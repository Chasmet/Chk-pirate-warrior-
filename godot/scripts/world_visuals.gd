class_name WorldVisuals
extends Node3D

signal weather_changed(label: String)

const GROUND_COLORS := [Color("8a6f43"), Color("4d6638"), Color("e8f3f8"), Color("c9954f"), Color("403435"), Color("4f5d66")]
const WEATHER := ["soleil", "pluie", "neige", "soleil", "cendres", "tempête"]

var environment: Environment
var sun: DirectionalLight3D
var particles: GPUParticles3D
var particle_material: ParticleProcessMaterial
var foliage_material_cache: Dictionary = {}
var day_time: float = 0.22
var zones: Array = []
var unlocked_zones: Array = [0]
var destination_markers: Array[Node3D] = []

func build(zone_definitions: Array, unlocked: Array = [0]) -> void:
	zones = zone_definitions
	unlocked_zones = unlocked.duplicate()
	_build_environment()
	_build_ocean()
	_build_islands()
	_build_sea_routes()
	_build_weather()

func set_destination(zone_index: int) -> void:
	for index in range(destination_markers.size()):
		var marker := destination_markers[index]
		if not is_instance_valid(marker):
			continue
		var beam := marker.get_node_or_null("Faisceau") as MeshInstance3D
		var label := marker.get_node_or_null("NomÎle") as Label3D
		var selected := index == zone_index
		if beam != null:
			beam.scale = Vector3(1.8, 1.0, 1.8) if selected else Vector3.ONE
			var material := beam.material_override as StandardMaterial3D
			if material != null:
				material.albedo_color = Color(1.0, 0.73, 0.18, 0.46 if selected else 0.18)
				material.emission_energy_multiplier = 6.5 if selected else 2.2
		if label != null:
			label.font_size = 46 if selected else 34
			label.modulate = Color("ffe08a") if selected else Color("dbe8ee")

func set_unlocked_zones(value: Array) -> void:
	unlocked_zones = value.duplicate()
	for index in range(destination_markers.size()):
		var marker := destination_markers[index]
		var status := marker.get_node_or_null("Statut") as Label3D
		if status != null:
			status.text = "DÉBLOQUÉE" if unlocked_zones.has(index) else "À DÉCOUVRIR"
			status.modulate = Color("71e39b") if unlocked_zones.has(index) else Color("ffbd58")

func update_world(delta: float, player_position: Vector3) -> void:
	day_time = fmod(day_time + delta / 260.0, 1.0)
	var daylight: float = clampf(sin(day_time * PI), 0.05, 1.0)
	sun.rotation_degrees.x = day_time * 360.0 - 100.0
	sun.light_energy = 0.18 + daylight * 1.55
	environment.ambient_light_energy = 0.22 + daylight * 0.62
	particles.global_position = player_position + Vector3(0, 12, 0)

func set_zone_weather(zone_index: int) -> void:
	var weather: String = String(WEATHER[clampi(zone_index, 0, WEATHER.size() - 1)])
	var quad := particles.draw_pass_1 as QuadMesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particles.emitting = true
	match weather:
		"pluie":
			particles.amount = 1300
			particle_material.direction = Vector3(-0.2, -1, 0.05)
			particle_material.initial_velocity_min = 14.0
			particle_material.initial_velocity_max = 22.0
			quad.size = Vector2(0.025, 0.75)
			material.albedo_color = Color(0.65, 0.84, 1.0, 0.7)
			environment.fog_density = 0.009
		"neige":
			particles.amount = 850
			particle_material.direction = Vector3(0.15, -1, 0.08)
			particle_material.initial_velocity_min = 2.0
			particle_material.initial_velocity_max = 5.0
			quad.size = Vector2(0.12, 0.12)
			material.albedo_color = Color(1, 1, 1, 0.92)
			environment.fog_density = 0.014
		"tempête":
			particles.amount = 1700
			particle_material.direction = Vector3(-0.58, -1, 0.12)
			particle_material.initial_velocity_min = 20.0
			particle_material.initial_velocity_max = 30.0
			quad.size = Vector2(0.03, 0.92)
			material.albedo_color = Color(0.55, 0.72, 0.9, 0.76)
			environment.fog_density = 0.025
		"cendres":
			particles.amount = 650
			particle_material.direction = Vector3(0.1, -0.3, 0.05)
			particle_material.initial_velocity_min = 1.0
			particle_material.initial_velocity_max = 3.0
			quad.size = Vector2(0.10, 0.10)
			material.albedo_color = Color(0.25, 0.19, 0.17, 0.88)
			environment.fog_density = 0.018
		_:
			particles.amount = 1
			particles.emitting = false
			environment.fog_density = 0.003
	quad.material = material
	if particles.emitting:
		particles.restart()
	weather_changed.emit(weather.capitalize())

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("1e6da6")
	sky_material.sky_horizon_color = Color("8bd6ee")
	sky_material.ground_bottom_color = Color("07131c")
	sky_material.ground_horizon_color = Color("5f7f78")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_density = 0.003
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("fff1cf")
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	sun.rotation_degrees = Vector3(-48, -28, 0)
	add_child(sun)

