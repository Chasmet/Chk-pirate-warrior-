class_name EnemyFactory
extends RefCounted

const ENEMIES := [
	{"id":"pirate_novice","name":"Pirate novice","color":Color("8b4d2d"),"accent":Color("d39b4c"),"health":78.0,"speed":3.2,"damage":7.0,"range":1.6,"xp":24,"coins":10,"weapon":"saber","style":"bandana"},
	{"id":"tireur_quais","name":"Tireur des quais","color":Color("5c6f82"),"accent":Color("92bed7"),"health":62.0,"speed":2.9,"damage":8.0,"range":4.4,"xp":28,"coins":13,"weapon":"rifle","style":"coat"},
	{"id":"pirate_bouclier","name":"Pirate bouclier","color":Color("4f6d5b"),"accent":Color("c8aa58"),"health":132.0,"speed":2.5,"damage":9.0,"range":1.7,"xp":35,"coins":16,"weapon":"shield","style":"armor"},
	{"id":"brute_mers","name":"Brute des mers","color":Color("704434"),"accent":Color("d5673f"),"health":180.0,"speed":2.15,"damage":15.0,"range":2.0,"xp":44,"coins":20,"weapon":"hammer","style":"brute"},
	{"id":"voleur_agile","name":"Voleur agile","color":Color("4a485f"),"accent":Color("bf62dc"),"health":68.0,"speed":4.8,"damage":8.0,"range":1.45,"xp":34,"coins":18,"weapon":"dual","style":"hood"},
	{"id":"medecin_pirate","name":"Médecin pirate","color":Color("b29c70"),"accent":Color("e7ecef"),"health":82.0,"speed":3.0,"damage":6.0,"range":2.0,"xp":38,"coins":20,"weapon":"staff","style":"medic"},
	{"id":"dompteur","name":"Dompteur","color":Color("7e5b37"),"accent":Color("e09a45"),"health":105.0,"speed":3.35,"damage":11.0,"range":2.4,"xp":42,"coins":22,"weapon":"whip","style":"hunter"},
	{"id":"garde_mecanique","name":"Garde mécanique","color":Color("58616d"),"accent":Color("4fd4d9"),"health":210.0,"speed":2.45,"damage":17.0,"range":2.0,"xp":55,"coins":28,"weapon":"gear","style":"mechanic"},
	{"id":"crabe_blinde","name":"Crabe blindé","color":Color("a64e32"),"health":155.0,"speed":2.25,"damage":13.0,"range":1.6,"xp":40,"coins":20,"creature":"crab"},
	{"id":"singe_voleur","name":"Singe voleur","color":Color("806044"),"health":74.0,"speed":5.1,"damage":7.0,"range":1.3,"xp":32,"coins":17,"creature":"monkey"},
	{"id":"oiseau_tempete","name":"Oiseau-tempête","color":Color("52718d"),"health":96.0,"speed":4.2,"damage":12.0,"range":2.7,"xp":45,"coins":23,"creature":"bird"},
	{"id":"lezard_falaises","name":"Lézard des falaises","color":Color("67824d"),"health":120.0,"speed":3.8,"damage":12.0,"range":1.8,"xp":42,"coins":21,"creature":"lizard"}
]

