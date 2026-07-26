class_name WorldVisualsV4
extends WorldVisuals

# Les bâtiments, terrains, animaux, quais et collisions restent de vrais
# objets 3D. Seuls les personnages importants utilisent les atlas 2.5D.
const GROUND_COLORS_V4 := [
	Color("8a6f43"), Color("4d6638"), Color("e8f3f8"), Color("c9954f"), Color("403435"), Color("4f5d66"),
	Color("d99cc4"), Color("282126"), Color("e8f5ff")
]
const GROUND_DETAIL_COLORS_V4 := [
	Color("516c35"), Color("2e7b3d"), Color("f8fbfc"), Color("dfb66d"), Color("6f4134"), Color("718491"),
	Color("f3d38b"), Color("5b3029"), Color("b9dcf5")
]
const SHORE_COLORS_V4 := [
	Color("c9a66a"), Color("b89a5b"), Color("dcebf0"), Color("e4c080"), Color("5b433d"), Color("71828a"),
	Color("f1c0d3"), Color("3b3032"), Color("d8f1ff")
]
const ROCK_COLORS_V4 := [
	Color("594838"), Color("38513a"), Color("9fb4bc"), Color("845f3d"), Color("241f20"), Color("354652"),
	Color("8b5f72"), Color("1a171a"), Color("7fa9c6")
]
const WEATHER_V4 := ["soleil", "pluie", "neige", "soleil", "cendres", "tempête", "soleil", "cendres", "soleil"]

func weather_for_zone(zone_index: int) -> String:
	return String(WEATHER_V4[clampi(zone_index, 0, WEATHER_V4.size() - 1)])

func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "OcéanContinuNeufÎles"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2700, 1500)
	plane.subdivide_width = 260
	plane.subdivide_depth = 150
	ocean.mesh = plane
	ocean.position = Vector3(930, 0, 20)
	ocean_material = ShaderMaterial.new()
	ocean_material.shader = load("res://shaders/ocean.gdshader")
	ocean.material_override = ocean_material
	add_child(ocean)

func _build_islands() -> void:
	for zone_index in range(zones.size()):
		var zone: Dictionary = zones[zone_index]
		var center: Vector3 = zone["center"]
		var radius := float(zone["radius"])
		var root := Node3D.new()
		root.name = "Zone_%d" % zone_index
		root.position = center
		root.set_meta("zone_index", zone_index)
		add_child(root)

		var ground := MeshInstance3D.new()
		ground.name = "TerrainRelief3D"
		var ground_mesh := _create_island_mesh(zone_index, radius)
		ground.mesh = ground_mesh
		ground.material_override = _terrain_material(zone_index)
		root.add_child(ground)

		var floor_body := StaticBody3D.new()
		floor_body.name = "CollisionTerrain"
		var floor_collision := CollisionShape3D.new()
		floor_collision.shape = ground_mesh.create_trimesh_shape()
		floor_body.add_child(floor_collision)
		root.add_child(floor_body)

		_build_shore_foam(root, radius)
		_build_zone_props(root, zone_index, radius)
		_build_animals(root, zone_index, radius)
		_build_landmark(root, zone_index, radius)
		_build_dock(root, zone_index, radius, Vector3(zone["dock_dir"]))

		if zone_index == 8:
			# Le joueur pilote réellement son bateau jusqu’au quai situé sous
			# l’île céleste. L’ascenseur d’eau l’amène ensuite au quai supérieur.
			var sea_gate := Node3D.new()
			sea_gate.name = "QuaiMaritimeRoyaumeCéleste"
			sea_gate.position = Vector3(center.x, 0.0, center.z)
			add_child(sea_gate)
			_build_dock(sea_gate, zone_index, radius, Vector3(zone["dock_dir"]))
			_build_sky_sea_gate(sea_gate, radius, Vector3(zone["dock_dir"]))
			_build_destination_marker(sea_gate, zone_index, radius, Vector3(zone["dock_dir"]))
		else:
			_build_destination_marker(root, zone_index, radius, Vector3(zone["dock_dir"]))

func _terrain_height(zone_index: int, x: float, z: float, island_radius: float) -> float:
	if zone_index < 6:
		return super._terrain_height(zone_index, x, z, island_radius)
	var ratio := clampf(Vector2(x, z).length() / maxf(island_radius, 0.01), 0.0, 1.08)
	var seed := float(zone_index) * 1.73
	var broad := sin(x * 0.050 + seed) * cos(z * 0.044 - seed * 0.7)
	var crossed := sin((x + z) * 0.027 + seed * 2.1) * 0.56
	var detail := cos(x * 0.113 - z * 0.086 + seed) * 0.24
	var relief_amount := 1.75 if zone_index == 6 else 4.2 if zone_index == 7 else 3.1
	var interior := pow(clampf(1.0 - ratio, 0.0, 1.0), 1.12)
	var relief := maxf(0.0, broad * 0.58 + crossed * 0.30 + detail * 0.12 + 0.42)
	var plateau := 1.62 + relief * relief_amount * interior
	if zone_index == 8:
		plateau += smoothstep(0.70, 0.0, ratio) * 2.6
	var shore_blend := smoothstep(0.76, 1.0, ratio)
	return lerpf(plateau, 0.48, shore_blend)

