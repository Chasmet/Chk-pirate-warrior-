extends Node

# Direction de production runtime : corrige le premier affichage Android,
# donne une identité lisible à chaque famille et orchestre les pouvoirs signatures.

const HERO_SKILLS := {
	"cheikh": "ÉPÉE INFERNALE\nDU CERBÈRE",
	"yvane": "ÉCLAIR\nSERPENTINE",
	"nelvyn": "BOULE DU\nBIG BANG"
}

var player: PlayerController
var ui: GameUI
var skill_button: Button
var save_badge: Label
var previous_skill_cooldown := 0.0
var last_save_time := 0
var scan_timer := 0.0
var visual_time := 0.0
var startup_cleanup_time := 1.8
var animated_details: Array[Node3D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 2000
	set_process(true)
	call_deferred("_early_mobile_cleanup")

func _process(delta: float) -> void:
	visual_time += delta
	startup_cleanup_time = maxf(0.0, startup_cleanup_time - delta)
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.20
		_resolve_runtime_nodes()
		if startup_cleanup_time > 0.0:
			_early_mobile_cleanup()
		_upgrade_world_cast()
		_update_save_badge()
	if is_instance_valid(player):
		_update_skill_button()
		_detect_signature_skill()
	_animate_studio_details(delta)

func _resolve_runtime_nodes() -> void:
	if not is_instance_valid(player):
		var candidate := get_tree().root.find_child("ÉquipageQuinet", true, false)
		if candidate is PlayerController:
			player = candidate as PlayerController
			previous_skill_cooldown = player.skill_cooldown
	if not is_instance_valid(ui):
		var candidate_ui := get_tree().root.find_child("InterfaceFrançaise", true, false)
		if candidate_ui is GameUI:
			ui = candidate_ui as GameUI
	if is_instance_valid(ui) and not is_instance_valid(skill_button):
		for button in ui.find_children("*", "Button", true, false):
			var candidate_button := button as Button
			if candidate_button.text == "POUVOIR" or candidate_button.name == "PouvoirSignature":
				skill_button = candidate_button
				skill_button.name = "PouvoirSignature"
				break
	if is_instance_valid(ui) and not is_instance_valid(save_badge):
		_build_save_badge()

func _early_mobile_cleanup() -> void:
	# Masque uniquement les éléments connus pour produire les panneaux blancs
	# pendant le chargement. La météo et les effets de combat restent disponibles.
	for node in get_tree().root.find_children("*", "Label3D", true, false):
		(node as Label3D).visible = false
	for node in get_tree().root.find_children("BarreDeVie", "Node3D", true, false):
		(node as Node3D).visible = false
	for node in get_tree().root.find_children("BaliseDestination_*", "Node3D", true, false):
		(node as Node3D).visible = false
	for node in get_tree().root.find_children("*", "GPUParticles3D", true, false):
		var particles := node as GPUParticles3D
		var label := String(particles.name)
		if label in ["Aura", "Sillage", "TraînéeAttaque", "CombatFX"]:
			particles.visible = false
			particles.emitting = false

func _build_save_badge() -> void:
	save_badge = Label.new()
	save_badge.name = "IndicateurSauvegarde"
	save_badge.text = "SAUVEGARDE AUTO"
	save_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_badge.add_theme_font_size_override("font_size", 17)
	save_badge.add_theme_color_override("font_color", Color("f5d985"))
	save_badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	save_badge.add_theme_constant_override("shadow_offset_x", 2)
	save_badge.add_theme_constant_override("shadow_offset_y", 2)
	save_badge.anchor_left = 1.0
	save_badge.anchor_right = 1.0
	save_badge.offset_left = -540.0
	save_badge.offset_right = -255.0
	save_badge.offset_top = 112.0
	save_badge.offset_bottom = 146.0
	save_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	save_badge.modulate.a = 0.45
	ui.add_child(save_badge)
	last_save_time = FileAccess.get_modified_time(SaveSystem.SAVE_PATH) if FileAccess.file_exists(SaveSystem.SAVE_PATH) else 0

func _update_save_badge() -> void:
	if not is_instance_valid(save_badge):
		return
	var modified := FileAccess.get_modified_time(SaveSystem.SAVE_PATH) if FileAccess.file_exists(SaveSystem.SAVE_PATH) else 0
	if modified > last_save_time:
		last_save_time = modified
		save_badge.text = "✓ PROGRESSION SAUVEGARDÉE"
		save_badge.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(1.2)
		tween.tween_property(save_badge, "modulate:a", 0.45, 0.8)
		tween.tween_callback(func():
			if is_instance_valid(save_badge):
				save_badge.text = "SAUVEGARDE AUTO"
		)

func _update_skill_button() -> void:
	if not is_instance_valid(skill_button):
		return
	var label := String(HERO_SKILLS.get(player.hero_id, "POUVOIR"))
	if skill_button.text != label:
		skill_button.text = label
		skill_button.add_theme_font_size_override("font_size", 15 if player.hero_id != "nelvyn" else 16)

func _detect_signature_skill() -> void:
	var activated := player.skill_cooldown > previous_skill_cooldown + 0.35
	previous_skill_cooldown = player.skill_cooldown
	if not activated or player.boat_mode:
		return
	match player.hero_id:
		"cheikh":
			_spawn_cerberus_sword()
			VoiceFR.stop()
			VoiceFR.speak("Épée infernale du Cerbère !", true)
		"yvane":
			_spawn_serpentine_lightning()
			VoiceFR.stop()
			VoiceFR.speak("Éclair Serpentine !", true)
		"nelvyn":
			_spawn_big_bang_ball()
			VoiceFR.stop()
			VoiceFR.speak("La Boule du Big Bang !", true)

func _spawn_cerberus_sword() -> void:
	for index in range(3):
		var arc := _mesh_node("StudioCerbere_%d" % index, TorusMesh.new(), Color("ff351c") if index != 1 else Color("ffb21f"), 8.0)
		var mesh := arc.mesh as TorusMesh
		mesh.inner_radius = 0.72 + index * 0.16
		mesh.outer_radius = 1.04 + index * 0.20
		mesh.rings = 24
		mesh.ring_segments = 40
		arc.position = Vector3(0, 1.05 + index * 0.18, -1.0 - index * 0.45)
		arc.rotation_degrees = Vector3(90, 0, -28 + index * 28)
		player.add_child(arc)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(arc, "scale", Vector3.ONE * (2.2 + index * 0.35), 0.32)
		tween.tween_property(arc, "position:z", -5.2 - index * 0.8, 0.32)
		tween.tween_property(arc, "transparency", 1.0, 0.38)
		tween.chain().tween_callback(arc.queue_free)
	_spawn_signature_flash(Color("ff4a20"), 2.8)

func _spawn_serpentine_lightning() -> void:
	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	for index in range(22):
		var sphere := SphereMesh.new()
		sphere.radius = 0.12 + float(index % 3) * 0.035
		sphere.height = sphere.radius * 2.0
		var orb := _mesh_node("StudioÉclairSerpentine_%02d" % index, sphere, Color("52d9ff") if index % 2 == 0 else Color("f6fcff"), 11.0)
		var distance := 0.8 + index * 0.52
		var wave := sin(float(index) * 1.12) * (0.35 + distance * 0.045)
		orb.global_position = player.global_position + Vector3.UP * (1.15 + cos(float(index) * 0.72) * 0.22) + forward * distance + right * wave
		get_tree().current_scene.add_child(orb)
		var tween := create_tween()
		tween.tween_interval(index * 0.010)
		tween.set_parallel(true)
		tween.tween_property(orb, "scale", Vector3.ONE * 1.9, 0.24)
		tween.tween_property(orb, "transparency", 1.0, 0.34)
		tween.chain().tween_callback(orb.queue_free)
	_spawn_signature_flash(Color("40cfff"), 2.2)

func _spawn_big_bang_ball() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.58
	sphere.height = 1.16
	sphere.radial_segments = 32
	sphere.rings = 20
	var orb := _mesh_node("StudioBouleBigBang", sphere, Color("9c62ff"), 13.0)
	orb.position = Vector3(0, 1.42, -1.15)
	orb.scale = Vector3.ONE * 0.08
	player.add_child(orb)
	var ring := _mesh_node("AnneauBigBang", TorusMesh.new(), Color("e4c5ff"), 10.0)
	var ring_mesh := ring.mesh as TorusMesh
	ring_mesh.inner_radius = 0.78
	ring_mesh.outer_radius = 0.93
	ring.rotation_degrees.x = 90.0
	orb.add_child(ring)
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector3.ONE * 2.2, 0.46).set_trans(Tween.TRANS_BACK)
	tween.tween_property(orb, "position:z", -7.0, 0.32)
	tween.set_parallel(true)
	tween.tween_property(orb, "scale", Vector3.ONE * 5.4, 0.30)
	tween.tween_property(orb, "transparency", 1.0, 0.34)
	tween.chain().tween_callback(orb.queue_free)
	_spawn_signature_flash(Color("b984ff"), 3.4)

