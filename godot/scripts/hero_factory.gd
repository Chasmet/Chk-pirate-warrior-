class_name HeroFactory
extends RefCounted

const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"height": 1.92,
		"skin": Color("70462f"),
		"accent": Color("d4a640"),
		"aura": Color("ef4b32"),
		"role": "Capitaine puissant",
		"weapon": "Sabre courbe",
		"sprite": "res://assets/heroes/cheikh_poses.webp",
		"third_person_sprite": "res://assets/heroes/cheikh_third_person.webp",
		"steering_sprite": "res://assets/heroes/cheikh_steering_v24.webp",
		"pixel_size": 0.00305,
		"sprite_y": 0.91
	},
	"yvane": {
		"display_name": "YVANE",
		"height": 1.62,
		"skin": Color("7a4e34"),
		"accent": Color("67bcf2"),
		"aura": Color("31a9f3"),
		"role": "Éclaireur électrique",
		"weapon": "Fronde",
		"sprite": "res://assets/heroes/yvane_poses.webp",
		"third_person_sprite": "res://assets/heroes/yvane_third_person.webp",
		"steering_sprite": "res://assets/heroes/yvane_steering_v24.webp",
		"pixel_size": 0.00266,
		"sprite_y": 0.80
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"height": 1.34,
		"skin": Color("805238"),
		"accent": Color("e5ba55"),
		"aura": Color("76df72"),
		"role": "Inventeur tactique",
		"weapon": "Gadgets",
		"sprite": "res://assets/heroes/nelvyn_poses.webp",
		"third_person_sprite": "res://assets/heroes/nelvyn_third_person.webp",
		"steering_sprite": "res://assets/heroes/nelvyn_steering_v24.webp",
		"pixel_size": 0.00228,
		"sprite_y": 0.68
	}
}

static func create_hero(hero_id: StringName, third_person: bool = true) -> CharacterBody3D:
	var resolved_id := String(hero_id)
	if not HEROES.has(resolved_id):
		resolved_id = "cheikh"
	var profile: Dictionary = HEROES[resolved_id]
	var hero := CharacterBody3D.new()
	hero.name = String(profile["display_name"])
	hero.set_meta("hero_id", resolved_id)
	hero.set_meta("profile", profile)
	hero.set_meta("procedural_3d", true)

	var rig := Node3D.new()
	rig.name = "RigVisuel"
	hero.add_child(rig)
	_build_compatibility_art(rig, profile, third_person)
	_build_model_3d(rig, resolved_id, profile)
	_build_ground_shadow(rig, profile)
	_build_aura(rig, profile)
	return hero

# Cette planche reste minuscule pour préserver les anciennes interfaces et les
# tests de ressources. Le personnage visible en jeu est désormais Model3D.
static func _build_compatibility_art(root: Node3D, profile: Dictionary, third_person: bool) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "CharacterArt"
	var texture_path := String(profile["third_person_sprite"]) if third_person else String(profile["sprite"])
	sprite.texture = load(texture_path) as Texture2D
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = 0.000001
	sprite.position.y = float(profile["sprite_y"])
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.double_sided = true
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.render_priority = -8
	root.add_child(sprite)

