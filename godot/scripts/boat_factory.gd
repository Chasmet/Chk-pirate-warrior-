class_name QuinetBoatFactory
extends RefCounted

# Navire mobile original inspiré d'un grand bateau pirate classique : coque
# lisible, voiles rayées, poste de barre dégagé et figure de proue en bélier.
# Le modèle reste procédural et léger pour l'export Android OpenGL.

static func create_boat() -> Node3D:
	var boat := Node3D.new()
	boat.name = "NavireQuinet"

	_build_hull(boat)
	_build_decks(boat)
	_build_rails(boat)
	_build_cabin(boat)
	_build_sails(boat)
	_build_helm(boat)
	_build_rudder(boat)
	_build_figurehead(boat)
	_build_cannons(boat)
	_build_lanterns(boat)
	_build_wake(boat)

	var camera_focus := Marker3D.new()
	camera_focus.name = "CameraFocus"
	camera_focus.position = Vector3(0.0, 2.65, 0.15)
	boat.add_child(camera_focus)

	var pilot_marker := Marker3D.new()
	pilot_marker.name = "PilotMarker"
	pilot_marker.position = Vector3(0.0, 0.78, 1.48)
	boat.add_child(pilot_marker)

	boat.scale = Vector3.ONE * 0.92
	return boat

static func _build_hull(boat: Node3D) -> void:
	var hull_root := Node3D.new()
	hull_root.name = "Coque"
	boat.add_child(hull_root)

	var lower := _part("CoqueBasse", BoxMesh.new(), Color("321b15"), 0.94, 0.0)
	(lower.mesh as BoxMesh).size = Vector3(3.35, 0.82, 9.6)
	lower.position = Vector3(0.0, -0.52, 0.15)
	hull_root.add_child(lower)

	var middle := _part("CoquePrincipale", BoxMesh.new(), Color("5a2f1f"), 0.86, 0.02)
	(middle.mesh as BoxMesh).size = Vector3(4.10, 1.15, 10.35)
	middle.position = Vector3(0.0, 0.06, 0.12)
	hull_root.add_child(middle)

	var upper := _part("CoqueHaute", BoxMesh.new(), Color("734126"), 0.82, 0.02)
	(upper.mesh as BoxMesh).size = Vector3(4.42, 0.70, 9.65)
	upper.position = Vector3(0.0, 0.68, 0.26)
	hull_root.add_child(upper)

	var bow := _part("Proue", PrismMesh.new(), Color("6c3923"), 0.80, 0.03)
	(bow.mesh as PrismMesh).size = Vector3(4.35, 2.35, 3.35)
	bow.position = Vector3(0.0, 0.05, -6.18)
	bow.rotation_degrees.y = 90.0
	hull_root.add_child(bow)

	var stern := _part("Poupe", PrismMesh.new(), Color("593020"), 0.84, 0.02)
	(stern.mesh as PrismMesh).size = Vector3(4.20, 1.85, 2.55)
	stern.position = Vector3(0.0, 0.20, 5.55)
	stern.rotation_degrees.y = -90.0
	hull_root.add_child(stern)

	var keel := _part("Quille", BoxMesh.new(), Color("20110e"), 0.98, 0.0)
	(keel.mesh as BoxMesh).size = Vector3(0.52, 1.85, 10.6)
	keel.position = Vector3(0.0, -1.04, 0.35)
	hull_root.add_child(keel)

	for plank_index in range(6):
		var plank_color := Color("6b3822").lightened(float(plank_index % 2) * 0.065)
		for side in [-1.0, 1.0]:
			var plank := _part("Bordé_%d" % plank_index, BoxMesh.new(), plank_color, 0.90, 0.0)
			(plank.mesh as BoxMesh).size = Vector3(0.11, 0.16, 9.65)
			plank.position = Vector3(side * 2.13, -0.38 + float(plank_index) * 0.22, 0.20)
			hull_root.add_child(plank)

	for side in [-1.0, 1.0]:
		var trim := _part("LiseréDoré", BoxMesh.new(), Color("c99742"), 0.50, 0.18)
		(trim.mesh as BoxMesh).size = Vector3(0.10, 0.13, 9.85)
		trim.position = Vector3(side * 2.18, 0.82, 0.20)
		hull_root.add_child(trim)