func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1550, 1020)
	plane.subdivide_width = 190
	plane.subdivide_depth = 120
	ocean.mesh = plane
	ocean.position = Vector3(455, 0, 35)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/ocean.gdshader")
	ocean.material_override = shader_material
	add_child(ocean)

func _build_islands() -> void:
	for zone_index in range(zones.size()):
		var zone: Dictionary = zones[zone_index]
		var center: Vector3 = zone["center"]
		var radius := float(zone["radius"])
		var root := Node3D.new()
		root.name = "Zone_%d" % zone_index
		root.position = center
		add_child(root)
		var ground := MeshInstance3D.new()
		var ground_mesh := CylinderMesh.new()
		ground_mesh.top_radius = radius
		ground_mesh.bottom_radius = radius + 8.0
		ground_mesh.height = 3.0
		ground_mesh.radial_segments = 64
		ground.mesh = ground_mesh
		ground.position.y = 0.0
		ground.material_override = _material(GROUND_COLORS[zone_index], 0.92)
		root.add_child(ground)
		var floor_body := StaticBody3D.new()
		var floor_collision := CollisionShape3D.new()
		var floor_shape := CylinderShape3D.new()
		floor_shape.radius = radius
		floor_shape.height = 3.0
		floor_collision.shape = floor_shape
		floor_body.add_child(floor_collision)
		root.add_child(floor_body)
		_build_zone_props(root, zone_index, radius)
		_build_landmark(root, zone_index, radius)
		_build_dock(root, zone_index, radius, Vector3(zone["dock_dir"]))
		_build_destination_marker(root, zone_index, radius, Vector3(zone["dock_dir"]))