func _terrain_material(zone_index: int) -> ShaderMaterial:
	var resolved := clampi(zone_index, 0, GROUND_COLORS_V4.size() - 1)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/terrain_realistic.gdshader")
	material.set_shader_parameter("ground_color", GROUND_COLORS_V4[resolved])
	material.set_shader_parameter("ground_detail", GROUND_DETAIL_COLORS_V4[resolved])
	material.set_shader_parameter("shore_color", SHORE_COLORS_V4[resolved])
	material.set_shader_parameter("rock_color", ROCK_COLORS_V4[resolved])
	material.set_shader_parameter("wetness", 0.32 if resolved in [0, 1, 2, 8] else 0.10)
	return material

func _build_zone_props(root: Node3D, zone_index: int, island_radius: float) -> void:
	if zone_index < 6:
		super._build_zone_props(root, zone_index, island_radius)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + zone_index * 997
	var prop_count := 72 if zone_index == 6 else 82 if zone_index == 7 else 58
	for i in range(prop_count):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(island_radius * 0.30, island_radius * 0.82)
		var position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		position.y = _terrain_height(zone_index, position.x, position.z, island_radius) + 0.03
		match zone_index:
			6:
				if i % 5 == 0:
					_build_candy_tree(root, position, rng.randf_range(0.72, 1.26), i)
				elif i % 3 == 0:
					_build_cupcake_house(root, position, rng.randf_range(0.68, 1.05), i)
				else:
					_build_rock(root, position, Color("b8738c"), rng.randf_range(0.55, 1.25))
			7:
				_build_rock(root, position, Color("211b1e"), rng.randf_range(0.85, 2.35))
				if i % 9 == 0:
					_add_sphere(root, "BraiseVolcanique", position + Vector3(0, 0.42, 0), 0.34, Color("ff4a17"), true)
			8:
				if i % 4 == 0:
					_add_cylinder(root, "ColonneCéleste", position + Vector3(0, 2.7, 0), 0.42, 0.58, 5.4, Color("e6f2fb"))
				else:
					_add_sphere(root, "CristalNuage", position + Vector3(0, 0.8, 0), rng.randf_range(0.45, 1.1), Color(0.76, 0.91, 1.0, 0.82), true)

func _build_animals(root: Node3D, zone_index: int, island_radius: float) -> void:
	if zone_index < 6:
		super._build_animals(root, zone_index, island_radius)
		return
	var species_by_zone := [
		["singe", "cerf"],
		["lézard", "aigle"],
		["aigle", "mouette"]
	]
	var colors_by_zone := [
		[Color("a05c73"), Color("f0c56e")],
		[Color("3a302d"), Color("6f6178")],
		[Color("e8f4ff"), Color("c4d9e8")]
	]
	var local_zone := zone_index - 6
	var rng := RandomNumberGenerator.new()
	rng.seed = 24820 + zone_index * 431
	for animal_index in range(10):
		var species_index := animal_index % 2
		var species := String(species_by_zone[local_zone][species_index])
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(island_radius * 0.20, island_radius * 0.70)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var flying := species in ["mouette", "aigle"]
		var y := _terrain_height(zone_index, x, z, island_radius) + (7.5 if flying else 0.05)
		var animal := QuinetAmbientAnimal.new()
		animal.name = "%s_%02d" % [species.capitalize(), animal_index]
		root.add_child(animal)
		animal.configure(species, Color(colors_by_zone[local_zone][species_index]), Vector3(x, y, z), 90000 + zone_index * 100 + animal_index)

func _build_landmark(root: Node3D, zone_index: int, island_radius: float) -> void:
	match zone_index:
		6:
			_build_cake_city(root, island_radius)
		7:
			_build_skull_citadel(root, island_radius)
		8:
			_build_sky_palace(root, island_radius)
		_:
			super._build_landmark(root, zone_index, island_radius)

