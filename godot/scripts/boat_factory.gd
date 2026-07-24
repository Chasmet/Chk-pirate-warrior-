class_name QuinetBoatFactory
extends RefCounted

static func create_boat() -> Node3D:
	var boat := Node3D.new()
	boat.name = "NavireQuinet"

	var hull := _part("Coque", BoxMesh.new(), Color("4b2518"), 0.74, 0.08)
	hull.mesh.size = Vector3(3.70, 1.12, 8.8)
	hull.position = Vector3(0.0, 0.05, 0.0)
	boat.add_child(hull)

	var bow := _part("Proue", PrismMesh.new(), Color("6a3420"), 0.68, 0.05)
	bow.mesh.size = Vector3(3.55, 1.72, 3.10)
	bow.position = Vector3(0.0, 0.20, -5.35)
	bow.rotation_degrees.y = 90.0
	boat.add_child(bow)

	var keel := _part("Quille", BoxMesh.new(), Color("25140f"), 0.92, 0.02)
	keel.mesh.size = Vector3(0.42, 1.62, 8.2)
	keel.position = Vector3(0.0, -0.68, 0.30)
	boat.add_child(keel)

	var deck := _part("Pont", BoxMesh.new(), Color("b57a42"), 0.88, 0.0)
	deck.mesh.size = Vector3(3.32, 0.18, 7.55)
	deck.position = Vector3(0.0, 0.70, 0.32)
	boat.add_child(deck)

	for side in [-1.0, 1.0]:
		var rail := _part("Bastingage", BoxMesh.new(), Color("d09a58"), 0.72, 0.0)
		rail.mesh.size = Vector3(0.12, 0.64, 7.72)
		rail.position = Vector3(side * 1.72, 1.04, 0.15)
		boat.add_child(rail)
		for index in range(8):
			var post := _part("Poteau", CylinderMesh.new(), Color("e1b56d"), 0.72, 0.0)
			post.mesh.top_radius = 0.055
			post.mesh.bottom_radius = 0.065
			post.mesh.height = 0.80
			post.position = Vector3(side * 1.72, 1.04, -3.15 + index * 0.90)
			boat.add_child(post)

	for plank_index in range(5):
		var plank_color := Color("6b3822").lightened(float(plank_index % 2) * 0.08)
		for side in [-1.0, 1.0]:
			var plank := _part("Bordé", BoxMesh.new(), plank_color, 0.86, 0.0)
			plank.mesh.size = Vector3(0.10, 0.17, 8.35)
			plank.position = Vector3(side * 1.88, -0.28 + plank_index * 0.22, 0.10)
			boat.add_child(plank)

	var voilure := Node3D.new()
	voilure.name = "Voilure"
	boat.add_child(voilure)

	var mast := _part("Mât", CylinderMesh.new(), Color("59351f"), 0.82, 0.0)
	mast.mesh.top_radius = 0.13
	mast.mesh.bottom_radius = 0.19
	mast.mesh.height = 9.2
	mast.position = Vector3(0.0, 5.35, -0.45)
	voilure.add_child(mast)

	var yard := _part("Vergue", CylinderMesh.new(), Color("51301d"), 0.82, 0.0)
	yard.mesh.top_radius = 0.09
	yard.mesh.bottom_radius = 0.09
	yard.mesh.height = 6.65
	yard.position = Vector3(0.0, 7.0, -0.42)
	yard.rotation_degrees.z = 90.0
	voilure.add_child(yard)

	var sail := _part("Voile", QuadMesh.new(), Color("f2e4c2"), 0.62, 0.0)
	sail.mesh.size = Vector2(6.15, 4.75)
	sail.position = Vector3(0.0, 4.80, -0.48)
	sail.rotation_degrees.y = 180.0
	(sail.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	voilure.add_child(sail)

	for stripe_index in [-2, 0, 2]:
		var stripe := _part("BandeRouge", QuadMesh.new(), Color("a82f2e"), 0.66, 0.0)
		stripe.mesh.size = Vector2(0.72, 4.72)
		stripe.position = Vector3(float(stripe_index) * 1.02, 4.80, -0.505)
		stripe.rotation_degrees.y = 180.0
		(stripe.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		voilure.add_child(stripe)

	var emblem := _part("Emblème", CylinderMesh.new(), Color("d6a63d"), 0.40, 0.16)
	emblem.mesh.top_radius = 0.62
	emblem.mesh.bottom_radius = 0.62
	emblem.mesh.height = 0.045
	emblem.position = Vector3(0.0, 4.80, -0.535)
	emblem.rotation_degrees.x = 90.0
	voilure.add_child(emblem)

	var flag := _part("Pavillon", QuadMesh.new(), Color("7c2026"), 0.64, 0.06)
	flag.mesh.size = Vector2(2.05, 1.05)
	flag.position = Vector3(1.02, 9.65, -0.42)
	flag.rotation_degrees.y = 180.0
	(flag.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	voilure.add_child(flag)

	var cabin := _part("Cabine", BoxMesh.new(), Color("25384b"), 0.62, 0.18)
	cabin.mesh.size = Vector3(2.70, 1.55, 2.35)
	cabin.position = Vector3(0.0, 1.48, 3.05)
	boat.add_child(cabin)

	var cabin_roof := _part("ToitCabine", PrismMesh.new(), Color("6e3024"), 0.78, 0.02)
	cabin_roof.mesh.size = Vector3(3.15, 0.75, 2.75)
	cabin_roof.position = Vector3(0.0, 2.57, 3.05)
	cabin_roof.rotation_degrees.y = 90.0
	boat.add_child(cabin_roof)

	for side in [-1.0, 1.0]:
		var window := _part("FenêtreCabine", BoxMesh.new(), Color("69c7df"), 0.20, 0.35)
		window.mesh.size = Vector3(0.48, 0.52, 0.05)
		window.position = Vector3(side * 0.68, 1.56, 1.85)
		var window_material := window.material_override as StandardMaterial3D
		window_material.emission_enabled = true
		window_material.emission = Color("2d829f")
		window_material.emission_energy_multiplier = 1.6
		boat.add_child(window)

	for side in [-1.0, 1.0]:
		var lantern := _part("Lanterne", SphereMesh.new(), Color("ffc85a"), 0.30, 0.05)
		lantern.mesh.radius = 0.18
		lantern.mesh.height = 0.32
		lantern.position = Vector3(side * 1.28, 2.10, 1.78)
		var lantern_material := lantern.material_override as StandardMaterial3D
		lantern_material.emission_enabled = true
		lantern_material.emission = Color("ffb532")
		lantern_material.emission_energy_multiplier = 3.0
		boat.add_child(lantern)

	_build_helm(boat)
	_build_rudder(boat)
	_build_figurehead(boat)

	var wake := GPUParticles3D.new()
	wake.name = "Sillage"
	wake.amount = 120
	wake.lifetime = 1.2
	wake.emitting = false
	wake.visibility_aabb = AABB(Vector3(-5, -2, -8), Vector3(10, 5, 16))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(1.45, 0.08, 0.52)
	process.direction = Vector3(0, 0.18, 1)
	process.spread = 24.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.5
	process.gravity = Vector3(0, -0.7, 0)
	process.color = Color(0.75, 0.94, 1.0, 0.82)
	wake.process_material = process
	var foam := QuadMesh.new()
	foam.size = Vector2(0.24, 0.24)
	var foam_material := StandardMaterial3D.new()
	foam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_material.albedo_color = Color(0.82, 0.96, 1.0, 0.84)
	foam_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	foam.material = foam_material
	wake.draw_pass_1 = foam
	wake.position = Vector3(0, -0.10, 4.65)
	boat.add_child(wake)

	boat.scale = Vector3.ONE * 0.84
	return boat

static func _build_helm(boat: Node3D) -> void:
	var station := Node3D.new()
	station.name = "PosteDePilotage"
	station.position = Vector3(0.0, 0.0, 1.28)
	boat.add_child(station)
	var pedestal := _part("PiedGouvernail", BoxMesh.new(), Color("56301f"), 0.86, 0.04)
	pedestal.mesh.size = Vector3(0.72, 1.58, 0.72)
	pedestal.position = Vector3(0.0, 1.38, 0.20)
	station.add_child(pedestal)
	var helm := Node3D.new()
	helm.name = "Gouvernail3D"
	helm.position = Vector3(0.0, 2.28, -0.18)
	station.add_child(helm)
	var rim := _part("Jante", TorusMesh.new(), Color("7b4729"), 0.68, 0.05)
	rim.mesh.inner_radius = 0.72
	rim.mesh.outer_radius = 0.90
	rim.mesh.rings = 28
	rim.mesh.ring_segments = 20
	rim.rotation_degrees.x = 90.0
	helm.add_child(rim)
	var hub := _part("Moyeu", CylinderMesh.new(), Color("c68a42"), 0.46, 0.18)
	hub.mesh.top_radius = 0.22
	hub.mesh.bottom_radius = 0.22
	hub.mesh.height = 0.34
	hub.rotation_degrees.x = 90.0
	helm.add_child(hub)
	for spoke_index in range(8):
		var angle := TAU * float(spoke_index) / 8.0
		var spoke := _part("Rayon", CylinderMesh.new(), Color("a76838"), 0.72, 0.02)
		spoke.mesh.top_radius = 0.055
		spoke.mesh.bottom_radius = 0.07
		spoke.mesh.height = 1.92
		spoke.position = Vector3(cos(angle) * 0.48, sin(angle) * 0.48, 0.0)
		spoke.rotation_degrees.z = rad_to_deg(angle) - 90.0
		helm.add_child(spoke)

static func _build_rudder(boat: Node3D) -> void:
	var rudder := Node3D.new()
	rudder.name = "GouvernailArrière"
	rudder.position = Vector3(0.0, -0.35, 4.75)
	boat.add_child(rudder)
	var blade := _part("Pale", BoxMesh.new(), Color("3b2016"), 0.92, 0.0)
	blade.mesh.size = Vector3(1.18, 1.55, 0.20)
	blade.position.y = -0.45
	rudder.add_child(blade)
	var shaft := _part("Axe", CylinderMesh.new(), Color("6a4128"), 0.84, 0.02)
	shaft.mesh.top_radius = 0.10
	shaft.mesh.bottom_radius = 0.12
	shaft.mesh.height = 2.2
	shaft.position.y = 0.30
	rudder.add_child(shaft)

static func _build_figurehead(boat: Node3D) -> void:
	var figure := Node3D.new()
	figure.name = "FigureDeProue"
	figure.position = Vector3(0.0, 0.65, -6.42)
	boat.add_child(figure)
	var neck := _part("Cou", CylinderMesh.new(), Color("e4ddd0"), 0.65, 0.02)
	neck.mesh.top_radius = 0.28
	neck.mesh.bottom_radius = 0.36
	neck.mesh.height = 1.85
	neck.rotation_degrees.x = -24.0
	figure.add_child(neck)
	var head := _part("TêteBélier", SphereMesh.new(), Color("eee7db"), 0.58, 0.02)
	head.mesh.radius = 0.55
	head.mesh.height = 0.82
	head.position = Vector3(0.0, 1.05, -0.42)
	head.scale = Vector3(0.9, 0.72, 1.25)
	figure.add_child(head)
	for side in [-1.0, 1.0]:
		var horn := _part("Corne", TorusMesh.new(), Color("8a765c"), 0.72, 0.0)
		horn.mesh.inner_radius = 0.20
		horn.mesh.outer_radius = 0.34
		horn.position = Vector3(side * 0.48, 1.15, -0.30)
		horn.rotation_degrees = Vector3(90.0, 0.0, 90.0)
		figure.add_child(horn)

static func _part(part_name: String, mesh: PrimitiveMesh, color: Color, roughness: float, metallic: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	node.material_override = material
	return node