func _build_zone_props(root: Node3D, zone_index: int, island_radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + zone_index * 997
	for i in range(62):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(island_radius * 0.30, island_radius * 0.82)
		var position := Vector3(cos(angle) * radius, 1.7, sin(angle) * radius)
		match zone_index:
			0, 1:
				_build_tree(root, position, rng.randf_range(0.8, 1.45), zone_index == 0)
			2:
				_build_snow_pine(root, position, rng.randf_range(0.8, 1.5))
			3:
				_build_rock(root, position, Color("9c6e40"), rng.randf_range(0.8, 1.8))
			4:
				_build_rock(root, position, Color("30292b"), rng.randf_range(0.9, 2.2))
			_:
				_build_rock(root, position, Color("4c5960"), rng.randf_range(0.8, 1.8))
	if zone_index == 0 or zone_index == 1:
		_build_grass(root, rng, island_radius)

func _build_tree(root: Node3D, position: Vector3, scale_value: float, palm: bool) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.32 * scale_value
	trunk_mesh.bottom_radius = 0.48 * scale_value
	trunk_mesh.height = 7.0 * scale_value
	trunk.mesh = trunk_mesh
	trunk.position = position + Vector3(0, 3.5 * scale_value, 0)
	trunk.material_override = _material(Color("6a442c"), 0.9)
	root.add_child(trunk)
	var crown := MeshInstance3D.new()
	if palm:
		var sphere := SphereMesh.new()
		sphere.radius = 2.5 * scale_value
		sphere.height = 2.4 * scale_value
		crown.mesh = sphere
	else:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 3.0 * scale_value
		cone.height = 6.5 * scale_value
		crown.mesh = cone
	crown.position = position + Vector3(0, 7.2 * scale_value, 0)
	crown.material_override = _foliage_material(Color("25733d"), 0.26 if palm else 0.18)
	root.add_child(crown)
	var trunk_body := StaticBody3D.new()
	trunk_body.position = position + Vector3(0, 3.5 * scale_value, 0)
	var trunk_collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.48 * scale_value
	trunk_shape.height = 7.0 * scale_value
	trunk_collision.shape = trunk_shape
	trunk_body.add_child(trunk_collision)
	root.add_child(trunk_body)

func _build_snow_pine(root: Node3D, position: Vector3, scale_value: float) -> void:
	_build_tree(root, position, scale_value, false)
	var snow := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.65 * scale_value
	cone.height = 4.5 * scale_value
	snow.mesh = cone
	snow.position = position + Vector3(0, 8.2 * scale_value, 0)
	snow.material_override = _material(Color("eaf5fb"), 0.72)
	root.add_child(snow)

func _build_rock(root: Node3D, position: Vector3, color: Color, scale_value: float) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.2 * scale_value
	mesh.height = 1.7 * scale_value
	rock.mesh = mesh
	rock.position = position
	rock.scale = Vector3(1.4, 0.7, 1.0)
	rock.rotation_degrees = Vector3(0, position.x * 3.0, 0)
	rock.material_override = _material(color, 0.96)
	root.add_child(rock)
	var rock_body := StaticBody3D.new()
	rock_body.position = position
	var rock_collision := CollisionShape3D.new()
	var rock_shape := SphereShape3D.new()
	rock_shape.radius = 0.85 * scale_value
	rock_collision.shape = rock_shape
	rock_body.add_child(rock_collision)
	root.add_child(rock_body)

func _build_grass(root: Node3D, rng: RandomNumberGenerator, island_radius: float) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 1500
	var blade := QuadMesh.new()
	blade.size = Vector2(0.18, 1.25)
	var grass_material := ShaderMaterial.new()
	grass_material.shader = load("res://shaders/grass.gdshader")
	blade.material = grass_material
	multimesh.mesh = blade
	for i in range(multimesh.instance_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = sqrt(rng.randf()) * island_radius * 0.92
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		var scale_value: float = rng.randf_range(0.65, 1.35)
		basis = basis.scaled(Vector3.ONE * scale_value)
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(cos(angle) * radius, 1.58, sin(angle) * radius)))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = 130.0
	root.add_child(instance)