static func _build_model_3d(root: Node3D, hero_id: String, profile: Dictionary) -> void:
	var model := Node3D.new()
	model.name = "Model3D"
	model.set_meta("hero_id", hero_id)
	model.set_meta("front_axis", Vector3(0.0, 0.0, -1.0))
	root.add_child(model)

	var height_ratio := float(profile["height"]) / 1.92
	model.scale = Vector3.ONE * height_ratio

	var skin := _material(Color(profile["skin"]), 0.78)
	var skin_light := _material(Color(profile["skin"]).lightened(0.08), 0.72)
	var accent := _material(Color(profile["accent"]), 0.62)
	var aura_color := Color(profile["aura"])
	var dark := _material(Color("17202a"), 0.86)
	var cloth_dark := _material(Color("26313b"), 0.88)
	var leather := _material(Color("4b3023"), 0.90)
	var white := _material(Color("f1eadc"), 0.70)
	var eye_dark := _material(Color("090b0d"), 0.55)
	var metal := _material(Color("c7d1d6"), 0.24, 0.72)
	var gold := _material(Color("d8ad48"), 0.32, 0.62)

	var hips := Node3D.new()
	hips.name = "Hanches"
	hips.position = Vector3(0.0, 0.82, 0.0)
	model.add_child(hips)
	_add_box(hips, "Ceinture", Vector3(0.54, 0.18, 0.30), Vector3.ZERO, Vector3.ZERO, leather)
	_add_box(hips, "Boucle", Vector3(0.13, 0.11, 0.035), Vector3(0.0, 0.0, -0.17), Vector3.ZERO, gold)

	var torso := Node3D.new()
	torso.name = "Torse"
	torso.position = Vector3(0.0, 1.22, 0.0)
	model.add_child(torso)
	var torso_width := 0.68 if hero_id == "cheikh" else 0.55 if hero_id == "yvane" else 0.58
	_add_box(torso, "Buste", Vector3(torso_width, 0.72, 0.34), Vector3.ZERO, Vector3.ZERO, accent)
	_add_box(torso, "Chemise", Vector3(torso_width * 0.46, 0.58, 0.035), Vector3(0.0, 0.0, -0.19), Vector3.ZERO, white)
	_add_box(torso, "Sangle", Vector3(0.11, 0.82, 0.045), Vector3(0.08, 0.0, -0.22), Vector3(0.0, 0.0, -26.0), leather)

	var coat := Node3D.new()
	coat.name = "Manteau"
	coat.position = Vector3(0.0, -0.26, 0.17)
	torso.add_child(coat)
	_add_box(coat, "PanGauche", Vector3(0.24, 0.68, 0.08), Vector3(-0.17, -0.28, 0.0), Vector3(8.0, 0.0, -4.0), accent)
	_add_box(coat, "PanDroit", Vector3(0.24, 0.68, 0.08), Vector3(0.17, -0.28, 0.0), Vector3(8.0, 0.0, 4.0), accent)

	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0.0, 1.78, 0.0)
	model.add_child(head)
	_add_sphere(head, "Visage", 0.245, Vector3.ZERO, Vector3(1.0, 1.08, 0.94), skin_light)
	_build_face(head, hero_id, skin, white, eye_dark, accent, gold)
	_build_hair(head, hero_id, dark, accent, leather)

	_build_arm(model, "BrasGauche", -1.0, skin, accent, hero_id)
	var right_arm := _build_arm(model, "BrasDroit", 1.0, skin, accent, hero_id)
	_build_leg(model, "JambeGauche", -1.0, cloth_dark, leather)
	_build_leg(model, "JambeDroite", 1.0, cloth_dark, leather)
	_build_weapon(right_arm, hero_id, aura_color, leather, metal, gold)

	if hero_id == "nelvyn":
		_build_backpack(torso, dark, gold, aura_color)
	elif hero_id == "yvane":
		_build_lightning_marks(torso, aura_color)
	else:
		_build_captain_details(torso, gold)

static func _build_face(head: Node3D, hero_id: String, skin: StandardMaterial3D, white: StandardMaterial3D, eye_dark: StandardMaterial3D, accent: StandardMaterial3D, gold: StandardMaterial3D) -> void:
	for side in [-1.0, 1.0]:
		_add_sphere(head, "Oeil", 0.055, Vector3(side * 0.085, 0.045, -0.218), Vector3(1.05, 0.72, 0.42), white)
		_add_sphere(head, "Pupille", 0.026, Vector3(side * 0.085, 0.043, -0.252), Vector3(0.74, 0.82, 0.38), eye_dark)
		_add_box(head, "Sourcil", Vector3(0.10, 0.022, 0.024), Vector3(side * 0.085, 0.115, -0.235), Vector3(0.0, 0.0, side * -7.0), eye_dark)
	_add_sphere(head, "Nez", 0.040, Vector3(0.0, -0.005, -0.258), Vector3(0.72, 1.05, 0.62), skin)
	_add_box(head, "Bouche", Vector3(0.10, 0.020, 0.022), Vector3(0.0, -0.105, -0.244), Vector3.ZERO, eye_dark)
	if hero_id == "cheikh":
		_add_box(head, "Barbe", Vector3(0.31, 0.16, 0.12), Vector3(0.0, -0.175, -0.105), Vector3(12.0, 0.0, 0.0), eye_dark)
	elif hero_id == "nelvyn":
		var goggles := Node3D.new()
		goggles.name = "Lunettes"
		head.add_child(goggles)
		for side in [-1.0, 1.0]:
			_add_cylinder(goggles, "Verre", 0.073, 0.035, Vector3(side * 0.082, 0.050, -0.258), Vector3(90.0, 0.0, 0.0), gold)
		_add_box(goggles, "Pont", Vector3(0.055, 0.020, 0.020), Vector3(0.0, 0.050, -0.270), Vector3.ZERO, accent)