func _spawn_signature_flash(color: Color, radius: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var flash := _mesh_node("StudioFlashSignature", sphere, Color(color, 0.34), 6.0)
	flash.position = Vector3(0, 1.0, -1.3)
	flash.scale = Vector3.ONE * 0.12
	player.add_child(flash)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE, 0.24)
	tween.tween_property(flash, "transparency", 1.0, 0.30)
	tween.chain().tween_callback(flash.queue_free)

func _upgrade_world_cast() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and not node.has_meta("studio_visual_upgrade_v2"):
			node.set_meta("studio_visual_upgrade_v2", true)
			_upgrade_enemy(node)
	for node in get_tree().get_nodes_in_group("ambient_animals"):
		if is_instance_valid(node) and not node.has_meta("studio_visual_upgrade_v2"):
			node.set_meta("studio_visual_upgrade_v2", true)
			_upgrade_animal(node)

func _upgrade_enemy(enemy: Node) -> void:
	var profile_value = enemy.get("profile")
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var identifier := String(profile.get("id", enemy.name)).to_lower()
	var boss := bool(profile.get("boss", false))
	var scale_value := float(profile.get("scale", 1.0))
	var accent: Color = profile.get("accent", profile.get("color", Color("d6a63d")))
	var kit := Node3D.new()
	kit.name = "StudioCharacterKit_" + identifier
	enemy.add_child(kit)

	if boss:
		_build_boss_kit(kit, identifier, accent, scale_value)
	elif String(profile.get("creature", "")) != "":
		_build_creature_kit(kit, String(profile.get("creature", "")), accent)
	else:
		_build_pirate_kit(kit, identifier, String(profile.get("weapon", "saber")), accent)