func _build_landmark(root: Node3D, zone_index: int, island_radius: float) -> void:
	match zone_index:
		0:
			_add_cylinder(root, "Phare", Vector3(-island_radius * 0.34, 10.5, -island_radius * 0.24), 3.8, 3.0, 18.0, Color("efe1c2"))
			_add_cylinder(root, "ToitPhare", Vector3(-island_radius * 0.34, 20.2, -island_radius * 0.24), 4.6, 0.5, 1.6, Color("8b2428"), true)
			_add_sphere(root, "FeuPhare", Vector3(-island_radius * 0.34, 19.4, -island_radius * 0.24), 1.35, Color("ffd257"), true)
			for index in range(6):
				var angle := -0.75 + float(index) * 0.30
				var hut_position := Vector3(cos(angle), 0, sin(angle)) * island_radius * 0.42
				_add_box(root, "MaisonPort", hut_position + Vector3(0, 3.0, 0), Vector3(7.5, 5.0, 6.5), Color("6e4530"))
				_add_cone(root, "ToitPort", hut_position + Vector3(0, 6.2, 0), 5.4, 3.0, Color("8a2f2b"))
		1:
			for level in range(5):
				_add_box(root, "TempleJungle", Vector3(0, 1.8 + level * 1.35, 6.0), Vector3(34.0 - level * 4.8, 1.25, 27.0 - level * 3.5), Color("52684a"))
			_add_box(root, "PorteTemple", Vector3(0, 10.3, -1.0), Vector3(8.5, 12.0, 3.0), Color("314638"))
			for side in [-1.0, 1.0]:
				_add_cylinder(root, "TotemJungle", Vector3(side * 17.0, 6.5, 3.0), 1.4, 1.8, 10.0, Color("75603d"))
				_add_sphere(root, "ŒilTotem", Vector3(side * 17.0, 8.0, 1.7), 0.55, Color("7df18c"), true)
		2:
			_add_cone(root, "PicGivré", Vector3(4, 18.0, 8), 24.0, 34.0, Color("d5edf5"))
			for index in range(12):
				var angle := TAU * float(index) / 12.0
				var crystal_position := Vector3(cos(angle) * 27.0, 6.0 + float(index % 3) * 1.2, sin(angle) * 27.0)
				_add_cone(root, "CristalDeGlace", crystal_position, 2.2 + float(index % 2), 10.0 + float(index % 3) * 2.0, Color("76d9ef"), true)
		3:
			_add_box(root, "RuineCentrale", Vector3(0, 2.3, 0), Vector3(42, 3.0, 30), Color("b98851"))
			_add_box(root, "Obélisque", Vector3(0, 15.0, 0), Vector3(5.0, 27.0, 5.0), Color("d1a064"))
			_add_cone(root, "PointeObélisque", Vector3(0, 30.0, 0), 4.0, 5.0, Color("e4bb75"))
			for side_x in [-1.0, 1.0]:
				for side_z in [-1.0, 1.0]:
					_add_cylinder(root, "ColonneDesDunes", Vector3(side_x * 18.0, 8.0, side_z * 11.0), 1.3, 1.6, 13.0, Color("c99b63"))
		4:
			_add_cone(root, "Volcan", Vector3(3, 21.0, 10), 35.0, 40.0, Color("30282a"))
			_add_cylinder(root, "Cratère", Vector3(3, 41.3, 10), 8.5, 10.0, 1.4, Color("1a1719"))
			_add_sphere(root, "CœurDeLave", Vector3(3, 41.0, 10), 5.8, Color("ff4b18"), true)
			for index in range(5):
				var lava_angle := -1.3 + float(index) * 0.55
				var lava_position := Vector3(cos(lava_angle) * 34.0, 2.05, sin(lava_angle) * 34.0)
				_add_box(root, "RivièreDeLave", lava_position, Vector3(5.0, 0.18, 34.0), Color("ff5a1e"), true, lava_angle)
		_:
			_add_box(root, "Forteresse", Vector3(0, 9.0, 0), Vector3(54, 15, 42), Color("384854"))
			_add_box(root, "CourForteresse", Vector3(0, 16.8, 0), Vector3(42, 1.0, 30), Color("60717b"))
			for side_x in [-1.0, 1.0]:
				for side_z in [-1.0, 1.0]:
					_add_cylinder(root, "TourTempête", Vector3(side_x * 27.0, 14.0, side_z * 21.0), 5.0, 5.8, 24.0, Color("465965"))
					_add_cone(root, "ToitTempête", Vector3(side_x * 27.0, 28.0, side_z * 21.0), 6.4, 5.5, Color("263744"))
					_add_sphere(root, "Paratonnerre", Vector3(side_x * 27.0, 31.2, side_z * 21.0), 0.7, Color("82d9ff"), true)

func _build_dock(root: Node3D, zone_index: int, island_radius: float, raw_direction: Vector3) -> void:
	var direction := raw_direction.normalized()
	var yaw := atan2(direction.x, direction.z)
	for plank_index in range(9):
		var distance := island_radius - 15.0 + float(plank_index) * 4.0
		var plank_position := direction * distance + Vector3(0, 1.72, 0)
		_add_box(root, "PontDuQuai", plank_position, Vector3(6.8, 0.34, 3.7), Color("9a6639"), false, yaw)
		for side in [-1.0, 1.0]:
			var side_vector: Vector3 = Vector3(direction.z, 0, -direction.x) * side * 3.15
			_add_cylinder(root, "PoteauDuQuai", plank_position + side_vector + Vector3(0, -0.75, 0), 0.18, 0.24, 3.2, Color("4f301f"))
	var sign_position := direction * (island_radius - 22.0)
	_add_cylinder(root, "PanneauQuai", sign_position + Vector3(0, 3.2, 0), 0.20, 0.25, 4.5, Color("593720"))
	var sign := Label3D.new()
	sign.text = "QUAI • BATEAU"
	sign.font_size = 42
	sign.outline_size = 9
	sign.modulate = Color("ffe08a")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = sign_position + Vector3(0, 5.5, 0)
	root.add_child(sign)