static func _build_hair(head: Node3D, hero_id: String, dark: StandardMaterial3D, accent: StandardMaterial3D, leather: StandardMaterial3D) -> void:
	if hero_id == "cheikh":
		_add_sphere(head, "Cheveux", 0.252, Vector3(0.0, 0.085, 0.018), Vector3(1.02, 0.62, 1.02), dark)
		_add_box(head, "Bandeau", Vector3(0.52, 0.075, 0.37), Vector3(0.0, 0.145, -0.010), Vector3.ZERO, accent)
	elif hero_id == "yvane":
		_add_sphere(head, "Cheveux", 0.248, Vector3(0.0, 0.10, 0.020), Vector3(1.02, 0.64, 1.02), dark)
		for index in range(7):
			var x := -0.21 + float(index) * 0.07
			var length := 0.34 + float(abs(index - 3)) * 0.025
			_add_capsule(head, "Tresse_%d" % index, 0.025, length, Vector3(x, -0.03, 0.105), Vector3(8.0, 0.0, float(index - 3) * 4.0), dark)
	else:
		_add_sphere(head, "Cheveux", 0.250, Vector3(0.0, 0.10, 0.025), Vector3(1.04, 0.66, 1.04), dark)
		_add_box(head, "Casquette", Vector3(0.54, 0.10, 0.40), Vector3(0.0, 0.16, -0.005), Vector3.ZERO, leather)
		_add_box(head, "Visiere", Vector3(0.30, 0.035, 0.20), Vector3(0.0, 0.145, -0.235), Vector3(-8.0, 0.0, 0.0), accent)

static func _build_arm(model: Node3D, node_name: String, side: float, skin: StandardMaterial3D, accent: StandardMaterial3D, hero_id: String) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = Vector3(side * (0.41 if hero_id == "cheikh" else 0.35), 1.48, 0.0)
	model.add_child(pivot)
	_add_capsule(pivot, "Manche", 0.105, 0.55, Vector3(0.0, -0.24, 0.0), Vector3.ZERO, accent)
	_add_sphere(pivot, "Main", 0.105, Vector3(0.0, -0.55, -0.015), Vector3.ONE, skin)
	return pivot

static func _build_leg(model: Node3D, node_name: String, side: float, cloth: StandardMaterial3D, leather: StandardMaterial3D) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = Vector3(side * 0.17, 0.78, 0.0)
	model.add_child(pivot)
	_add_capsule(pivot, "Jambe", 0.13, 0.70, Vector3(0.0, -0.30, 0.0), Vector3.ZERO, cloth)
	_add_box(pivot, "Botte", Vector3(0.26, 0.24, 0.42), Vector3(0.0, -0.69, -0.07), Vector3.ZERO, leather)
	return pivot

static func _build_weapon(arm: Node3D, hero_id: String, aura_color: Color, leather: StandardMaterial3D, metal: StandardMaterial3D, gold: StandardMaterial3D) -> void:
	var weapon := Node3D.new()
	weapon.name = "Arme"
	weapon.position = Vector3(0.0, -0.61, -0.02)
	arm.add_child(weapon)
	if hero_id == "cheikh":
		_add_cylinder(weapon, "Poignee", 0.035, 0.24, Vector3(0.0, -0.03, 0.0), Vector3.ZERO, leather)
		_add_box(weapon, "Garde", Vector3(0.28, 0.035, 0.055), Vector3(0.0, -0.13, 0.0), Vector3.ZERO, gold)
		_add_box(weapon, "Lame", Vector3(0.075, 0.80, 0.025), Vector3(0.0, -0.57, 0.0), Vector3(0.0, 0.0, -9.0), metal)
	elif hero_id == "yvane":
		_add_box(weapon, "BrancheGauche", Vector3(0.045, 0.38, 0.045), Vector3(-0.08, -0.18, 0.0), Vector3(0.0, 0.0, -18.0), leather)
		_add_box(weapon, "BrancheDroite", Vector3(0.045, 0.38, 0.045), Vector3(0.08, -0.18, 0.0), Vector3(0.0, 0.0, 18.0), leather)
		_add_box(weapon, "Elastique", Vector3(0.24, 0.018, 0.018), Vector3(0.0, -0.37, 0.0), Vector3.ZERO, _emissive_material(aura_color, 3.0))
	else:
		_add_sphere(weapon, "Gadget", 0.16, Vector3(0.0, -0.12, 0.0), Vector3.ONE, _emissive_material(aura_color, 4.5))
		_add_cylinder(weapon, "Anneau", 0.20, 0.035, Vector3(0.0, -0.12, 0.0), Vector3(90.0, 0.0, 0.0), gold)

