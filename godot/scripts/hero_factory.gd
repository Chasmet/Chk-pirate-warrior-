class_name HeroFactory
extends RefCounted

const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"height": 1.82,
		"body_scale": Vector3(1.08, 1.0, 1.02),
		"skin": Color("6f452f"),
		"hair": Color("191513"),
		"outfit_main": Color("9f2529"),
		"outfit_secondary": Color("171b22"),
		"accent": Color("e7b843"),
		"aura": Color("e23a2e"),
		"hair_style": "short_curls",
		"role": "Capitaine puissant",
		"weapon": "sabre_lourd"
	},
	"yvane": {
		"display_name": "YVANE",
		"height": 1.53,
		"body_scale": Vector3(0.84, 0.86, 0.86),
		"skin": Color("7c5036"),
		"hair": Color("171312"),
		"outfit_main": Color("226fb5"),
		"outfit_secondary": Color("111925"),
		"accent": Color("eaf7ff"),
		"aura": Color("2fa9f4"),
		"hair_style": "long_twists",
		"role": "Éclaireur électrique",
		"weapon": "double_lame"
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"height": 1.30,
		"body_scale": Vector3(0.78, 0.76, 0.8),
		"skin": Color("815337"),
		"hair": Color("211817"),
		"outfit_main": Color("2aa667"),
		"outfit_secondary": Color("18211f"),
		"accent": Color("f09a3f"),
		"aura": Color("54e08b"),
		"hair_style": "short_round",
		"role": "Inventeur tactique",
		"weapon": "gantelets_tech"
	}
}

static func create_hero(hero_id: StringName) -> CharacterBody3D:
	var profile: Dictionary = HEROES.get(String(hero_id), HEROES["cheikh"])
	var hero := CharacterBody3D.new()
	hero.name = profile.display_name
	hero.set_meta("hero_id", String(hero_id))
	hero.set_meta("profile", profile)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34 * profile.body_scale.x
	capsule.height = max(1.0, profile.height - capsule.radius * 2.0)
	collision.shape = capsule
	collision.position.y = profile.height * 0.5
	hero.add_child(collision)

	var rig := Node3D.new()
	rig.name = "RigVisuel"
	hero.add_child(rig)
	_build_body(rig, profile)
	_build_face(rig, profile)
	_build_hair(rig, profile)
	_build_outfit(rig, profile)
	_build_weapon(rig, profile)
	_build_aura(rig, profile)
	_build_nameplate(hero, profile)

	return hero

static func _build_body(root: Node3D, p: Dictionary) -> void:
	var torso := _mesh_part("Torse", CylinderMesh.new(), p.skin)
	torso.mesh.top_radius = 0.27 * p.body_scale.x
	torso.mesh.bottom_radius = 0.32 * p.body_scale.x
	torso.mesh.height = 0.62 * p.body_scale.y
	torso.position = Vector3(0, p.height * 0.56, 0)
	root.add_child(torso)

	var hips := _mesh_part("Bassin", CapsuleMesh.new(), p.outfit_secondary)
	hips.mesh.radius = 0.28 * p.body_scale.x
	hips.mesh.height = 0.34 * p.body_scale.y
	hips.position = Vector3(0, p.height * 0.34, 0)
	root.add_child(hips)

	for side in [-1.0, 1.0]:
		var arm := _mesh_part("Bras", CapsuleMesh.new(), p.skin)
		arm.mesh.radius = 0.085 * p.body_scale.x
		arm.mesh.height = 0.52 * p.body_scale.y
		arm.position = Vector3(side * 0.34 * p.body_scale.x, p.height * 0.57, 0)
		arm.rotation_degrees.z = side * 5.0
		root.add_child(arm)

		var leg := _mesh_part("Jambe", CapsuleMesh.new(), p.outfit_secondary)
		leg.mesh.radius = 0.105 * p.body_scale.x
		leg.mesh.height = 0.68 * p.body_scale.y
		leg.position = Vector3(side * 0.13 * p.body_scale.x, p.height * 0.15, 0)
		root.add_child(leg)

		var boot := _mesh_part("Botte", BoxMesh.new(), Color("1a1514"))
		boot.mesh.size = Vector3(0.19, 0.13, 0.35) * p.body_scale
		boot.position = Vector3(side * 0.13 * p.body_scale.x, 0.065, -0.05)
		root.add_child(boot)