static func _build_decks(boat: Node3D) -> void:
	var main_deck := _part("Pont", BoxMesh.new(), Color("b47a42"), 0.88, 0.0)
	(main_deck.mesh as BoxMesh).size = Vector3(3.78, 0.18, 9.25)
	main_deck.position = Vector3(0.0, 1.08, -0.05)
	boat.add_child(main_deck)

	var aft_deck := _part("PontSupérieur", BoxMesh.new(), Color("c28a4e"), 0.86, 0.0)
	(aft_deck.mesh as BoxMesh).size = Vector3(3.65, 0.22, 3.40)
	aft_deck.position = Vector3(0.0, 1.46, 3.65)
	boat.add_child(aft_deck)

	var front_deck := _part("GaillardAvant", BoxMesh.new(), Color("a96d3a"), 0.90, 0.0)
	(front_deck.mesh as BoxMesh).size = Vector3(3.55, 0.20, 2.70)
	front_deck.position = Vector3(0.0, 1.36, -4.35)
	boat.add_child(front_deck)

	for index in range(9):
		var seam := _part("JointPont", BoxMesh.new(), Color("714024"), 0.92, 0.0)
		(seam.mesh as BoxMesh).size = Vector3(3.58, 0.022, 0.035)
		seam.position = Vector3(0.0, 1.18, -3.8 + float(index) * 0.95)
		boat.add_child(seam)