func _build_cake_city(root: Node3D, island_radius: float) -> void:
	# Château-pièce montée entièrement en volumes 3D.
	var tiers := [Vector3(46, 6, 38), Vector3(36, 6, 30), Vector3(27, 6, 23), Vector3(18, 6, 16)]
	for level in range(tiers.size()):
		var y := 4.0 + float(level) * 6.0
		var color := Color("f6b9cf") if level % 2 == 0 else Color("f2d78d")
		_add_box(root, "GâteauRoyal", Vector3(0, y, 4), tiers[level], color)
		for side in [-1.0, 1.0]:
			_add_sphere(root, "CrèmeRoyale", Vector3(side * tiers[level].x * 0.38, y + 3.0, 4), 1.25, Color("fff1e7"), true)
	_add_cylinder(root, "TourSucréeCentrale", Vector3(0, 32.0, 4), 5.2, 6.0, 17.0, Color("f9e4bc"))
	_add_cone(root, "ToitCaramel", Vector3(0, 43.0, 4), 7.2, 7.0, Color("c36e48"))
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var p := Vector3(cos(angle) * 34.0, 9.0, sin(angle) * 27.0 + 4.0)
		_add_cylinder(root, "TourBonbon", p, 2.4, 3.0, 13.0, Color("f1a8c4") if index % 2 == 0 else Color("8fc9e8"))
		_add_cone(root, "ToitBonbon", p + Vector3(0, 8.0, 0), 3.8, 5.5, Color("d84d6f"))
	for index in range(6):
		var river_angle := -1.2 + float(index) * 0.48
		var p := Vector3(cos(river_angle) * 44.0, 2.1, sin(river_angle) * 44.0)
		_add_box(root, "RivièreCaramel", p, Vector3(4.2, 0.20, 35.0), Color("e69842"), true, river_angle)

func _build_skull_citadel(root: Node3D, island_radius: float) -> void:
	# Forteresse-crâne 3D inspirée de l’asset fourni, entourée de magma.
	_add_ellipsoid(root, "CrâneForteresse", Vector3(0, 25.0, 3), Vector3(31, 24, 26), Color("655f5a"), true)
	_add_ellipsoid(root, "OrbiteGauche", Vector3(-11.0, 28.0, -20.5), Vector3(7.2, 6.0, 4.0), Color("08080a"), false)
	_add_ellipsoid(root, "OrbiteDroite", Vector3(11.0, 28.0, -20.5), Vector3(7.2, 6.0, 4.0), Color("08080a"), false)
	_add_sphere(root, "FlammeŒilGauche", Vector3(-11.0, 28.0, -24.0), 1.35, Color("ff5a18"), true)
	_add_sphere(root, "FlammeŒilDroite", Vector3(11.0, 28.0, -24.0), 1.35, Color("ff5a18"), true)
	_add_box(root, "GueuleDuCrâne", Vector3(0, 16.0, -22.0), Vector3(17, 10, 8), Color("111014"))
	for tooth in range(8):
		var x := -7.0 + float(tooth) * 2.0
		_add_cone(root, "DentCrâne", Vector3(x, 17.0, -27.0), 0.85, 4.2, Color("b9b1a3"))
	for side in [-1.0, 1.0]:
		_add_rotated_cone(root, "CorneCrâne", Vector3(side * 26.0, 42.0, 1.0), 7.0, 34.0, Color("4f4946"), Vector3(0, 0, side * -52.0))
	_add_box(root, "CitadelleSommet", Vector3(0, 52.0, 4.0), Vector3(38, 15, 31), Color("25232a"))
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			_add_cylinder(root, "TourCrâne", Vector3(side_x * 20.0, 56.0, 4.0 + side_z * 15.0), 3.7, 4.5, 20.0, Color("302b31"))
			_add_cone(root, "ToitCrâne", Vector3(side_x * 20.0, 68.0, 4.0 + side_z * 15.0), 5.0, 6.0, Color("17151a"))
	var magma := MeshInstance3D.new()
	magma.name = "AnneauDeMagma"
	var ring := TorusMesh.new()
	ring.inner_radius = island_radius * 0.82
	ring.outer_radius = island_radius * 0.98
	ring.rings = 96
	ring.ring_segments = 12
	magma.mesh = ring
	magma.position.y = 0.72
	magma.material_override = _glow_material(Color(1.0, 0.16, 0.02, 0.94), 6.5)
	root.add_child(magma)
	for index in range(7):
		var angle := -1.45 + float(index) * 0.46
		var p := Vector3(cos(angle) * 48.0, 2.15, sin(angle) * 48.0)
		_add_box(root, "FailleMagma", p, Vector3(5.0, 0.22, 40.0), Color("ff4712"), true, angle)

