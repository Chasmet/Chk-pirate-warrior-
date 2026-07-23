class_name EnemyFactory
extends RefCounted

const ENEMIES := [
	{"id":"pirate_novice","name":"Pirate novice","color":Color("8b4d2d"),"health":78.0,"speed":3.2,"damage":7.0,"range":1.6,"xp":24,"coins":10},
	{"id":"tireur_quais","name":"Tireur des quais","color":Color("5c6f82"),"health":62.0,"speed":2.9,"damage":8.0,"range":4.4,"xp":28,"coins":13},
	{"id":"pirate_bouclier","name":"Pirate bouclier","color":Color("4f6d5b"),"health":132.0,"speed":2.5,"damage":9.0,"range":1.7,"xp":35,"coins":16},
	{"id":"brute_mers","name":"Brute des mers","color":Color("704434"),"health":180.0,"speed":2.15,"damage":15.0,"range":2.0,"xp":44,"coins":20},
	{"id":"voleur_agile","name":"Voleur agile","color":Color("4a485f"),"health":68.0,"speed":4.8,"damage":8.0,"range":1.45,"xp":34,"coins":18},
	{"id":"medecin_pirate","name":"Médecin pirate","color":Color("b29c70"),"health":82.0,"speed":3.0,"damage":6.0,"range":2.0,"xp":38,"coins":20},
	{"id":"dompteur","name":"Dompteur","color":Color("7e5b37"),"health":105.0,"speed":3.35,"damage":11.0,"range":2.4,"xp":42,"coins":22},
	{"id":"garde_mecanique","name":"Garde mécanique","color":Color("58616d"),"health":210.0,"speed":2.45,"damage":17.0,"range":2.0,"xp":55,"coins":28},
	{"id":"crabe_blinde","name":"Crabe blindé","color":Color("a64e32"),"health":155.0,"speed":2.25,"damage":13.0,"range":1.6,"xp":40,"coins":20,"creature":"crab"},
	{"id":"singe_voleur","name":"Singe voleur","color":Color("806044"),"health":74.0,"speed":5.1,"damage":7.0,"range":1.3,"xp":32,"coins":17,"creature":"monkey"},
	{"id":"oiseau_tempete","name":"Oiseau-tempête","color":Color("52718d"),"health":96.0,"speed":4.2,"damage":12.0,"range":2.7,"xp":45,"coins":23,"creature":"bird"},
	{"id":"lezard_falaises","name":"Lézard des falaises","color":Color("67824d"),"health":120.0,"speed":3.8,"damage":12.0,"range":1.8,"xp":42,"coins":21,"creature":"lizard"}
]

const BOSSES := [
	{"id":"brakor","name":"Brakor, gardien du port","color":Color("475a6d"),"health":950.0,"speed":2.7,"damage":24.0,"range":2.5,"xp":450,"coins":240,"boss":true,"weapon":"anchor"},
	{"id":"scorpia","name":"Madame Scorpia","color":Color("78354f"),"health":820.0,"speed":4.2,"damage":21.0,"range":2.1,"xp":520,"coins":280,"boss":true,"weapon":"dual"},
	{"id":"mako","name":"Roi Mako","color":Color("315f78"),"health":1150.0,"speed":3.0,"damage":28.0,"range":2.7,"xp":620,"coins":340,"boss":true,"weapon":"trident"},
	{"id":"volkan","name":"Général Volkan","color":Color("8f2e24"),"health":1400.0,"speed":2.8,"damage":34.0,"range":3.0,"xp":760,"coins":430,"boss":true,"weapon":"hammer"},
	{"id":"vorga","name":"Amiral Vorga","color":Color("252d3d"),"health":1900.0,"speed":3.5,"damage":38.0,"range":3.2,"xp":1200,"coins":700,"boss":true,"weapon":"saber"}
]

static func create_enemy(profile: Dictionary, player: Node3D) -> EnemyAI:
	var enemy := EnemyAI.new()
	enemy.name = String(profile.get("name", "Ennemi"))
	_build_collision(enemy, profile)
	_build_model(enemy, profile)
	enemy.configure(profile, player)
	return enemy

static func profile_for_index(index: int) -> Dictionary:
	return ENEMIES[posmod(index, ENEMIES.size())]

static func boss_for_zone(zone: int) -> Dictionary:
	return BOSSES[clampi(zone, 0, BOSSES.size() - 1)]

static func _build_collision(enemy: EnemyAI, profile: Dictionary) -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	var boss_scale := 1.45 if bool(profile.get("boss", false)) else 1.0
	capsule.radius = 0.38 * boss_scale
	capsule.height = 1.05 * boss_scale
	collision.shape = capsule
	collision.position.y = 0.9 * boss_scale
	enemy.add_child(collision)

static func _build_model(enemy: EnemyAI, profile: Dictionary) -> void:
	var boss_scale := 1.48 if bool(profile.get("boss", false)) else 1.0
	var base_color: Color = profile.get("color", Color.GRAY)
	var creature := String(profile.get("creature", ""))
	if creature == "crab":
		_build_crab(enemy, base_color, boss_scale)
	elif creature == "bird":
		_build_bird(enemy, base_color, boss_scale)
	elif creature == "lizard" or creature == "monkey":
		_build_creature(enemy, base_color, boss_scale, creature)
	else:
		_build_pirate(enemy, base_color, boss_scale, profile)
	_build_label(enemy, profile, boss_scale)
	if bool(profile.get("boss", false)):
		_build_boss_aura(enemy, base_color, boss_scale)

static func _build_pirate(root: EnemyAI, color: Color, scale_value: float, profile: Dictionary) -> void:
	var torso := _part("Torse", CylinderMesh.new(), color)
	torso.mesh.top_radius = 0.30 * scale_value
	torso.mesh.bottom_radius = 0.36 * scale_value
	torso.mesh.height = 0.78 * scale_value
	torso.position.y = 1.05 * scale_value
	root.add_child(torso)
	var head := _part("Tête", SphereMesh.new(), Color("8c6044"))
	head.mesh.radius = 0.26 * scale_value
	head.mesh.height = 0.50 * scale_value
	head.position.y = 1.65 * scale_value
	root.add_child(head)
	var hat := _part("Chapeau", CylinderMesh.new(), color.darkened(0.38))
	hat.mesh.top_radius = 0.24 * scale_value
	hat.mesh.bottom_radius = 0.43 * scale_value
	hat.mesh.height = 0.14 * scale_value
	hat.position.y = 1.93 * scale_value
	root.add_child(hat)
	for side in [-1.0, 1.0]:
		var leg := _part("Jambe", CapsuleMesh.new(), Color("242832"))
		leg.mesh.radius = 0.11 * scale_value
		leg.mesh.height = 0.78 * scale_value
		leg.position = Vector3(side * 0.16, 0.45, 0) * scale_value
		root.add_child(leg)
		var arm := _part("Bras", CapsuleMesh.new(), Color("8c6044"))
		arm.mesh.radius = 0.09 * scale_value
		arm.mesh.height = 0.62 * scale_value
		arm.position = Vector3(side * 0.39, 1.10, 0) * scale_value
		arm.rotation_degrees.z = side * 12.0
		root.add_child(arm)
	_build_weapon(root, String(profile.get("weapon", "saber")), scale_value)

static func _build_weapon(root: Node3D, kind: String, scale_value: float) -> void:
	if kind == "hammer" or kind == "anchor":
		var shaft := _part("Arme", BoxMesh.new(), Color("4a3527"))
		shaft.mesh.size = Vector3(0.09, 1.45, 0.09) * scale_value
		shaft.position = Vector3(0.55, 1.0, 0) * scale_value
		shaft.rotation_degrees.z = -20.0
		root.add_child(shaft)
		var head := _part("TêteArme", BoxMesh.new(), Color("5c6470"))
		head.mesh.size = Vector3(0.55, 0.25, 0.25) * scale_value
		head.position = Vector3(0.78, 1.60, 0) * scale_value
		root.add_child(head)
	elif kind == "trident":
		var shaft := _part("Trident", BoxMesh.new(), Color("b48c3b"))
		shaft.mesh.size = Vector3(0.06, 1.7, 0.06) * scale_value
		shaft.position = Vector3(0.55, 1.1, 0) * scale_value
		root.add_child(shaft)
	else:
		var blade := _part("Sabre", BoxMesh.new(), Color("c8d4da"))
		blade.mesh.size = Vector3(0.07, 1.05, 0.03) * scale_value
		blade.position = Vector3(0.50, 0.95, -0.08) * scale_value
		blade.rotation_degrees.z = -24.0
		root.add_child(blade)