static func _build_face(root: Node3D, p: Dictionary) -> void:
	var head := _mesh_part("Tete", SphereMesh.new(), p.skin)
	head.mesh.radius = 0.235 * p.body_scale.x
	head.mesh.height = 0.46 * p.body_scale.y
	head.position = Vector3(0, p.height * 0.86, 0)
	root.add_child(head)

	for side in [-1.0, 1.0]:
		var eye_white := _mesh_part("Oeil", SphereMesh.new(), Color.WHITE)
		eye_white.mesh.radius = 0.038
		eye_white.mesh.height = 0.045
		eye_white.scale = Vector3(1.0, 0.82, 0.48)
		eye_white.position = Vector3(side * 0.082, p.height * 0.88, -0.207)
		root.add_child(eye_white)

		var iris := _mesh_part("Iris", SphereMesh.new(), Color("241810"))
		iris.mesh.radius = 0.017
		iris.mesh.height = 0.02
		iris.scale.z = 0.35
		iris.position = Vector3(side * 0.082, p.height * 0.88, -0.229)
		root.add_child(iris)

	var nose := _mesh_part("Nez", PrismMesh.new(), p.skin.lightened(0.04))
	nose.mesh.size = Vector3(0.055, 0.085, 0.08)
	nose.position = Vector3(0, p.height * 0.84, -0.23)
	root.add_child(nose)

	var mouth := _mesh_part("Bouche", BoxMesh.new(), Color("5a2928"))
	mouth.mesh.size = Vector3(0.11, 0.018, 0.012)
	mouth.position = Vector3(0, p.height * 0.79, -0.235)
	root.add_child(mouth)

	if p.display_name == "CHEIKH":
		var beard := _mesh_part("Barbe", SphereMesh.new(), p.hair)
		beard.mesh.radius = 0.205
		beard.mesh.height = 0.25
		beard.scale = Vector3(1.0, 0.58, 0.65)
		beard.position = Vector3(0, p.height * 0.78, -0.085)
		root.add_child(beard)

static func _build_hair(root: Node3D, p: Dictionary) -> void:
	match p.hair_style:
		"long_twists":
			for i in range(18):
				var angle := TAU * float(i) / 18.0
				var strand := _mesh_part("Tresse", CapsuleMesh.new(), p.hair)
				strand.mesh.radius = 0.028
				strand.mesh.height = 0.42 + 0.06 * sin(float(i) * 1.7)
				strand.position = Vector3(cos(angle) * 0.19, p.height * 0.92, sin(angle) * 0.16)
				strand.rotation_degrees.x = 10.0 + 18.0 * abs(sin(angle))
				root.add_child(strand)
		"short_curls":
			for i in range(22):
				var angle := TAU * float(i) / 22.0
				var curl := _mesh_part("Boucle", SphereMesh.new(), p.hair)
				curl.mesh.radius = 0.052
				curl.mesh.height = 0.07
				curl.position = Vector3(cos(angle) * 0.18, p.height * 0.965 + 0.03 * sin(float(i)), sin(angle) * 0.16)
				root.add_child(curl)
		_:
			var cap := _mesh_part("Cheveux", SphereMesh.new(), p.hair)
			cap.mesh.radius = 0.235
			cap.mesh.height = 0.22
			cap.scale = Vector3(1.0, 0.65, 1.0)
			cap.position = Vector3(0, p.height * 0.965, 0.015)
			root.add_child(cap)

