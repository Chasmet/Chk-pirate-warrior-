extends Node

# Couche de finition exécutée dès le premier écran Android.
# Elle corrige les artefacts transitoires, affiche les vrais noms des pouvoirs,
# ajoute leurs effets signatures et rend la sauvegarde automatique visible.

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 2000
	set_process(true)
	# Le premier passage a lieu avant que le monde soit totalement initialisé.
	call_deferred("_early_mobile_cleanup")

func _process(delta: float) -> void:
	visual_time += delta
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.20
		_resolve_runtime_nodes()
		_early_mobile_cleanup()
		_upgrade_world_cast()
		_update_save_badge()
	if is_instance_valid(player):
		_update_skill_button()
		_detect_signature_skill()

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
	# Le bug observé au début de la vidéo vient de quads/labels/particules visibles
	# pendant quelques images avant l'arrivée des scripts de réparation habituels.
	for node in get_tree().root.find_children("*", "Label3D", true, false):
		(node as Label3D).visible = false
	for node in get_tree().root.find_children("BarreDeVie", "Node3D", true, false):
		(node as Node3D).visible = false
	for node in get_tree().root.find_children("BaliseDestination_*", "Node3D", true, false):
		(node as Node3D).visible = false
	for node in get_tree().root.find_children("*", "GPUParticles3D", true, false):
		var particles := node as GPUParticles3D
		# Les effets signatures ci-dessous utilisent des meshes/tweens stables.
		if not String(particles.name).begins_with("StudioSafe"):
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
			if is_instance_valid(save_badge): save_badge.text = "SAUVEGARDE AUTO"
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
		var arc := MeshInstance3D.new()
		arc.name = "StudioCerbere_%d" % index
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.72 + index * 0.16
		mesh.outer_radius = 1.04 + index * 0.20
		mesh.rings = 24
		mesh.ring_segments = 40
		arc.mesh = mesh
		arc.position = Vector3(0, 1.05 + index * 0.18, -1.0 - index * 0.45)
		arc.rotation_degrees = Vector3(90, 0, -28 + index * 28)
		arc.material_override = _glow_material(Color("ff351c") if index != 1 else Color("ffb21f"), 8.0)
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
	for index in range(18):
		var orb := MeshInstance3D.new()
		orb.name = "StudioÉclairSerpentine_%02d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 0.12 + float(index % 3) * 0.035
		sphere.height = sphere.radius * 2.0
		orb.mesh = sphere
		var distance := 0.8 + index * 0.55
		var wave := sin(float(index) * 1.12) * (0.35 + distance * 0.045)
		orb.global_position = player.global_position + Vector3.UP * (1.15 + cos(float(index) * 0.72) * 0.22) + forward * distance + right * wave
		orb.material_override = _glow_material(Color("52d9ff") if index % 2 == 0 else Color("f6fcff"), 11.0)
		get_tree().current_scene.add_child(orb)
		var tween := create_tween()
		tween.tween_interval(index * 0.012)
		tween.set_parallel(true)
		tween.tween_property(orb, "scale", Vector3.ONE * 1.9, 0.24)
		tween.tween_property(orb, "transparency", 1.0, 0.34)
		tween.chain().tween_callback(orb.queue_free)
	_spawn_signature_flash(Color("40cfff"), 2.2)

func _spawn_big_bang_ball() -> void:
	var orb := MeshInstance3D.new()
	orb.name = "StudioBouleBigBang"
	var sphere := SphereMesh.new()
	sphere.radius = 0.58
	sphere.height = 1.16
	sphere.radial_segments = 32
	sphere.rings = 20
	orb.mesh = sphere
	orb.position = Vector3(0, 1.42, -1.15)
	orb.scale = Vector3.ONE * 0.08
	orb.material_override = _glow_material(Color("9c62ff"), 13.0)
	player.add_child(orb)
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector3.ONE * 2.2, 0.46).set_trans(Tween.TRANS_BACK)
	tween.tween_property(orb, "position:z", -7.0, 0.32)
	tween.set_parallel(true)
	tween.tween_property(orb, "scale", Vector3.ONE * 5.4, 0.30)
	tween.tween_property(orb, "transparency", 1.0, 0.34)
	tween.chain().tween_callback(orb.queue_free)
	_spawn_signature_flash(Color("b984ff"), 3.4)