static func _build_rails(boat: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var rail := _part("Bastingage", BoxMesh.new(), Color("d0a05b"), 0.72, 0.0)
		(rail.mesh as BoxMesh).size = Vector3(0.13, 0.18, 9.8)
		rail.position = Vector3(side * 2.05, 1.78, 0.12)
		boat.add_child(rail)
		for index in range(11):
			var post := _part("PoteauBastingage", CylinderMesh.new(), Color("d7aa65"), 0.72, 0.0)
			var post_mesh := post.mesh as CylinderMesh
			post_mesh.top_radius = 0.055
			post_mesh.bottom_radius = 0.075
			post_mesh.height = 1.20
			post.position = Vector3(side * 2.05, 1.40, -4.45 + float(index) * 0.90)
			boat.add_child(post)

	for z_value in [-4.85, 4.95]:
		var cross_rail := _part("BastingageAvantArrière", BoxMesh.new(), Color("d0a05b"), 0.72, 0.0)
		(cross_rail.mesh as BoxMesh).size = Vector3(4.05, 0.16, 0.13)
		cross_rail.position = Vector3(0.0, 1.78, z_value)
		boat.add_child(cross_rail)

static func _build_cabin(boat: Node3D) -> void:
	var cabin := Node3D.new()
	cabin.name = "Cabine"
	cabin.position = Vector3(0.0, 0.0, 4.08)
	boat.add_child(cabin)

	var body := _part("CorpsCabine", BoxMesh.new(), Color("293c4e"), 0.66, 0.12)
	(body.mesh as BoxMesh).size = Vector3(3.25, 1.52, 2.35)
	body.position = Vector3(0.0, 2.05, 0.0)
	cabin.add_child(body)

	var roof := _part("ToitCabine", PrismMesh.new(), Color("6e3024"), 0.78, 0.02)
	(roof.mesh as PrismMesh).size = Vector3(3.72, 0.86, 2.82)
	roof.position = Vector3(0.0, 3.18, 0.0)
	roof.rotation_degrees.y = 90.0
	cabin.add_child(roof)

	for side in [-1.0, 0.0, 1.0]:
		var window := _part("FenêtreCabine", BoxMesh.new(), Color("66c1db"), 0.22, 0.30)
		(window.mesh as BoxMesh).size = Vector3(0.58, 0.58, 0.06)
		window.position = Vector3(side * 0.92, 2.15, -1.20)
		var glass := window.material_override as StandardMaterial3D
		glass.emission_enabled = true
		glass.emission = Color("2d7f9c")
		glass.emission_energy_multiplier = 1.7
		cabin.add_child(window)

	var door := _part("PorteCabine", BoxMesh.new(), Color("5a2d20"), 0.86, 0.0)
	(door.mesh as BoxMesh).size = Vector3(0.86, 1.42, 0.08)
	door.position = Vector3(0.0, 1.92, -1.22)
	cabin.add_child(door)

static func _build_sails(boat: Node3D) -> void:
	var voilure := Node3D.new()
	voilure.name = "Voilure"
	boat.add_child(voilure)

	_build_mast(voilure, "GrandMât", Vector3(0.0, 5.55, -1.10), 9.7, 0.20)
	_build_yard(voilure, "GrandeVergue", Vector3(0.0, 7.35, -1.10), 7.25)
	_build_striped_sail(voilure, Vector3(0.0, 5.35, -1.16), Vector2(6.65, 4.05), 7)

	_build_yard(voilure, "VergueHaute", Vector3(0.0, 9.55, -1.08), 5.25)
	var upper_sail := _part("VoileHaute", QuadMesh.new(), Color("eee2c8"), 0.64, 0.0)
	(upper_sail.mesh as QuadMesh).size = Vector2(4.65, 2.15)
	upper_sail.position = Vector3(0.0, 8.55, -1.14)
	upper_sail.rotation_degrees.y = 180.0
	_configure_sail_material(upper_sail)
	voilure.add_child(upper_sail)

	_build_mast(voilure, "MâtAvant", Vector3(0.0, 4.45, -4.10), 7.25, 0.15)
	_build_yard(voilure, "VergueAvant", Vector3(0.0, 5.45, -4.10), 4.45)
	var front_sail := _part("VoileAvant", QuadMesh.new(), Color("f0e5cf"), 0.66, 0.0)
	(front_sail.mesh as QuadMesh).size = Vector2(4.05, 3.15)
	front_sail.position = Vector3(0.0, 4.10, -4.16)
	front_sail.rotation_degrees.y = 180.0
	_configure_sail_material(front_sail)
	voilure.add_child(front_sail)

	var flag := _part("PavillonQuinet", QuadMesh.new(), Color("76242a"), 0.64, 0.04)
	(flag.mesh as QuadMesh).size = Vector2(2.25, 1.10)
	flag.position = Vector3(1.05, 10.65, -1.08)
	flag.rotation_degrees.y = 180.0
	_configure_sail_material(flag)
	voilure.add_child(flag)

	var emblem := _part("EmblèmeQuinet", CylinderMesh.new(), Color("d4a33b"), 0.40, 0.16)
	var emblem_mesh := emblem.mesh as CylinderMesh
	emblem_mesh.top_radius = 0.62
	emblem_mesh.bottom_radius = 0.62
	emblem_mesh.height = 0.045
	emblem.position = Vector3(0.0, 5.38, -1.205)
	emblem.rotation_degrees.x = 90.0
	voilure.add_child(emblem)

static func _build_mast(root: Node3D, node_name: String, position: Vector3, height: float, radius: float) -> void:
	var mast := _part(node_name, CylinderMesh.new(), Color("55321e"), 0.84, 0.0)
	var mesh := mast.mesh as CylinderMesh
	mesh.top_radius = radius * 0.72
	mesh.bottom_radius = radius
	mesh.height = height
	mast.position = position
	root.add_child(mast)

static func _build_yard(root: Node3D, node_name: String, position: Vector3, length: float) -> void:
	var yard := _part(node_name, CylinderMesh.new(), Color("4e2d1b"), 0.84, 0.0)
	var mesh := yard.mesh as CylinderMesh
	mesh.top_radius = 0.085
	mesh.bottom_radius = 0.095
	mesh.height = length
	yard.position = position
	yard.rotation_degrees.z = 90.0
	root.add_child(yard)

static func _build_striped_sail(root: Node3D, position: Vector3, size: Vector2, stripe_count: int) -> void:
	var stripe_width := size.x / float(stripe_count)
	for stripe_index in range(stripe_count):
		var color := Color("a52f31") if stripe_index % 2 == 0 else Color("efe3c9")
		var stripe := _part("BandeVoile_%d" % stripe_index, QuadMesh.new(), color, 0.64, 0.0)
		(stripe.mesh as QuadMesh).size = Vector2(stripe_width + 0.025, size.y)
		stripe.position = position + Vector3(-size.x * 0.5 + stripe_width * (float(stripe_index) + 0.5), 0.0, -0.01)
		stripe.rotation_degrees.y = 180.0
		_configure_sail_material(stripe)
		root.add_child(stripe)

static func _configure_sail_material(part: MeshInstance3D) -> void:
	var material := part.material_override as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _build_helm(boat: Node3D) -> void:
	var station := Node3D.new()
	station.name = "PosteDePilotage"
	station.position = Vector3(0.0, 0.0, 1.28)
	boat.add_child(station)

	var pedestal := _part("PiedGouvernail", BoxMesh.new(), Color("56301f"), 0.86, 0.04)
	(pedestal.mesh as BoxMesh).size = Vector3(0.72, 1.42, 0.72)
	pedestal.position = Vector3(0.0, 1.76, 0.20)
	station.add_child(pedestal)

	var helm := Node3D.new()
	helm.name = "Gouvernail3D"
	helm.position = Vector3(0.0, 2.38, -0.18)
	station.add_child(helm)

	var rim := _part("Jante", TorusMesh.new(), Color("7b4729"), 0.68, 0.05)
	var rim_mesh := rim.mesh as TorusMesh
	rim_mesh.inner_radius = 0.68
	rim_mesh.outer_radius = 0.90
	rim_mesh.rings = 28
	rim_mesh.ring_segments = 20
	rim.rotation_degrees.x = 90.0
	helm.add_child(rim)

	var hub := _part("Moyeu", CylinderMesh.new(), Color("c68a42"), 0.46, 0.18)
	var hub_mesh := hub.mesh as CylinderMesh
	hub_mesh.top_radius = 0.22
	hub_mesh.bottom_radius = 0.22
	hub_mesh.height = 0.34
	hub.rotation_degrees.x = 90.0
	helm.add_child(hub)

	for spoke_index in range(8):
		var angle := TAU * float(spoke_index) / 8.0
		var spoke := _part("Rayon", CylinderMesh.new(), Color("a76838"), 0.72, 0.02)
		var spoke_mesh := spoke.mesh as CylinderMesh
		spoke_mesh.top_radius = 0.052
		spoke_mesh.bottom_radius = 0.068
		spoke_mesh.height = 1.88
		spoke.position = Vector3(cos(angle) * 0.47, sin(angle) * 0.47, 0.0)
		spoke.rotation_degrees.z = rad_to_deg(angle) - 90.0
		helm.add_child(spoke)

static func _build_rudder(boat: Node3D) -> void:
	var rudder := Node3D.new()
	rudder.name = "GouvernailArrière"
	rudder.position = Vector3(0.0, -0.34, 5.75)
	boat.add_child(rudder)

	var blade := _part("Pale", BoxMesh.new(), Color("3b2016"), 0.92, 0.0)
	(blade.mesh as BoxMesh).size = Vector3(1.28, 1.85, 0.22)
	blade.position.y = -0.52
	rudder.add_child(blade)

	var shaft := _part("Axe", CylinderMesh.new(), Color("6a4128"), 0.84, 0.02)
	var shaft_mesh := shaft.mesh as CylinderMesh
	shaft_mesh.top_radius = 0.10
	shaft_mesh.bottom_radius = 0.12
	shaft_mesh.height = 2.4
	shaft.position.y = 0.32
	rudder.add_child(shaft)

static func _build_figurehead(boat: Node3D) -> void:
	var figure := Node3D.new()
	figure.name = "FigureDeProue"
	figure.position = Vector3(0.0, 0.72, -7.08)
	boat.add_child(figure)

	var neck := _part("Cou", CylinderMesh.new(), Color("e5ded2"), 0.65, 0.02)
	var neck_mesh := neck.mesh as CylinderMesh
	neck_mesh.top_radius = 0.27
	neck_mesh.bottom_radius = 0.38
	neck_mesh.height = 2.1
	neck.rotation_degrees.x = -24.0
	figure.add_child(neck)

	var head := _part("TêteBélier", SphereMesh.new(), Color("eee8dd"), 0.58, 0.02)
	var head_mesh := head.mesh as SphereMesh
	head_mesh.radius = 0.62
	head_mesh.height = 0.90
	head.position = Vector3(0.0, 1.20, -0.48)
	head.scale = Vector3(0.94, 0.74, 1.30)
	figure.add_child(head)

	var muzzle := _part("Museau", SphereMesh.new(), Color("f3eee5"), 0.62, 0.0)
	var muzzle_mesh := muzzle.mesh as SphereMesh
	muzzle_mesh.radius = 0.33
	muzzle_mesh.height = 0.42
	muzzle.position = Vector3(0.0, 1.08, -1.02)
	muzzle.scale = Vector3(1.25, 0.72, 0.88)
	figure.add_child(muzzle)

	for side in [-1.0, 1.0]:
		var horn := _part("Corne", TorusMesh.new(), Color("8a765c"), 0.72, 0.0)
		var horn_mesh := horn.mesh as TorusMesh
		horn_mesh.inner_radius = 0.22
		horn_mesh.outer_radius = 0.38
		horn.position = Vector3(side * 0.52, 1.30, -0.34)
		horn.rotation_degrees = Vector3(90.0, 0.0, 90.0)
		figure.add_child(horn)

static func _build_cannons(boat: Node3D) -> void:
	for side in [-1.0, 1.0]:
		for index in range(4):
			var cannon := _part("Canon", CylinderMesh.new(), Color("20252b"), 0.40, 0.72)
			var mesh := cannon.mesh as CylinderMesh
			mesh.top_radius = 0.17
			mesh.bottom_radius = 0.23
			mesh.height = 1.25
			cannon.position = Vector3(side * 2.33, 0.72, -2.85 + float(index) * 1.75)
			cannon.rotation_degrees.z = 90.0
			boat.add_child(cannon)

static func _build_lanterns(boat: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var lantern := _part("Lanterne", SphereMesh.new(), Color("ffc85a"), 0.30, 0.05)
		var mesh := lantern.mesh as SphereMesh
		mesh.radius = 0.20
		mesh.height = 0.36
		lantern.position = Vector3(side * 1.55, 3.05, 4.85)
		var material := lantern.material_override as StandardMaterial3D
		material.emission_enabled = true
		material.emission = Color("ffb532")
		material.emission_energy_multiplier = 3.0
		boat.add_child(lantern)

static func _build_wake(boat: Node3D) -> void:
	var wake := GPUParticles3D.new()
	wake.name = "Sillage"
	wake.amount = 80
	wake.lifetime = 1.0
	wake.emitting = false
	wake.visibility_aabb = AABB(Vector3(-5, -2, -8), Vector3(10, 5, 18))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(1.55, 0.08, 0.55)
	process.direction = Vector3(0, 0.18, 1)
	process.spread = 22.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.0
	process.gravity = Vector3(0, -0.7, 0)
	process.color = Color(0.75, 0.94, 1.0, 0.82)
	wake.process_material = process
	var foam := QuadMesh.new()
	foam.size = Vector2(0.22, 0.22)
	var foam_material := StandardMaterial3D.new()
	foam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_material.albedo_color = Color(0.82, 0.96, 1.0, 0.84)
	foam_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	foam.material = foam_material
	wake.draw_pass_1 = foam
	wake.position = Vector3(0, -0.12, 5.55)
	boat.add_child(wake)

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