func _build_pirate_kit(root: Node3D, identifier: String, weapon: String, accent: Color) -> void:
	var scarf := _part("Écharpe", BoxMesh.new(), accent, Vector3(0.72, 0.13, 0.18), Vector3(0, 1.45, 0.18))
	root.add_child(scarf)
	var weapon_node: MeshInstance3D
	match weapon:
		"rifle":
			weapon_node = _part("Fusil", BoxMesh.new(), Color("4b3020"), Vector3(0.13, 0.13, 1.45), Vector3(0.48, 1.12, -0.12))
		"shield":
			weapon_node = _part("Bouclier", CylinderMesh.new(), accent.darkened(0.22), Vector3(1.0, 1.0, 1.0), Vector3(-0.50, 1.05, -0.05))
			var shield_mesh := weapon_node.mesh as CylinderMesh
			shield_mesh.top_radius = 0.52
			shield_mesh.bottom_radius = 0.52
			shield_mesh.height = 0.12
			weapon_node.rotation_degrees.x = 90.0
		"hammer":
			weapon_node = _part("Marteau", BoxMesh.new(), accent, Vector3(0.70, 0.34, 0.34), Vector3(0.52, 1.10, -0.20))
		"dual":
			weapon_node = _part("LamesDoubles", BoxMesh.new(), accent, Vector3(1.20, 0.08, 0.12), Vector3(0, 0.95, -0.42))
		"staff", "whip", "gear":
			weapon_node = _part("ArmeSpéciale", CylinderMesh.new(), accent, Vector3.ONE, Vector3(0.48, 1.10, -0.12))
			var staff_mesh := weapon_node.mesh as CylinderMesh
			staff_mesh.top_radius = 0.055
			staff_mesh.bottom_radius = 0.075
			staff_mesh.height = 1.65
		_:
			weapon_node = _part("Sabre", BoxMesh.new(), accent.lightened(0.28), Vector3(0.08, 0.08, 1.15), Vector3(0.48, 1.00, -0.16))
	root.add_child(weapon_node)
	if "medecin" in identifier:
		var vial := _mesh_node("FioleVerte", SphereMesh.new(), Color("56ef79"), 2.8)
		vial.scale = Vector3(0.22, 0.35, 0.22)
		vial.position = Vector3(-0.34, 0.92, -0.32)
		root.add_child(vial)
		_register_animation(vial, 1.3)
	elif "mecanique" in identifier:
		var gear := _mesh_node("CœurMécanique", TorusMesh.new(), Color("4fd4d9"), 4.2)
		gear.scale = Vector3.ONE * 0.34
		gear.position = Vector3(0, 1.18, -0.38)
		root.add_child(gear)
		_register_animation(gear, 2.4)
	elif "voleur" in identifier:
		var hood := _part("CapucheLongue", PrismMesh.new(), accent.darkened(0.45), Vector3(0.50, 0.58, 0.40), Vector3(0, 1.82, 0.08))
		root.add_child(hood)