func _build_sky_palace(root: Node3D, island_radius: float) -> void:
	# Masse rocheuse suspendue et palais blanc/or entièrement en 3D.
	for index in range(9):
		var angle := TAU * float(index) / 9.0
		var p := Vector3(cos(angle) * 38.0, -18.0 - float(index % 3) * 3.0, sin(angle) * 32.0)
		_add_rotated_cone(root, "RocheFlottante", p, 11.0 + float(index % 2) * 3.0, 38.0, Color("557487"), Vector3(180.0, 0, 0))
	for level in range(5):
		_add_box(root, "TerrasseCéleste", Vector3(0, 4.0 + level * 4.0, 5.0), Vector3(68.0 - level * 9.0, 2.5, 50.0 - level * 6.0), Color("eaf4fb"))
	_add_cylinder(root, "DômeCentral", Vector3(0, 33.0, 5.0), 10.0, 13.0, 24.0, Color("f3f8fb"))
	_add_ellipsoid(root, "ToitDoréCentral", Vector3(0, 47.0, 5.0), Vector3(14, 7, 14), Color("e4bd58"), true)
	for index in range(10):
		var angle := TAU * float(index) / 10.0
		var p := Vector3(cos(angle) * 34.0, 25.0, sin(angle) * 27.0 + 5.0)
		_add_cylinder(root, "TourCéleste", p, 2.8, 3.6, 25.0, Color("edf7ff"))
		_add_ellipsoid(root, "DômeDoré", p + Vector3(0, 14.0, 0), Vector3(4.2, 2.5, 4.2), Color("d9af42"), true)
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var p := Vector3(cos(angle) * 55.0, -24.0, sin(angle) * 45.0)
		_add_cylinder(root, "ColonneOcéanVersCiel", p, 2.6, 4.8, 58.0, Color(0.30, 0.74, 1.0, 0.55), true, false)
	for index in range(14):
		var angle := TAU * float(index) / 14.0
		var p := Vector3(cos(angle) * 62.0, -2.0 + sin(angle * 3.0) * 2.0, sin(angle) * 49.0)
		_add_sphere(root, "NuagePortant", p, 6.5 + float(index % 3), Color(0.86, 0.95, 1.0, 0.44), true)

func _build_sky_sea_gate(root: Node3D, island_radius: float, raw_direction: Vector3) -> void:
	var direction := raw_direction.normalized()
	var lift_position := direction * (island_radius - 13.0)
	_add_cylinder(root, "AscenseurDEau", lift_position + Vector3(0, 25.0, 0), 3.8, 6.0, 50.0, Color(0.35, 0.80, 1.0, 0.52), true, false)
	for side in [-1.0, 1.0]:
		var tangent := Vector3(direction.z, 0, -direction.x) * side * 8.0
		_add_cylinder(root, "PilierDuPortail", lift_position + tangent + Vector3(0, 8.0, 0), 1.5, 2.2, 16.0, Color("dfeefa"))
		_add_sphere(root, "FlammeCéleste", lift_position + tangent + Vector3(0, 17.0, 0), 1.2, Color("72d9ff"), true)

func _build_candy_tree(root: Node3D, position: Vector3, scale_value: float, variant: int) -> void:
	_add_cylinder(root, "TroncSucre", position + Vector3(0, 2.7 * scale_value, 0), 0.35 * scale_value, 0.48 * scale_value, 5.4 * scale_value, Color("f1d3b5"))
	var crown_color := Color("f36b9c") if variant % 3 == 0 else Color("79c8ef") if variant % 3 == 1 else Color("f5d05d")
	_add_sphere(root, "CouronneBonbon", position + Vector3(0, 6.4 * scale_value, 0), 2.3 * scale_value, crown_color, true)

func _build_cupcake_house(root: Node3D, position: Vector3, scale_value: float, variant: int) -> void:
	_add_cylinder(root, "MaisonCupcake", position + Vector3(0, 1.7 * scale_value, 0), 2.2 * scale_value, 2.8 * scale_value, 3.4 * scale_value, Color("d8a06d"))
	_add_cone(root, "CrèmeCupcake", position + Vector3(0, 4.5 * scale_value, 0), 3.0 * scale_value, 3.8 * scale_value, Color("f6b6d0") if variant % 2 == 0 else Color("fff0da"))

func _add_ellipsoid(root: Node3D, node_name: String, position: Vector3, scale_value: Vector3, color: Color, collision_enabled: bool) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 28
	mesh.rings = 16
	node.mesh = mesh
	node.position = position
	node.scale = scale_value
	node.material_override = _material(color, 0.80)
	root.add_child(node)
	if collision_enabled:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Collision"
		collision.position = position
		var shape := SphereShape3D.new()
		shape.radius = maxf(scale_value.x, maxf(scale_value.y, scale_value.z)) * 0.72
		collision.shape = shape
		_decoration_collision_body(root).add_child(collision)

func _add_rotated_cone(root: Node3D, node_name: String, position: Vector3, radius: float, height: float, color: Color, rotation_degrees_value: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 28
	node.mesh = mesh
	node.position = position
	node.rotation_degrees = rotation_degrees_value
	node.material_override = _material(color, 0.84)
	root.add_child(node)