const BOSSES := [
	{"id":"brakor","name":"Brakor, titan des quais","color":Color("475a6d"),"accent":Color("e2a63e"),"health":950.0,"speed":2.7,"damage":24.0,"range":2.7,"xp":450,"coins":240,"boss":true,"weapon":"anchor","design":"harbor_titan","scale":1.72},
	{"id":"scorpia","name":"Madame Scorpia","color":Color("78354f"),"accent":Color("e96ca1"),"health":900.0,"speed":4.2,"damage":22.0,"range":2.2,"xp":520,"coins":280,"boss":true,"weapon":"dual","design":"scorpion_queen","scale":1.58},
	{"id":"kryl","name":"Kryl, roi du givre","color":Color("477a99"),"accent":Color("a8efff"),"health":1180.0,"speed":3.1,"damage":29.0,"range":3.0,"xp":640,"coins":350,"boss":true,"weapon":"ice_spear","design":"frost_king","scale":1.68},
	{"id":"mako","name":"Sultan Mako des dunes","color":Color("8b6435"),"accent":Color("f0c35a"),"health":1320.0,"speed":3.25,"damage":31.0,"range":2.9,"xp":710,"coins":390,"boss":true,"weapon":"trident","design":"dune_sultan","scale":1.70},
	{"id":"volkan","name":"Général Volkan","color":Color("8f2e24"),"accent":Color("ff5a24"),"health":1550.0,"speed":2.85,"damage":35.0,"range":3.1,"xp":820,"coins":470,"boss":true,"weapon":"hammer","design":"lava_general","scale":1.80},
	{"id":"vorga","name":"Amiral Vorga, maître des orages","color":Color("252d3d"),"accent":Color("61c9ff"),"health":2050.0,"speed":3.55,"damage":40.0,"range":3.3,"xp":1250,"coins":720,"boss":true,"weapon":"storm_blades","design":"storm_admiral","scale":1.76}
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
	var boss_scale := float(profile.get("scale", 1.45)) if bool(profile.get("boss", false)) else 1.0
	capsule.radius = 0.38 * boss_scale
	capsule.height = 1.05 * boss_scale
	collision.shape = capsule
	collision.position.y = 0.9 * boss_scale
	enemy.add_child(collision)

static func _build_model(enemy: EnemyAI, profile: Dictionary) -> void:
	var boss_scale := float(profile.get("scale", 1.48)) if bool(profile.get("boss", false)) else 1.0
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
	if bool(profile.get("boss", false)):
		_build_boss_signature(enemy, profile, boss_scale)
	_build_label(enemy, profile, boss_scale)
	if bool(profile.get("boss", false)):
		_build_boss_aura(enemy, base_color, boss_scale)

static func _build_pirate(root: EnemyAI, color: Color, scale_value: float, profile: Dictionary) -> void:
	var accent: Color = profile.get("accent", color.lightened(0.28))
	var style := String(profile.get("style", "captain" if bool(profile.get("boss", false)) else "bandana"))
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
	var coat := _part("Manteau", BoxMesh.new(), color.darkened(0.16))
	coat.mesh.size = Vector3(0.58, 0.74, 0.16) * scale_value
	coat.position = Vector3(0, 1.06, 0.22) * scale_value
	root.add_child(coat)
	var belt := _part("Ceinture", CylinderMesh.new(), Color("2c1d18"))
	belt.mesh.top_radius = 0.37 * scale_value
	belt.mesh.bottom_radius = 0.37 * scale_value
	belt.mesh.height = 0.12 * scale_value
	belt.position.y = 0.78 * scale_value
	root.add_child(belt)
	var buckle := _part("Boucle", BoxMesh.new(), accent)
	buckle.mesh.size = Vector3(0.16, 0.14, 0.07) * scale_value
	buckle.position = Vector3(0, 0.79, -0.36) * scale_value
	root.add_child(buckle)
	for side in [-1.0, 1.0]:
		var eye := _part("Œil", SphereMesh.new(), Color("ecf4f4"))
		eye.mesh.radius = 0.055 * scale_value
		eye.mesh.height = 0.09 * scale_value
		eye.position = Vector3(side * 0.085, 1.70, -0.235) * scale_value
		root.add_child(eye)
		var pupil := _part("Pupille", SphereMesh.new(), Color("12171d"))
		pupil.mesh.radius = 0.022 * scale_value
		pupil.mesh.height = 0.035 * scale_value
		pupil.position = Vector3(side * 0.085, 1.70, -0.277) * scale_value
		root.add_child(pupil)
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
		var boot := _part("Botte", BoxMesh.new(), Color("171b22"))
		boot.mesh.size = Vector3(0.24, 0.29, 0.38) * scale_value
		boot.position = Vector3(side * 0.16, 0.15, -0.08) * scale_value
		root.add_child(boot)
		if style == "armor" or style == "brute" or bool(profile.get("boss", false)):
			var shoulder := _part("Épaulette", SphereMesh.new(), accent)
			shoulder.mesh.radius = (0.20 if style != "brute" else 0.27) * scale_value
			shoulder.mesh.height = 0.26 * scale_value
			shoulder.position = Vector3(side * 0.40, 1.40, 0) * scale_value
			root.add_child(shoulder)
	match style:
		"hood":
			var hood := _part("Capuche", SphereMesh.new(), color.darkened(0.35))
			hood.mesh.radius = 0.34 * scale_value
			hood.mesh.height = 0.58 * scale_value
			hood.position.y = 1.70 * scale_value
			root.add_child(hood)
		"medic":
			var badge := _part("InsigneMédecin", BoxMesh.new(), Color("f1f3ed"))
			badge.mesh.size = Vector3(0.10, 0.40, 0.05) * scale_value
			badge.position = Vector3(0, 1.08, -0.38) * scale_value
			root.add_child(badge)
			var badge_cross := _part("CroixMédecin", BoxMesh.new(), Color("e6534b"))
			badge_cross.mesh.size = Vector3(0.34, 0.10, 0.055) * scale_value
			badge_cross.position = badge.position
			root.add_child(badge_cross)
		"mechanic":
			var lens := _glow_part("ViseurMécanique", SphereMesh.new(), accent, 3.6)
			lens.mesh.radius = 0.10 * scale_value
			lens.mesh.height = 0.11 * scale_value
			lens.position = Vector3(0.09, 1.70, -0.29) * scale_value
			root.add_child(lens)
		_:
			var bandana := _part("Bandana", CylinderMesh.new(), accent)
			bandana.mesh.top_radius = 0.275 * scale_value
			bandana.mesh.bottom_radius = 0.285 * scale_value
			bandana.mesh.height = 0.11 * scale_value
			bandana.position.y = 1.77 * scale_value
			root.add_child(bandana)
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
	elif kind == "trident" or kind == "ice_spear":
		var shaft := _part("Trident", BoxMesh.new(), Color("b48c3b"))
		shaft.mesh.size = Vector3(0.06, 1.7, 0.06) * scale_value
		shaft.position = Vector3(0.55, 1.1, 0) * scale_value
		root.add_child(shaft)
		for offset in [-0.13, 0.0, 0.13]:
			var tip_color := Color("9ceeff") if kind == "ice_spear" else Color("e2c167")
			var tip := _glow_part("PointeTrident", CylinderMesh.new(), tip_color, 3.8 if kind == "ice_spear" else 1.4)
			tip.mesh.top_radius = 0.0
			tip.mesh.bottom_radius = 0.055 * scale_value
			tip.mesh.height = 0.42 * scale_value
			tip.position = Vector3(0.55 + offset * scale_value, 2.10, 0) * scale_value
			root.add_child(tip)
	elif kind == "dual" or kind == "storm_blades":
		for side in [-1.0, 1.0]:
			var blade_color := Color("70d6ff") if kind == "storm_blades" else Color("d9e1e5")
			var blade := _glow_part("SabreDouble", BoxMesh.new(), blade_color, 4.6 if kind == "storm_blades" else 1.0)
			blade.mesh.size = Vector3(0.055, 1.05, 0.035) * scale_value
			blade.position = Vector3(side * 0.53, 0.98, -0.12) * scale_value
			blade.rotation_degrees.z = side * -23.0
			root.add_child(blade)
	elif kind == "rifle":
		var rifle := _part("Fusil", BoxMesh.new(), Color("493021"))
		rifle.mesh.size = Vector3(0.12, 1.55, 0.12) * scale_value
		rifle.position = Vector3(0.52, 1.10, -0.14) * scale_value
		rifle.rotation_degrees.z = -34.0
		root.add_child(rifle)
		var barrel := _part("CanonFusil", CylinderMesh.new(), Color("89939b"))
		barrel.mesh.top_radius = 0.045 * scale_value
		barrel.mesh.bottom_radius = 0.055 * scale_value
		barrel.mesh.height = 0.95 * scale_value
		barrel.position = Vector3(0.78, 1.55, -0.14) * scale_value
		barrel.rotation_degrees.z = -34.0
		root.add_child(barrel)
	elif kind == "shield":
		var shield := _part("Bouclier", CylinderMesh.new(), Color("657c74"))
		shield.mesh.top_radius = 0.48 * scale_value
		shield.mesh.bottom_radius = 0.48 * scale_value
		shield.mesh.height = 0.12 * scale_value
		shield.position = Vector3(-0.47, 1.02, -0.32) * scale_value
		shield.rotation_degrees.x = 90.0
		root.add_child(shield)
	elif kind == "staff" or kind == "whip" or kind == "gear":
		var tool := _part("Outil", CylinderMesh.new(), Color("6d4a2e"))
		tool.mesh.top_radius = 0.045 * scale_value
		tool.mesh.bottom_radius = 0.065 * scale_value
		tool.mesh.height = 1.55 * scale_value
		tool.position = Vector3(0.52, 1.03, 0) * scale_value
		tool.rotation_degrees.z = -16.0
		root.add_child(tool)
		if kind == "gear":
			var gear := _glow_part("Engrenage", TorusMesh.new(), Color("55d8df"), 3.0)
			gear.mesh.inner_radius = 0.11 * scale_value
			gear.mesh.outer_radius = 0.26 * scale_value
			gear.position = Vector3(0.72, 1.72, 0) * scale_value
			root.add_child(gear)
	else:
		var blade := _part("Sabre", BoxMesh.new(), Color("c8d4da"))
		blade.mesh.size = Vector3(0.07, 1.05, 0.03) * scale_value
		blade.position = Vector3(0.50, 0.95, -0.08) * scale_value
		blade.rotation_degrees.z = -24.0
		root.add_child(blade)

static func _build_boss_signature(root: EnemyAI, profile: Dictionary, scale_value: float) -> void:
	var design := String(profile.get("design", "captain"))
	var accent: Color = profile.get("accent", Color("f0bf55"))
	match design:
		"harbor_titan":
			for side in [-1.0, 1.0]:
				var plate := _part("BlindageBrakor", BoxMesh.new(), Color("344450"))
				plate.mesh.size = Vector3(0.42, 0.34, 0.72) * scale_value
				plate.position = Vector3(side * 0.52, 1.38, 0.03) * scale_value
				plate.rotation_degrees.z = side * 18.0
				root.add_child(plate)
			for link_index in range(5):
				var link := _part("ChaîneAncre", TorusMesh.new(), Color("7f8990"))
				link.mesh.inner_radius = 0.07 * scale_value
				link.mesh.outer_radius = 0.14 * scale_value
				link.position = Vector3(0.50, 1.58 - link_index * 0.24, 0.03) * scale_value
				link.rotation_degrees.x = 90.0 if link_index % 2 == 0 else 0.0
				root.add_child(link)
		"scorpion_queen":
			for segment_index in range(6):
				var segment := _part("QueueScorpion", SphereMesh.new(), accent.darkened(float(segment_index) * 0.045))
				segment.mesh.radius = (0.20 - float(segment_index) * 0.012) * scale_value
				segment.mesh.height = 0.32 * scale_value
				segment.position = Vector3(0, 0.78 + segment_index * 0.23, 0.42 + segment_index * 0.19) * scale_value
				root.add_child(segment)
			var stinger := _glow_part("DardScorpion", CylinderMesh.new(), Color("ff75b7"), 4.8)
			stinger.mesh.top_radius = 0.0
			stinger.mesh.bottom_radius = 0.13 * scale_value
			stinger.mesh.height = 0.48 * scale_value
			stinger.position = Vector3(0, 2.18, 1.48) * scale_value
			stinger.rotation_degrees.x = 42.0
			root.add_child(stinger)
		"frost_king":
			for crown_index in range(5):
				var crown_spike := _glow_part("CouronneGivre", CylinderMesh.new(), Color("b6f4ff"), 4.2)
				crown_spike.mesh.top_radius = 0.0
				crown_spike.mesh.bottom_radius = 0.075 * scale_value
				crown_spike.mesh.height = (0.46 + absf(float(crown_index - 2)) * 0.08) * scale_value
				crown_spike.position = Vector3((crown_index - 2) * 0.12, 2.18 + absf(float(crown_index - 2)) * 0.04, 0) * scale_value
				root.add_child(crown_spike)
			for side in [-1.0, 1.0]:
				var crystal := _glow_part("CristalÉpaule", PrismMesh.new(), Color("85dff4"), 3.8)
				crystal.mesh.size = Vector3(0.42, 0.72, 0.34) * scale_value
				crystal.position = Vector3(side * 0.53, 1.62, 0) * scale_value
				crystal.rotation_degrees.z = side * 22.0
				root.add_child(crystal)
		"dune_sultan":
			var turban := _part("TurbanMako", TorusMesh.new(), Color("e9c36b"))
			turban.mesh.inner_radius = 0.18 * scale_value
			turban.mesh.outer_radius = 0.34 * scale_value
			turban.position.y = 1.92 * scale_value
			root.add_child(turban)
			var gem := _glow_part("JoyauMako", SphereMesh.new(), Color("58d8e8"), 4.6)
			gem.mesh.radius = 0.10 * scale_value
			gem.mesh.height = 0.14 * scale_value
			gem.position = Vector3(0, 1.98, -0.29) * scale_value
			root.add_child(gem)
			var cape := _part("CapeDesDunes", BoxMesh.new(), Color("5a2d26"))
			cape.mesh.size = Vector3(0.78, 1.25, 0.08) * scale_value
			cape.position = Vector3(0, 0.95, 0.35) * scale_value
			cape.rotation_degrees.x = -8.0
			root.add_child(cape)
		"lava_general":
			var core := _glow_part("CœurVolkan", SphereMesh.new(), Color("ff5522"), 7.5)
			core.mesh.radius = 0.19 * scale_value
			core.mesh.height = 0.28 * scale_value
			core.position = Vector3(0, 1.16, -0.37) * scale_value
			root.add_child(core)
			for side in [-1.0, 1.0]:
				var horn := _glow_part("CorneVolkan", CylinderMesh.new(), Color("ff7433"), 4.0)
				horn.mesh.top_radius = 0.0
				horn.mesh.bottom_radius = 0.10 * scale_value
				horn.mesh.height = 0.58 * scale_value
				horn.position = Vector3(side * 0.22, 2.20, 0) * scale_value
				horn.rotation_degrees.z = side * 26.0
				root.add_child(horn)
				var gauntlet := _part("GanteletVolkan", SphereMesh.new(), Color("2a2527"))
				gauntlet.mesh.radius = 0.25 * scale_value
				gauntlet.mesh.height = 0.35 * scale_value
				gauntlet.position = Vector3(side * 0.51, 0.92, 0) * scale_value
				root.add_child(gauntlet)
		"storm_admiral":
			for side in [-1.0, 1.0]:
				var orb := _glow_part("OrbeOrage", SphereMesh.new(), Color("66d6ff"), 7.0)
				orb.mesh.radius = 0.17 * scale_value
				orb.mesh.height = 0.25 * scale_value
				orb.position = Vector3(side * 0.62, 1.62, 0.08) * scale_value
				root.add_child(orb)
				var coat_tail := _part("PanManteauVorga", BoxMesh.new(), Color("121b2a"))
				coat_tail.mesh.size = Vector3(0.34, 1.30, 0.10) * scale_value
				coat_tail.position = Vector3(side * 0.22, 0.54, 0.36) * scale_value
				coat_tail.rotation_degrees.z = side * 7.0
				root.add_child(coat_tail)
			var crest := _glow_part("CrêteFoudre", PrismMesh.new(), Color("a1e8ff"), 5.0)
			crest.mesh.size = Vector3(0.18, 0.82, 0.30) * scale_value
			crest.position = Vector3(0, 2.22, 0.04) * scale_value
			root.add_child(crest)

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

static func _glow_part(part_name: String, mesh: PrimitiveMesh, color: Color, energy: float) -> MeshInstance3D:
	var node := _part(part_name, mesh, color)
	var material := node.material_override as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return node
