class_name QuinetBoatFactory
extends RefCounted

static func create_boat() -> Node3D:
	var boat := Node3D.new()
	boat.name = "NavireQuinet"

	var hull := _part("Coque", BoxMesh.new(), Color("4b2518"), 0.74, 0.08)
	hull.mesh.size = Vector3(2.35, 0.72, 5.6)
	hull.position = Vector3(0.0, 0.18, 0.0)
	boat.add_child(hull)

	var bow := _part("Proue", PrismMesh.new(), Color("6a3420"), 0.68, 0.05)
	bow.mesh.size = Vector3(2.30, 1.18, 2.35)
	bow.position = Vector3(0.0, 0.25, -3.35)
	bow.rotation_degrees.y = 90.0
	boat.add_child(bow)

	var keel := _part("Quille", BoxMesh.new(), Color("25140f"), 0.92, 0.02)
	keel.mesh.size = Vector3(0.34, 1.10, 5.2)
	keel.position = Vector3(0.0, -0.45, 0.25)
	boat.add_child(keel)

	var deck := _part("Pont", BoxMesh.new(), Color("b57a42"), 0.88, 0.0)
	deck.mesh.size = Vector3(2.05, 0.16, 4.65)
	deck.position = Vector3(0.0, 0.61, 0.20)
	boat.add_child(deck)

	for side in [-1.0, 1.0]:
		var rail := _part("Bastingage", BoxMesh.new(), Color("d09a58"), 0.72, 0.0)
		rail.mesh.size = Vector3(0.10, 0.58, 4.85)
		rail.position = Vector3(side * 1.05, 0.92, 0.15)
		boat.add_child(rail)
		for index in range(5):
			var post := _part("Poteau", CylinderMesh.new(), Color("e1b56d"), 0.72, 0.0)
			post.mesh.top_radius = 0.055
			post.mesh.bottom_radius = 0.065
			post.mesh.height = 0.72
			post.position = Vector3(side * 1.05, 0.96, -1.78 + index * 0.92)
			boat.add_child(post)

	var mast := _part("Mât", CylinderMesh.new(), Color("59351f"), 0.82, 0.0)
	mast.mesh.top_radius = 0.10
	mast.mesh.bottom_radius = 0.14
	mast.mesh.height = 6.8
	mast.position = Vector3(0.0, 3.75, 0.2)
	boat.add_child(mast)

	var yard := _part("Vergue", CylinderMesh.new(), Color("51301d"), 0.82, 0.0)
	yard.mesh.top_radius = 0.07
	yard.mesh.bottom_radius = 0.07
	yard.mesh.height = 4.25
	yard.position = Vector3(0.0, 5.2, 0.15)
	yard.rotation_degrees.z = 90.0
	boat.add_child(yard)

	var sail := _part("Voile", QuadMesh.new(), Color("f2e4c2"), 0.62, 0.0)
	sail.mesh.size = Vector2(3.85, 3.25)
	sail.position = Vector3(0.0, 3.85, 0.10)
	sail.rotation_degrees.y = 180.0
	(sail.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	boat.add_child(sail)

	var emblem := _part("Emblème", CylinderMesh.new(), Color("d6a63d"), 0.40, 0.16)
	emblem.mesh.top_radius = 0.42
	emblem.mesh.bottom_radius = 0.42
	emblem.mesh.height = 0.045
	emblem.position = Vector3(0.0, 3.85, 0.045)
	emblem.rotation_degrees.x = 90.0
	boat.add_child(emblem)

	var flag := _part("Pavillon", QuadMesh.new(), Color("7c2026"), 0.64, 0.06)
	flag.mesh.size = Vector2(1.55, 0.82)
	flag.position = Vector3(0.78, 6.63, 0.15)
	flag.rotation_degrees.y = 180.0
	(flag.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	boat.add_child(flag)

	var cabin := _part("Cabine", BoxMesh.new(), Color("25384b"), 0.62, 0.18)
	cabin.mesh.size = Vector3(1.58, 1.18, 1.45)
	cabin.position = Vector3(0.0, 1.17, 1.65)
	boat.add_child(cabin)

	for side in [-1.0, 1.0]:
		var lantern := _part("Lanterne", SphereMesh.new(), Color("ffc85a"), 0.30, 0.05)
		lantern.mesh.radius = 0.18
		lantern.mesh.height = 0.32
		lantern.position = Vector3(side * 0.76, 1.55, 1.06)
		var lantern_material := lantern.material_override as StandardMaterial3D
		lantern_material.emission_enabled = true
		lantern_material.emission = Color("ffb532")
		lantern_material.emission_energy_multiplier = 3.0
		boat.add_child(lantern)

	var wake := GPUParticles3D.new()
	wake.name = "Sillage"
	wake.amount = 120
	wake.lifetime = 1.2
	wake.emitting = false
	wake.visibility_aabb = AABB(Vector3(-5, -2, -8), Vector3(10, 5, 16))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.9, 0.08, 0.35)
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
	wake.position = Vector3(0, -0.05, 3.0)
	boat.add_child(wake)

	boat.scale = Vector3.ONE * 0.92
	return boat

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
