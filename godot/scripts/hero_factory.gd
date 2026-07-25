class_name HeroFactory
extends RefCounted

const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"height": 1.86,
		"skin": Color("70462f"),
		"coat": Color("17232d"),
		"cloth": Color("6e2d28"),
		"hair": Color("11100f"),
		"accent": Color("d4a640"),
		"aura": Color("ef4b32"),
		"role": "Capitaine",
		"weapon": "Épée infernale du Cerbère"
	},
	"yvane": {
		"display_name": "YVANE",
		"height": 1.55,
		"skin": Color("75492f"),
		"coat": Color("20292d"),
		"cloth": Color("667044"),
		"hair": Color("11100f"),
		"accent": Color("67bcf2"),
		"aura": Color("31a9f3"),
		"role": "Matelot",
		"weapon": "Éclair Serpentine"
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"height": 1.30,
		"skin": Color("805238"),
		"coat": Color("273238"),
		"cloth": Color("8b6a35"),
		"hair": Color("11100f"),
		"accent": Color("e5ba55"),
		"aura": Color("7659ef"),
		"role": "Junior matelot",
		"weapon": "Boule du Big Bang"
	}
}

static func create_hero(hero_id: StringName, _third_person: bool = true) -> CharacterBody3D:
	var resolved_id := String(hero_id)
	if not HEROES.has(resolved_id):
		resolved_id = "cheikh"
	var profile: Dictionary = HEROES[resolved_id]
	var hero := CharacterBody3D.new()
	hero.name = String(profile["display_name"])
	hero.set_meta("hero_id", resolved_id)
	hero.set_meta("profile", profile)

	var rig := Node3D.new()
	rig.name = "RigVisuel"
	hero.add_child(rig)
	_build_character(rig, profile, resolved_id)
	_build_ground_shadow(rig, profile)
	_build_aura(rig, profile)
	return hero

static func _material(color: Color, roughness: float = 0.78, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

static func _mesh_part(name_value: String, mesh: PrimitiveMesh, color: Color, parent: Node3D, position: Vector3, scale_value: Vector3 = Vector3.ONE, roughness: float = 0.78, metallic: float = 0.0) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_value
	part.mesh = mesh
	part.position = position
	part.scale = scale_value
	part.material_override = _material(color, roughness, metallic)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)
	return part

static func _build_character(root: Node3D, profile: Dictionary, hero_id: String) -> void:
	var height := float(profile["height"])
	var ratio := height / 1.86
	var skin := Color(profile["skin"])
	var coat := Color(profile["coat"])
	var cloth := Color(profile["cloth"])
	var accent := Color(profile["accent"])

	var model := Node3D.new()
	model.name = "CharacterModel"
	model.scale = Vector3.ONE * ratio
	root.add_child(model)

	var hips := Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.92, 0)
	model.add_child(hips)

	_mesh_part("Torso", CapsuleMesh.new(), coat, hips, Vector3(0, 0.48, 0), Vector3(0.48, 0.72, 0.30))
	_mesh_part("Shirt", BoxMesh.new(), Color("d4c6ad"), hips, Vector3(0, 0.49, -0.24), Vector3(0.30, 0.46, 0.06))
	_mesh_part("Sash", BoxMesh.new(), cloth, hips, Vector3(0.08, 0.07, -0.27), Vector3(0.42, 0.10, 0.07))
	_mesh_part("Belt", BoxMesh.new(), Color("3d2418"), hips, Vector3(0, 0.18, -0.30), Vector3(0.44, 0.07, 0.06))
	_mesh_part("Buckle", BoxMesh.new(), accent, hips, Vector3(0, 0.18, -0.37), Vector3(0.09, 0.08, 0.025), 0.35, 0.65)

	var head_root := Node3D.new()
	head_root.name = "HeadRoot"
	head_root.position = Vector3(0, 1.30, 0)
	hips.add_child(head_root)
	_mesh_part("Head", SphereMesh.new(), skin, head_root, Vector3.ZERO, Vector3(0.30, 0.36, 0.28))
	_mesh_part("Hair", SphereMesh.new(), Color(profile["hair"]), head_root, Vector3(0, 0.25, 0.02), Vector3(0.31, 0.16 if hero_id == "cheikh" else 0.25, 0.29))
	if hero_id == "cheikh":
		_mesh_part("Beard", SphereMesh.new(), Color("201813"), head_root, Vector3(0, -0.13, -0.23), Vector3(0.25, 0.15, 0.08))
	else:
		for i in range(7):
			var angle := TAU * float(i) / 7.0
			_mesh_part("HairCurl%d" % i, SphereMesh.new(), Color(profile["hair"]), head_root, Vector3(cos(angle) * 0.20, 0.34 + sin(angle * 2.0) * 0.04, sin(angle) * 0.15), Vector3(0.09, 0.13, 0.09))

	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.43, 0.92, 0)
		hips.add_child(arm)
		_mesh_part("Upper", CapsuleMesh.new(), coat, arm, Vector3(0, -0.23, 0), Vector3(0.16, 0.36, 0.16))
		_mesh_part("Hand", SphereMesh.new(), skin, arm, Vector3(0, -0.63, 0), Vector3(0.13, 0.16, 0.13))

		var leg := Node3D.new()
		leg.name = "LegL" if side < 0 else "LegR"
		leg.position = Vector3(side * 0.20, 0.08, 0)
		hips.add_child(leg)
		_mesh_part("Thigh", CapsuleMesh.new(), Color("3a3028"), leg, Vector3(0, -0.31, 0), Vector3(0.19, 0.43, 0.20))
		_mesh_part("Boot", CapsuleMesh.new(), Color("291b15"), leg, Vector3(0, -0.76, -0.03), Vector3(0.20, 0.34, 0.22))

	_build_accessories(hips, profile, hero_id)

static func _build_accessories(hips: Node3D, profile: Dictionary, hero_id: String) -> void:
	var accent := Color(profile["accent"])
	if hero_id == "cheikh":
		var sword_root := Node3D.new()
		sword_root.name = "WeaponRoot"
		sword_root.position = Vector3(0.48, 0.42, 0)
		sword_root.rotation_degrees.z = -18.0
		hips.add_child(sword_root)
		_mesh_part("Blade", BoxMesh.new(), Color("aeb7b8"), sword_root, Vector3(0, -0.40, -0.18), Vector3(0.055, 0.55, 0.025), 0.18, 0.85)
		_mesh_part("Guard", BoxMesh.new(), accent, sword_root, Vector3(0, 0.08, -0.18), Vector3(0.20, 0.04, 0.05), 0.25, 0.70)
	else:
		_mesh_part("Satchel", BoxMesh.new(), Color("51321f"), hips, Vector3(0.42, 0.38, 0.05), Vector3(0.20, 0.25, 0.12))

static func _build_ground_shadow(root: Node3D, profile: Dictionary) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "OmbreAuSol"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.50 if String(profile["display_name"]) == "CHEIKH" else 0.38
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 32
	shadow.mesh = mesh
	shadow.position.y = 0.025
	shadow.material_override = _material(Color(0.005, 0.008, 0.012, 0.45))
	root.add_child(shadow)

static func _build_aura(root: Node3D, profile: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 90
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
	var glow := _material(Color(Color(profile["aura"]), 0.82), 0.25)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.emission_enabled = true
	glow.emission = Color(profile["aura"])
	glow.emission_energy_multiplier = 4.0
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = float(profile["height"]) * 0.48
	root.add_child(aura)