static func _build_outfit(root: Node3D, p: Dictionary) -> void:
	var coat := _mesh_part("Tenue", CylinderMesh.new(), p.outfit_main)
	coat.mesh.top_radius = 0.30 * p.body_scale.x
	coat.mesh.bottom_radius = 0.34 * p.body_scale.x
	coat.mesh.height = 0.5 * p.body_scale.y
	coat.position = Vector3(0, p.height * 0.57, -0.015)
	root.add_child(coat)

	var belt := _mesh_part("Ceinture", CylinderMesh.new(), p.accent)
	belt.mesh.top_radius = 0.34 * p.body_scale.x
	belt.mesh.bottom_radius = 0.34 * p.body_scale.x
	belt.mesh.height = 0.055
	belt.position = Vector3(0, p.height * 0.39, 0)
	root.add_child(belt)

	if p.display_name == "CHEIKH":
		var cape := _mesh_part("Manteau", BoxMesh.new(), Color("4a1218"))
		cape.mesh.size = Vector3(0.58, 0.78, 0.035) * p.body_scale
		cape.position = Vector3(0, p.height * 0.52, 0.18)
		root.add_child(cape)
	elif p.display_name == "NELVYN":
		for side in [-1.0, 1.0]:
			var module := _mesh_part("ModuleTech", BoxMesh.new(), p.accent)
			module.mesh.size = Vector3(0.13, 0.18, 0.1)
			module.position = Vector3(side * 0.32, p.height * 0.57, 0)
			root.add_child(module)

static func _build_weapon(root: Node3D, p: Dictionary) -> void:
	match p.weapon:
		"sabre_lourd":
			var blade := _mesh_part("Sabre", BoxMesh.new(), Color("cdd9df"))
			blade.mesh.size = Vector3(0.065, 0.92, 0.025)
			blade.position = Vector3(0.42, p.height * 0.52, 0)
			blade.rotation_degrees.z = -12
			root.add_child(blade)
		"double_lame":
			for side in [-1.0, 1.0]:
				var blade := _mesh_part("Lame", BoxMesh.new(), Color("d8f5ff"))
				blade.mesh.size = Vector3(0.035, 0.55, 0.02)
				blade.position = Vector3(side * 0.37, p.height * 0.5, 0)
				blade.rotation_degrees.z = side * 10
				root.add_child(blade)
		_:
			for side in [-1.0, 1.0]:
				var gauntlet := _mesh_part("Gantelet", BoxMesh.new(), p.accent)
				gauntlet.mesh.size = Vector3(0.16, 0.16, 0.18)
				gauntlet.position = Vector3(side * 0.36, p.height * 0.48, -0.02)
				root.add_child(gauntlet)

static func _build_aura(root: Node3D, p: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 180
	aura.lifetime = 0.8
	aura.emitting = false
	aura.visibility_aabb = AABB(Vector3(-2, 0, -2), Vector3(4, 4, 4))

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.5
	material.direction = Vector3(0, 1, 0)
	material.spread = 35.0
	material.initial_velocity_min = 1.2
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, 1.8, 0)
	material.scale_min = 0.035
	material.scale_max = 0.11
	material.color = p.aura
	aura.process_material = material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.13, 0.28)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(p.aura, 0.8)
	glow.emission_enabled = true
	glow.emission = p.aura
	glow.emission_energy_multiplier = 4.5
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = p.height * 0.45
	root.add_child(aura)

static func _build_nameplate(hero: CharacterBody3D, p: Dictionary) -> void:
	var label := Label3D.new()
	label.name = "Nom"
	label.text = p.display_name
	label.font_size = 42
	label.outline_size = 8
	label.modulate = p.accent
	label.position = Vector3(0, p.height + 0.32, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hero.add_child(label)

static func _mesh_part(part_name: String, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	material.metallic = 0.02
	node.material_override = material
	return node