func _build_creature_kit(root: Node3D, creature: String, accent: Color) -> void:
	match creature:
		"crab":
			for side in [-1.0, 1.0]:
				var claw := _part("Pince", SphereMesh.new(), accent, Vector3(0.48, 0.28, 0.54), Vector3(side * 0.72, 0.45, -0.28))
				root.add_child(claw)
		"bird":
			var wings := _part("AilesTempête", BoxMesh.new(), accent, Vector3(2.45, 0.08, 0.56), Vector3(0, 0.72, 0))
			root.add_child(wings)
			_register_animation(wings, 3.1)
		"monkey":
			var tail := _mesh_node("QueueSinge", TorusMesh.new(), accent, 0.15)
			tail.scale = Vector3(0.62, 0.62, 0.35)
			tail.position = Vector3(0, 0.65, 0.42)
			root.add_child(tail)
		"lizard":
			var tail_lizard := _part("QueueLézard", PrismMesh.new(), accent, Vector3(0.22, 0.22, 1.25), Vector3(0, 0.34, 0.72))
			root.add_child(tail_lizard)

func _build_boss_kit(root: Node3D, identifier: String, accent: Color, scale_value: float) -> void:
	var crown := _mesh_node("CouronneBoss", TorusMesh.new(), accent, 4.5)
	crown.scale = Vector3.ONE * (0.48 * scale_value)
	crown.position = Vector3(0, 2.12 * scale_value, 0)
	crown.rotation_degrees.x = 90.0
	root.add_child(crown)
	_register_animation(crown, 1.8)
	match identifier:
		"brakor":
			var anchor := _part("AncreTitan", BoxMesh.new(), Color("4c5968"), Vector3(0.36, 2.10, 0.28) * scale_value, Vector3(0.82, 1.05, -0.15) * scale_value)
			root.add_child(anchor)
		"scorpia":
			for side in [-1.0, 1.0]:
				var claw := _part("PinceScorpia", SphereMesh.new(), accent, Vector3(0.55, 0.34, 0.70) * scale_value, Vector3(side * 0.78, 1.08, -0.26) * scale_value)
				root.add_child(claw)
		"kryl":
			for side in [-1.0, 1.0]:
				var crystal := _mesh_node("CristalGivre", PrismMesh.new(), Color("a8efff"), 5.0)
				crystal.scale = Vector3(0.34, 0.82, 0.34) * scale_value
				crystal.position = Vector3(side * 0.62, 1.55, 0.12) * scale_value
				root.add_child(crystal)
		"mako":
			var trident := _part("TridentRoyal", CylinderMesh.new(), accent, Vector3.ONE, Vector3(0.82, 1.28, -0.18) * scale_value)
			var trident_mesh := trident.mesh as CylinderMesh
			trident_mesh.top_radius = 0.08
			trident_mesh.bottom_radius = 0.10
			trident_mesh.height = 2.35 * scale_value
			root.add_child(trident)
		"volkan":
			var core := _mesh_node("CœurVolcan", SphereMesh.new(), Color("ff4b18"), 8.0)
			core.scale = Vector3.ONE * (0.36 * scale_value)
			core.position = Vector3(0, 1.34, -0.42) * scale_value
			root.add_child(core)
			_register_animation(core, 2.8)
		"vorga":
			for side in [-1.0, 1.0]:
				var storm_orb := _mesh_node("OrbeOrage", SphereMesh.new(), Color("61c9ff"), 8.0)
				storm_orb.scale = Vector3.ONE * (0.28 * scale_value)
				storm_orb.position = Vector3(side * 0.86, 1.48, 0) * scale_value
				root.add_child(storm_orb)
				_register_animation(storm_orb, 2.2 + side * 0.3)