func _spawn_signature_flash(color: Color, radius: float) -> void:
	var flash := MeshInstance3D.new()
	flash.name = "StudioFlashSignature"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	flash.mesh = sphere
	flash.position = Vector3(0, 1.0, -1.3)
	flash.scale = Vector3.ONE * 0.12
	flash.material_override = _glow_material(Color(color, 0.34), 6.0)
	player.add_child(flash)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE, 0.24)
	tween.tween_property(flash, "transparency", 1.0, 0.30)
	tween.chain().tween_callback(flash.queue_free)

func _upgrade_world_cast() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and not node.has_meta("studio_visual_upgrade"):
			node.set_meta("studio_visual_upgrade", true)
			_upgrade_enemy(node)
	for node in get_tree().get_nodes_in_group("ambient_animals"):
		if is_instance_valid(node) and not node.has_meta("studio_visual_upgrade"):
			node.set_meta("studio_visual_upgrade", true)
			_upgrade_animal(node)

func _upgrade_enemy(enemy: Node) -> void:
	var profile_value = enemy.get("profile")
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var identifier := String(profile.get("id", enemy.name)).to_lower()
	var boss := bool(profile.get("boss", false))
	var accent: Color = profile.get("accent", profile.get("color", Color("d6a63d")))
	var crest := MeshInstance3D.new()
	crest.name = "SilhouetteUnique_" + identifier
	var crest_mesh := PrismMesh.new() if boss else CylinderMesh.new()
	if crest_mesh is PrismMesh:
		crest_mesh.size = Vector3(0.52, 0.28, 0.24) * float(profile.get("scale", 1.0))
	else:
		crest_mesh.top_radius = 0.08
		crest_mesh.bottom_radius = 0.20
		crest_mesh.height = 0.42
	crest.mesh = crest_mesh
	crest.position = Vector3(0, 2.08 * float(profile.get("scale", 1.0)), 0)
	crest.material_override = _glow_material(accent, 2.2 if boss else 0.7)
	enemy.add_child(crest)
	# Une forme de signature supplémentaire par famille, pour éviter les clones.
	if "tireur" in identifier:
		crest.rotation_degrees.z = 90
	elif "bouclier" in identifier or "brakor" in identifier:
		crest.scale = Vector3(2.2, 1.2, 0.55)
	elif "voleur" in identifier or "scorpia" in identifier:
		crest.rotation_degrees.y = 45
		crest.scale = Vector3(0.65, 1.7, 0.65)
	elif "mecanique" in identifier or "vorga" in identifier:
		crest.rotation_degrees = Vector3(35, 0, 45)
		crest.scale = Vector3.ONE * 1.45
	elif boss:
		crest.scale = Vector3.ONE * 2.0

func _upgrade_animal(animal: Node) -> void:
	var label := String(animal.name).to_lower()
	var detail := MeshInstance3D.new()
	detail.name = "DétailAnimalUnique"
	if "oiseau" in label or "aigle" in label or "mouette" in label:
		var wings := BoxMesh.new()
		wings.size = Vector3(2.2, 0.08, 0.48)
		detail.mesh = wings
		detail.position.y = 0.34
	elif "singe" in label:
		var tail := TorusMesh.new()
		tail.inner_radius = 0.24
		tail.outer_radius = 0.34
		detail.mesh = tail
		detail.position = Vector3(0, 0.35, 0.35)
	elif "crabe" in label:
		var shell := SphereMesh.new()
		shell.radius = 0.46
		shell.height = 0.42
		detail.mesh = shell
		detail.scale = Vector3(1.5, 0.55, 1.0)
	else:
		var crest := PrismMesh.new()
		crest.size = Vector3(0.34, 0.42, 0.18)
		detail.mesh = crest
		detail.position = Vector3(0, 0.65, -0.18)
	detail.material_override = _glow_material(Color("d9b56a"), 0.25)
	animal.add_child(detail)

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