func _build_destination_marker(root: Node3D, zone_index: int, island_radius: float, raw_direction: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "BaliseDestination_%d" % zone_index
	marker.position = raw_direction.normalized() * (island_radius + 18.0)
	root.add_child(marker)
	var beam := MeshInstance3D.new()
	beam.name = "Faisceau"
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.65
	beam_mesh.bottom_radius = 2.4
	beam_mesh.height = 28.0
	beam.mesh = beam_mesh
	beam.position.y = 14.0
	beam.material_override = _glow_material(Color(1.0, 0.73, 0.18, 0.18), 2.2)
	marker.add_child(beam)
	var label := Label3D.new()
	label.name = "NomÎle"
	label.text = String(zones[zone_index]["name"]).to_upper()
	label.font_size = 34
	label.outline_size = 10
	label.modulate = Color("dbe8ee")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 11.0
	marker.add_child(label)
	var status := Label3D.new()
	status.name = "Statut"
	status.text = "DÉBLOQUÉE" if unlocked_zones.has(zone_index) else "À DÉCOUVRIR"
	status.font_size = 25
	status.outline_size = 8
	status.modulate = Color("71e39b") if unlocked_zones.has(zone_index) else Color("ffbd58")
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status.position.y = 8.2
	marker.add_child(status)
	destination_markers.append(marker)

func _build_sea_routes() -> void:
	for zone_index in range(zones.size() - 1):
		var start := _zone_water_dock(zone_index)
		var finish := _zone_water_dock(zone_index + 1)
		for step in range(1, 8):
			var ratio := float(step) / 8.0
			var position := start.lerp(finish, ratio)
			var buoy := Node3D.new()
			buoy.name = "BouéeRoute_%d_%d" % [zone_index, step]
			buoy.position = position
			add_child(buoy)
			_add_cylinder(buoy, "CorpsBouée", Vector3(0, 0.8, 0), 0.52, 0.72, 1.3, Color("d94b32"))
			_add_cone(buoy, "SommetBouée", Vector3(0, 1.85, 0), 0.62, 0.8, Color("f2cf55"), true)

func _zone_water_dock(zone_index: int) -> Vector3:
	var zone: Dictionary = zones[zone_index]
	var direction: Vector3 = zone["dock_dir"]
	var result: Vector3 = Vector3(zone["center"]) + direction.normalized() * (float(zone["radius"]) + 18.0)
	result.y = 0.05
	return result

func _add_box(root: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, glow: bool = false, yaw: float = 0.0) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.rotation.y = yaw
	node.material_override = _glow_material(color, 4.0) if glow else _material(color, 0.84)
	root.add_child(node)

func _add_cylinder(root: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, glow: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 28
	node.mesh = mesh
	node.position = position
	node.material_override = _glow_material(color, 4.0) if glow else _material(color, 0.82)
	root.add_child(node)

func _add_sphere(root: Node3D, node_name: String, position: Vector3, radius: float, color: Color, glow: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	node.mesh = mesh
	node.position = position
	node.material_override = _glow_material(color, 5.0) if glow else _material(color, 0.76)
	root.add_child(node)

func _add_cone(root: Node3D, node_name: String, position: Vector3, radius: float, height: float, color: Color, glow: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.position = position
	node.material_override = _glow_material(color, 4.5) if glow else _material(color, 0.82)
	root.add_child(node)

func _build_weather() -> void:
	particles = GPUParticles3D.new()
	particles.amount = 1200
	particles.lifetime = 2.0
	particles.visibility_aabb = AABB(Vector3(-28, -24, -28), Vector3(56, 48, 56))
	particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(22, 1, 22)
	particle_material.direction = Vector3(0, -1, 0)
	particles.process_material = particle_material
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.65)
	particles.draw_pass_1 = quad
	add_child(particles)

func _foliage_material(color: Color, strength: float) -> ShaderMaterial:
	var key: String = color.to_html(false) + "_" + str(snappedf(strength, 0.01))
	if foliage_material_cache.has(key):
		return foliage_material_cache[key] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/foliage_wind.gdshader")
	material.set_shader_parameter("foliage_color", color)
	material.set_shader_parameter("wind_strength", strength)
	foliage_material_cache[key] = material
	return material

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = energy
	return material