func _upgrade_animal(animal: Node) -> void:
	var label := String(animal.name).to_lower()
	var root := Node3D.new()
	root.name = "StudioAnimalKit"
	animal.add_child(root)
	if "oiseau" in label or "aigle" in label or "mouette" in label:
		var wings := _part("Ailes", BoxMesh.new(), Color("d9e3e8"), Vector3(2.2, 0.07, 0.48), Vector3(0, 0.34, 0))
		root.add_child(wings)
		_register_animation(wings, 3.4)
	elif "singe" in label:
		var tail := _mesh_node("Queue", TorusMesh.new(), Color("806044"), 0.1)
		tail.position = Vector3(0, 0.35, 0.35)
		root.add_child(tail)
	elif "pingouin" in label:
		var belly := _part("VentreBlanc", SphereMesh.new(), Color("f1f3ee"), Vector3(0.55, 0.78, 0.30), Vector3(0, 0.52, -0.22))
		root.add_child(belly)
	elif "chameau" in label:
		for x in [-0.24, 0.24]:
			var hump := _part("Bosse", SphereMesh.new(), Color("b88958"), Vector3(0.42, 0.50, 0.40), Vector3(x, 0.92, 0.12))
			root.add_child(hump)
	elif "lézard" in label or "lezard" in label:
		var crest := _part("Crête", PrismMesh.new(), Color("7fa35c"), Vector3(0.22, 0.45, 0.95), Vector3(0, 0.62, 0.12))
		root.add_child(crest)
	else:
		var horns := _part("Cornes", BoxMesh.new(), Color("d9b56a"), Vector3(0.82, 0.08, 0.08), Vector3(0, 0.86, -0.20))
		root.add_child(horns)

func _animate_studio_details(delta: float) -> void:
	for index in range(animated_details.size() - 1, -1, -1):
		var node := animated_details[index]
		if not is_instance_valid(node):
			animated_details.remove_at(index)
			continue
		var speed := float(node.get_meta("studio_anim_speed", 1.0))
		node.rotation.y += delta * speed
		node.position.y += sin(visual_time * speed + float(index)) * delta * 0.035

func _register_animation(node: Node3D, speed: float) -> void:
	node.set_meta("studio_anim_speed", speed)
	animated_details.append(node)

func _part(part_name: String, mesh: PrimitiveMesh, color: Color, size: Vector3, position: Vector3) -> MeshInstance3D:
	var node := _mesh_node(part_name, mesh, color, 0.0)
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	else:
		node.scale = size
	node.position = position
	return node

func _mesh_node(part_name: String, mesh: PrimitiveMesh, color: Color, energy: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.material_override = _glow_material(color, energy)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if energy > 0.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if energy > 0.0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.roughness = 0.72
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b, 1.0)
		material.emission_energy_multiplier = energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