static func _build_backpack(torso: Node3D, dark: StandardMaterial3D, gold: StandardMaterial3D, aura_color: Color) -> void:
	var backpack := Node3D.new()
	backpack.name = "SacInventeur"
	backpack.position = Vector3(0.0, 0.0, 0.26)
	torso.add_child(backpack)
	_add_box(backpack, "Sac", Vector3(0.44, 0.52, 0.20), Vector3.ZERO, Vector3.ZERO, dark)
	_add_cylinder(backpack, "RéservoirGauche", 0.065, 0.38, Vector3(-0.15, 0.0, 0.15), Vector3.ZERO, gold)
	_add_cylinder(backpack, "RéservoirDroit", 0.065, 0.38, Vector3(0.15, 0.0, 0.15), Vector3.ZERO, gold)
	_add_sphere(backpack, "Énergie", 0.075, Vector3(0.0, 0.12, 0.14), Vector3.ONE, _emissive_material(aura_color, 4.0))

static func _build_lightning_marks(torso: Node3D, aura_color: Color) -> void:
	var glow := _emissive_material(aura_color, 3.8)
	_add_box(torso, "ÉclairHaut", Vector3(0.10, 0.30, 0.025), Vector3(-0.12, 0.12, -0.215), Vector3(0.0, 0.0, -26.0), glow)
	_add_box(torso, "ÉclairBas", Vector3(0.10, 0.28, 0.025), Vector3(0.02, -0.10, -0.215), Vector3(0.0, 0.0, 25.0), glow)

static func _build_captain_details(torso: Node3D, gold: StandardMaterial3D) -> void:
	for side in [-1.0, 1.0]:
		_add_box(torso, "Épaulette", Vector3(0.23, 0.08, 0.30), Vector3(side * 0.36, 0.31, 0.0), Vector3(0.0, 0.0, side * 5.0), gold)

static func _build_ground_shadow(root: Node3D, profile: Dictionary) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "OmbreAuSol"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.52 if String(profile["display_name"]) == "CHEIKH" else 0.42
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 28
	shadow.mesh = mesh
	shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.005, 0.008, 0.012, 0.48)
	shadow.material_override = material
	root.add_child(shadow)

static func _build_aura(root: Node3D, profile: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 132
	aura.lifetime = 0.72
	aura.emitting = false
	aura.visibility_aabb = AABB(Vector3(-2.5, -0.3, -2.5), Vector3(5, 4.5, 5))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.62
	process.direction = Vector3(0, 1, 0)
	process.spread = 44.0
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.6
	process.gravity = Vector3(0, 2.2, 0)
	process.scale_min = 0.035
	process.scale_max = 0.12
	process.color = Color(profile["aura"])
	aura.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.36)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(Color(profile["aura"]), 0.82)
	glow.emission_enabled = true
	glow.emission = Color(profile["aura"])
	glow.emission_energy_multiplier = 5.2
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = float(profile["height"]) * 0.48
	root.add_child(aura)

static func _material(color: Color, roughness: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

static func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color, 0.35, 0.18)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

static func _add_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, rotation_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(parent, node_name, mesh, position, rotation_value, Vector3.ONE, material)

static func _add_sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, scale_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	return _add_mesh(parent, node_name, mesh, position, Vector3.ZERO, scale_value, material)

static func _add_capsule(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, rotation_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add_mesh(parent, node_name, mesh, position, rotation_value, Vector3.ONE, material)

static func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, rotation_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	return _add_mesh(parent, node_name, mesh, position, rotation_value, Vector3.ONE, material)

static func _add_mesh(parent: Node3D, node_name: String, mesh: PrimitiveMesh, position: Vector3, rotation_value: Vector3, scale_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation_value
	instance.scale = scale_value
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance
