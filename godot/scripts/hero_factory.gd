class_name HeroFactory
extends RefCounted

const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"height": 1.90,
		"body_scale": Vector3(1.16, 1.05, 1.08),
		"skin": Color("70462f"),
		"hair": Color("181311"),
		"outfit_main": Color("15191c"),
		"outfit_secondary": Color("4c4032"),
		"vest": Color("141719"),
		"sash": Color("a7282c"),
		"accent": Color("d4a640"),
		"aura": Color("e43b30"),
		"hair_style": "shaved",
		"role": "Capitaine puissant",
		"weapon": "curved_saber"
	},
	"yvane": {
		"display_name": "YVANE",
		"height": 1.56,
		"body_scale": Vector3(0.88, 0.88, 0.88),
		"skin": Color("7a4e34"),
		"hair": Color("171311"),
		"outfit_main": Color("15171a"),
		"outfit_secondary": Color("22262a"),
		"vest": Color("17191c"),
		"sash": Color("66713b"),
		"accent": Color("7c4d2d"),
		"aura": Color("31a9f3"),
		"hair_style": "high_spikes",
		"role": "Éclaireur électrique",
		"weapon": "slingshot"
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"height": 1.30,
		"body_scale": Vector3(0.78, 0.77, 0.80),
		"skin": Color("805238"),
		"hair": Color("201817"),
		"outfit_main": Color("ece4d3"),
		"outfit_secondary": Color("a97842"),
		"vest": Color("274b67"),
		"sash": Color("d5a63b"),
		"accent": Color("6d452d"),
		"aura": Color("54df8a"),
		"hair_style": "short_fade",
		"role": "Inventeur tactique",
		"weapon": "toolbelt"
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
	capsule.radius = 0.34 * float(profile.body_scale.x)
	capsule.height = maxf(1.0, float(profile.height) - capsule.radius * 2.0)
	collision.shape = capsule
	collision.position.y = float(profile.height) * 0.5
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
	QuinetToonStyler.style(rig, true, Color(profile.aura))
	_build_nameplate(hero, profile)
	return hero

static func _build_body(root: Node3D, p: Dictionary) -> void:
	var height: float = float(p.height)
	var scale: Vector3 = p.body_scale
	var shoulder_width: float = 0.40 * scale.x
	if p.display_name == "CHEIKH":
		shoulder_width = 0.49 * scale.x

	var torso := _mesh_part("Torse", CapsuleMesh.new(), p.skin)
	torso.mesh.radius = 0.28 * scale.x
	torso.mesh.height = 0.72 * scale.y
	torso.scale = Vector3(1.18 if p.display_name == "CHEIKH" else 1.0, 1.0, 0.82)
	torso.position = Vector3(0, height * 0.58, 0)
	root.add_child(torso)

	var hips := _mesh_part("Bassin", CapsuleMesh.new(), p.outfit_secondary)
	hips.mesh.radius = 0.29 * scale.x
	hips.mesh.height = 0.36 * scale.y
	hips.scale.z = 0.82
	hips.position = Vector3(0, height * 0.35, 0)
	root.add_child(hips)

	for side in [-1.0, 1.0]:
		var upper_arm := _mesh_part("BrasHaut_%s" % side, CapsuleMesh.new(), p.skin)
		upper_arm.mesh.radius = (0.105 if p.display_name == "CHEIKH" else 0.083) * scale.x
		upper_arm.mesh.height = 0.44 * scale.y
		upper_arm.position = Vector3(side * shoulder_width, height * 0.61, 0)
		upper_arm.rotation_degrees.z = side * (8.0 if p.display_name == "CHEIKH" else 4.0)
		root.add_child(upper_arm)

		var forearm := _mesh_part("BrasBas_%s" % side, CapsuleMesh.new(), p.skin)
		forearm.mesh.radius = (0.098 if p.display_name == "CHEIKH" else 0.076) * scale.x
		forearm.mesh.height = 0.39 * scale.y
		forearm.position = Vector3(side * (shoulder_width + 0.045), height * 0.43, -0.01)
		forearm.rotation_degrees.z = side * 3.0
		root.add_child(forearm)

		var hand := _mesh_part("Main_%s" % side, SphereMesh.new(), p.skin)
		hand.mesh.radius = 0.105 * scale.x
		hand.mesh.height = 0.16 * scale.y
		hand.scale = Vector3(0.78, 1.0, 0.70)
		hand.position = Vector3(side * (shoulder_width + 0.055), height * 0.28, -0.02)
		root.add_child(hand)

		var thigh := _mesh_part("JambeHaut_%s" % side, CapsuleMesh.new(), p.outfit_secondary)
		thigh.mesh.radius = 0.13 * scale.x
		thigh.mesh.height = 0.52 * scale.y
		thigh.position = Vector3(side * 0.15 * scale.x, height * 0.24, 0)
		root.add_child(thigh)

		var shin := _mesh_part("JambeBas_%s" % side, CapsuleMesh.new(), p.outfit_secondary.darkened(0.08))
		shin.mesh.radius = 0.105 * scale.x
		shin.mesh.height = 0.43 * scale.y
		shin.position = Vector3(side * 0.15 * scale.x, height * 0.09, 0)
		root.add_child(shin)

		var boot := _mesh_part("Botte_%s" % side, BoxMesh.new(), Color("1b1716"))
		boot.mesh.size = Vector3(0.23, 0.15, 0.40) * scale
		boot.position = Vector3(side * 0.15 * scale.x, 0.065, -0.08)
		root.add_child(boot)

static func _build_face(root: Node3D, p: Dictionary) -> void:
	var height: float = float(p.height)
	var scale: Vector3 = p.body_scale
	var head := _mesh_part("Tete", SphereMesh.new(), p.skin)
	head.mesh.radius = 0.245 * scale.x
	head.mesh.height = 0.48 * scale.y
	head.scale = Vector3(0.94, 1.06, 0.90)
	head.position = Vector3(0, height * 0.87, 0)
	root.add_child(head)

	var jaw := _mesh_part("Machoire", SphereMesh.new(), p.skin.darkened(0.02))
	jaw.mesh.radius = 0.20 * scale.x
	jaw.mesh.height = 0.25 * scale.y
	jaw.scale = Vector3(0.90, 0.58, 0.82)
	jaw.position = Vector3(0, height * 0.79, -0.005)
	root.add_child(jaw)

	for side in [-1.0, 1.0]:
		var ear := _mesh_part("Oreille_%s" % side, SphereMesh.new(), p.skin)
		ear.mesh.radius = 0.045
		ear.mesh.height = 0.07
		ear.position = Vector3(side * 0.225 * scale.x, height * 0.86, 0)
		root.add_child(ear)

		var eye_white := _mesh_part("Oeil_%s" % side, SphereMesh.new(), Color("f5f1e9"))
		eye_white.mesh.radius = 0.041
		eye_white.mesh.height = 0.05
		eye_white.scale = Vector3(1.15, 0.72, 0.42)
		eye_white.position = Vector3(side * 0.085, height * 0.89, -0.215)
		root.add_child(eye_white)

		var iris := _mesh_part("Iris_%s" % side, SphereMesh.new(), Color("1c130f"))
		iris.mesh.radius = 0.018
		iris.mesh.height = 0.022
		iris.scale.z = 0.28
		iris.position = Vector3(side * 0.085, height * 0.89, -0.239)
		root.add_child(iris)

		var eyebrow := _mesh_part("Sourcil_%s" % side, BoxMesh.new(), p.hair)
		eyebrow.mesh.size = Vector3(0.095, 0.018, 0.018)
		eyebrow.position = Vector3(side * 0.086, height * 0.925, -0.224)
		eyebrow.rotation_degrees.z = side * (-8.0 if p.display_name == "YVANE" else -3.0)
		root.add_child(eyebrow)

	var nose := _mesh_part("Nez", PrismMesh.new(), p.skin.lightened(0.04))
	nose.mesh.size = Vector3(0.06, 0.09, 0.085)
	nose.position = Vector3(0, height * 0.855, -0.238)
	root.add_child(nose)

	var mouth := _mesh_part("Bouche", BoxMesh.new(), Color("552628"))
	mouth.mesh.size = Vector3(0.115, 0.018, 0.012)
	mouth.position = Vector3(0, height * 0.805, -0.235)
	root.add_child(mouth)

	if p.display_name == "CHEIKH":
		var beard := _mesh_part("Barbe", SphereMesh.new(), p.hair)
		beard.mesh.radius = 0.215
		beard.mesh.height = 0.28
		beard.scale = Vector3(1.0, 0.60, 0.67)
		beard.position = Vector3(0, height * 0.79, -0.075)
		root.add_child(beard)
		var moustache := _mesh_part("Moustache", BoxMesh.new(), p.hair)
		moustache.mesh.size = Vector3(0.16, 0.025, 0.035)
		moustache.position = Vector3(0, height * 0.82, -0.225)
		root.add_child(moustache)

static func _build_hair(root: Node3D, p: Dictionary) -> void:
	var height: float = float(p.height)
	match String(p.hair_style):
		"shaved":
			var cap := _mesh_part("CheveuxRases", SphereMesh.new(), p.hair)
			cap.mesh.radius = 0.242
			cap.mesh.height = 0.15
			cap.scale = Vector3(0.96, 0.48, 0.94)
			cap.position = Vector3(0, height * 0.975, 0.02)
			root.add_child(cap)
		"high_spikes":
			for i in range(16):
				var angle: float = TAU * float(i) / 16.0
				var spike := _mesh_part("Tresse_%02d" % i, CapsuleMesh.new(), p.hair)
				spike.mesh.radius = 0.035
				spike.mesh.height = 0.30 + 0.10 * absf(sin(float(i) * 1.6))
				spike.position = Vector3(cos(angle) * 0.17, height * 1.01 + 0.05 * absf(cos(angle)), sin(angle) * 0.14)
				spike.rotation_degrees = Vector3(12.0 + absf(sin(angle)) * 18.0, 0, rad_to_deg(-angle) * 0.12)
				root.add_child(spike)
		"short_fade":
			var fade := _mesh_part("Degrade", SphereMesh.new(), p.hair.darkened(0.04))
			fade.mesh.radius = 0.225
			fade.mesh.height = 0.16
			fade.scale = Vector3(0.96, 0.55, 0.94)
			fade.position = Vector3(0, height * 0.978, 0.02)
			root.add_child(fade)
			for i in range(12):
				var angle: float = TAU * float(i) / 12.0
				var curl := _mesh_part("Boucle_%02d" % i, SphereMesh.new(), p.hair)
				curl.mesh.radius = 0.048
				curl.mesh.height = 0.065
				curl.position = Vector3(cos(angle) * 0.14, height * 1.025 + 0.018 * sin(float(i)), sin(angle) * 0.12)
				root.add_child(curl)

static func _build_outfit(root: Node3D, p: Dictionary) -> void:
	var height: float = float(p.height)
	var scale: Vector3 = p.body_scale
	var shirt := _mesh_part("Chemise", CylinderMesh.new(), p.outfit_main)
	shirt.mesh.top_radius = 0.31 * scale.x
	shirt.mesh.bottom_radius = 0.34 * scale.x
	shirt.mesh.height = 0.49 * scale.y
	shirt.position = Vector3(0, height * 0.58, -0.012)
	root.add_child(shirt)

	if p.display_name == "CHEIKH":
		for side in [-1.0, 1.0]:
			var vest_panel := _mesh_part("Gilet_%s" % side, BoxMesh.new(), p.vest)
			vest_panel.mesh.size = Vector3(0.22, 0.55, 0.065) * scale
			vest_panel.position = Vector3(side * 0.15, height * 0.60, -0.25)
			vest_panel.rotation_degrees.z = side * 4.0
			root.add_child(vest_panel)
		var wrap := _mesh_part("BandageTorse", BoxMesh.new(), Color("e4ddd1"))
		wrap.mesh.size = Vector3(0.46, 0.095, 0.042) * scale
		wrap.position = Vector3(0, height * 0.60, -0.31)
		wrap.rotation_degrees.z = -25.0
		root.add_child(wrap)
		var sash := _mesh_part("EcharpeRouge", BoxMesh.new(), p.sash)
		sash.mesh.size = Vector3(0.72, 0.16, 0.08) * scale
		sash.position = Vector3(0.05, height * 0.39, -0.12)
		sash.rotation_degrees.z = -4.0
		root.add_child(sash)
		var tail := _mesh_part("ManteauRouge", BoxMesh.new(), p.sash.darkened(0.05))
		tail.mesh.size = Vector3(0.27, 0.62, 0.055) * scale
		tail.position = Vector3(0.27, height * 0.24, 0.04)
		tail.rotation_degrees.z = -12.0
		root.add_child(tail)
		for side in [-1.0, 1.0]:
			var bracer := _mesh_part("Brassard_%s" % side, CylinderMesh.new(), Color("4b2d20"))
			bracer.mesh.top_radius = 0.105 * scale.x
			bracer.mesh.bottom_radius = 0.115 * scale.x
			bracer.mesh.height = 0.22
			bracer.position = Vector3(side * 0.56, height * 0.40, 0)
			root.add_child(bracer)
	elif p.display_name == "YVANE":
		var cross_strap := _mesh_part("SangleCroisee", BoxMesh.new(), p.accent)
		cross_strap.mesh.size = Vector3(0.085, 0.64, 0.045)
		cross_strap.position = Vector3(0, height * 0.61, -0.25)
		cross_strap.rotation_degrees.z = -34.0
		root.add_child(cross_strap)
		var sash := _mesh_part("EcharpeOlive", BoxMesh.new(), p.sash)
		sash.mesh.size = Vector3(0.58, 0.13, 0.06) * scale
		sash.position = Vector3(0, height * 0.39, -0.10)
		root.add_child(sash)
		var cloth_tail := _mesh_part("ManteauOlive", BoxMesh.new(), p.sash)
		cloth_tail.mesh.size = Vector3(0.32, 0.50, 0.045)
		cloth_tail.position = Vector3(0.30, height * 0.28, 0.06)
		cloth_tail.rotation_degrees.z = -20.0
		root.add_child(cloth_tail)
	elif p.display_name == "NELVYN":
		for side in [-1.0, 1.0]:
			var vest_panel := _mesh_part("GiletBleu_%s" % side, BoxMesh.new(), p.vest)
			vest_panel.mesh.size = Vector3(0.19, 0.40, 0.055) * scale
			vest_panel.position = Vector3(side * 0.13, height * 0.60, -0.23)
			root.add_child(vest_panel)
		var shorts := _mesh_part("ShortBeige", BoxMesh.new(), p.outfit_secondary)
		shorts.mesh.size = Vector3(0.48, 0.30, 0.34) * scale
		shorts.position = Vector3(0, height * 0.31, 0)
		root.add_child(shorts)

	var belt := _mesh_part("Ceinture", CylinderMesh.new(), p.sash)
	belt.mesh.top_radius = 0.35 * scale.x
	belt.mesh.bottom_radius = 0.35 * scale.x
	belt.mesh.height = 0.065
	belt.position = Vector3(0, height * 0.40, 0)
	root.add_child(belt)
	var buckle := _mesh_part("BoucleCeinture", BoxMesh.new(), p.accent)
	buckle.mesh.size = Vector3(0.13, 0.10, 0.055)
	buckle.position = Vector3(0, height * 0.40, -0.31 * scale.z)
	root.add_child(buckle)

static func _build_weapon(root: Node3D, p: Dictionary) -> void:
	var height: float = float(p.height)
	match String(p.weapon):
		"curved_saber":
			var handle := _mesh_part("PoigneeSabre", CylinderMesh.new(), Color("38251c"))
			handle.mesh.top_radius = 0.045
			handle.mesh.bottom_radius = 0.052
			handle.mesh.height = 0.28
			handle.position = Vector3(0.50, height * 0.38, -0.03)
			handle.rotation_degrees.z = -18.0
			root.add_child(handle)
			var guard := _mesh_part("GardeSabre", BoxMesh.new(), p.accent)
			guard.mesh.size = Vector3(0.25, 0.055, 0.07)
			guard.position = Vector3(0.45, height * 0.50, -0.03)
			guard.rotation_degrees.z = -18.0
			root.add_child(guard)
			for i in range(6):
				var blade := _mesh_part("Sabre_%02d" % i, BoxMesh.new(), Color("d7e0e5"))
				blade.mesh.size = Vector3(0.075, 0.22, 0.025)
				blade.position = Vector3(0.41 - float(i) * 0.035, height * 0.58 + float(i) * 0.18, -0.03)
				blade.rotation_degrees.z = -12.0 + float(i) * 4.2
				root.add_child(blade)
		"slingshot":
			var grip := _mesh_part("LancePierrePoignee", CylinderMesh.new(), Color("654126"))
			grip.mesh.top_radius = 0.045
			grip.mesh.bottom_radius = 0.052
			grip.mesh.height = 0.30
			grip.position = Vector3(0.40, height * 0.45, -0.04)
			grip.rotation_degrees.z = -12.0
			root.add_child(grip)
			for side in [-1.0, 1.0]:
				var fork := _mesh_part("Fourche_%s" % side, CylinderMesh.new(), Color("7d522e"))
				fork.mesh.top_radius = 0.035
				fork.mesh.bottom_radius = 0.04
				fork.mesh.height = 0.28
				fork.position = Vector3(0.40 + side * 0.10, height * 0.62, -0.04)
				fork.rotation_degrees.z = side * -24.0
				root.add_child(fork)
				var elastic := _mesh_part("Elastique_%s" % side, BoxMesh.new(), Color("2a1b16"))
				elastic.mesh.size = Vector3(0.025, 0.28, 0.022)
				elastic.position = Vector3(0.40 + side * 0.06, height * 0.72, -0.055)
				elastic.rotation_degrees.z = side * 15.0
				root.add_child(elastic)
		"toolbelt":
			for side in [-1.0, 1.0]:
				var pouch := _mesh_part("Sacoche_%s" % side, BoxMesh.new(), Color("68452e"))
				pouch.mesh.size = Vector3(0.16, 0.19, 0.13)
				pouch.position = Vector3(side * 0.31, height * 0.36, -0.02)
				root.add_child(pouch)
			var gadget := _mesh_part("Gadget", CylinderMesh.new(), p.accent)
			gadget.mesh.top_radius = 0.08
			gadget.mesh.bottom_radius = 0.08
			gadget.mesh.height = 0.12
			gadget.position = Vector3(0.28, height * 0.46, -0.17)
			gadget.rotation_degrees.x = 90.0
			root.add_child(gadget)

static func _build_aura(root: Node3D, p: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 220
	aura.lifetime = 0.8
	aura.emitting = false
	aura.visibility_aabb = AABB(Vector3(-2, 0, -2), Vector3(4, 4, 4))
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.56
	material.direction = Vector3(0, 1, 0)
	material.spread = 38.0
	material.initial_velocity_min = 1.4
	material.initial_velocity_max = 3.4
	material.gravity = Vector3(0, 1.8, 0)
	material.scale_min = 0.035
	material.scale_max = 0.12
	material.color = p.aura
	aura.process_material = material
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.30)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(p.aura, 0.82)
	glow.emission_enabled = true
	glow.emission = p.aura
	glow.emission_energy_multiplier = 4.8
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = float(p.height) * 0.45
	root.add_child(aura)

static func _build_nameplate(hero: CharacterBody3D, p: Dictionary) -> void:
	var label := Label3D.new()
	label.name = "Nom"
	label.text = p.display_name
	label.font_size = 46
	label.outline_size = 9
	label.modulate = p.accent
	label.position = Vector3(0, float(p.height) + 0.34, 0)
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