static func _build_crab(root: Node3D, color: Color, scale_value: float) -> void:
	var body := _part("Carapace", SphereMesh.new(), color)
	body.mesh.radius = 0.58 * scale_value
	body.mesh.height = 0.62 * scale_value
	body.scale = Vector3(1.35, 0.58, 1.0)
	body.position.y = 0.58 * scale_value
	root.add_child(body)
	for side in [-1.0, 1.0]:
		var claw := _part("Pince", SphereMesh.new(), color.lightened(0.12))
		claw.mesh.radius = 0.25 * scale_value
		claw.mesh.height = 0.28 * scale_value
		claw.position = Vector3(side * 0.78, 0.72, -0.05) * scale_value
		root.add_child(claw)
		for i in range(3):
			var leg := _part("Patte", BoxMesh.new(), color.darkened(0.18))
			leg.mesh.size = Vector3(0.55, 0.08, 0.08) * scale_value
			leg.position = Vector3(side * 0.55, 0.35, -0.35 + i * 0.35) * scale_value
			leg.rotation_degrees.z = side * 18.0
			root.add_child(leg)

static func _build_bird(root: Node3D, color: Color, scale_value: float) -> void:
	var body := _part("Corps", SphereMesh.new(), color)
	body.mesh.radius = 0.34 * scale_value
	body.mesh.height = 0.72 * scale_value
	body.position.y = 1.0 * scale_value
	root.add_child(body)
	for side in [-1.0, 1.0]:
		var wing := _part("Aile", PrismMesh.new(), color.lightened(0.08))
		wing.mesh.size = Vector3(0.85, 0.12, 0.48) * scale_value
		wing.position = Vector3(side * 0.55, 1.05, 0) * scale_value
		wing.rotation_degrees.z = side * 12.0
		root.add_child(wing)

static func _build_creature(root: Node3D, color: Color, scale_value: float, kind: String) -> void:
	var body := _part("Corps", CapsuleMesh.new(), color)
	body.mesh.radius = 0.34 * scale_value
	body.mesh.height = (0.9 if kind == "monkey" else 1.15) * scale_value
	body.position.y = 0.85 * scale_value
	body.rotation_degrees.x = 78.0 if kind == "lizard" else 0.0
	root.add_child(body)
	var head := _part("Tête", SphereMesh.new(), color.lightened(0.12))
	head.mesh.radius = 0.27 * scale_value
	head.mesh.height = 0.45 * scale_value
	head.position = Vector3(0, 1.35, -0.22 if kind == "lizard" else 0) * scale_value
	root.add_child(head)

static func _build_label(root: Node3D, profile: Dictionary, scale_value: float) -> void:
	var label := Label3D.new()
	label.text = String(profile.get("name", "Ennemi"))
	label.font_size = 42 if bool(profile.get("boss", false)) else 30
	label.outline_size = 7
	label.modulate = Color("f4d98b") if bool(profile.get("boss", false)) else Color.WHITE
	label.position.y = 2.25 * scale_value
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

static func _build_boss_aura(root: EnemyAI, color: Color, scale_value: float) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 140
	particles.lifetime = 1.0
	particles.emitting = false
	particles.visibility_aabb = AABB(Vector3(-4, 0, -4), Vector3(8, 7, 8))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 1.0 * scale_value
	process.direction = Vector3(0, 1, 0)
	process.spread = 40.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 3.5
	process.gravity = Vector3(0, 1.2, 0)
	process.color = color.lightened(0.2)
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.42) * scale_value
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.78)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 5.0
	quad.material = material
	particles.draw_pass_1 = quad
	particles.position.y = 1.0 * scale_value
	root.add_child(particles)
	root.aura_particles = particles

static func _part(part_name: String, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	material.metallic = 0.06
	node.material_override = material
	return node
