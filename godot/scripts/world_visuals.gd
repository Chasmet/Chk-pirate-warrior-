class_name WorldVisuals
extends Node3D

signal weather_changed(label: String)

const GROUND_COLORS := [Color("8a6f43"), Color("4d6638"), Color("e8f3f8"), Color("c9954f"), Color("403435"), Color("4f5d66")]
const GROUND_DETAIL_COLORS := [Color("516c35"), Color("2e7b3d"), Color("f8fbfc"), Color("dfb66d"), Color("6f4134"), Color("718491")]
const SHORE_COLORS := [Color("c9a66a"), Color("b89a5b"), Color("dcebf0"), Color("e4c080"), Color("5b433d"), Color("71828a")]
const ROCK_COLORS := [Color("594838"), Color("38513a"), Color("9fb4bc"), Color("845f3d"), Color("241f20"), Color("354652")]
const WEATHER := ["soleil", "pluie", "neige", "soleil", "cendres", "tempête"]
const AMBIENT_ANIMAL_SCRIPT := preload("res://scripts/ambient_animal.gd")

var environment: Environment
var sun: DirectionalLight3D
var particles: GPUParticles3D
var particle_material: ParticleProcessMaterial
var sky_material: ProceduralSkyMaterial
var ocean_material: ShaderMaterial
var foliage_material_cache: Dictionary = {}
var grass_materials: Array[ShaderMaterial] = []
var day_time: float = 0.22
var weather_time := 0.0
var current_weather := "soleil"
var target_fog_density := 0.003
var lightning_flash := 0.0
var lightning_timer := 3.4
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
		var status := marker.get_node_or_null("Statut") as Label3D
		var selected := index == zone_index
		if beam != null:
			# Une seule balise doit guider le joueur. Les six faisceaux
			# translucides superposés formaient de grands aplats blancs sur
			# les GPU mobiles, surtout depuis la mer.
			beam.visible = selected
			var material := beam.material_override as StandardMaterial3D
			if material != null:
				material.albedo_color = Color(1.0, 0.73, 0.18, 0.14)
				material.emission_energy_multiplier = 2.6
		if label != null:
			label.visible = selected
			label.font_size = 42
			label.modulate = Color("ffe08a")
		if status != null:
			status.visible = selected

func set_unlocked_zones(value: Array) -> void:
	unlocked_zones = value.duplicate()
	for index in range(destination_markers.size()):
		var marker := destination_markers[index]
		var status := marker.get_node_or_null("Statut") as Label3D
		if status != null:
			status.text = "DÉBLOQUÉE" if unlocked_zones.has(index) else "À DÉCOUVRIR"
			status.modulate = Color("71e39b") if unlocked_zones.has(index) else Color("ffbd58")

func update_world(delta: float, player_position: Vector3) -> void:
	weather_time += delta
	day_time = fmod(day_time + delta / 260.0, 1.0)
	var daylight: float = clampf((sin(day_time * TAU) + 0.12) / 1.12, 0.025, 1.0)
	var storm_strength := 1.0 if current_weather == "tempête" else 0.62 if current_weather == "cendres" else 0.34 if current_weather in ["pluie", "neige"] else 0.0
	sun.rotation_degrees.x = day_time * 360.0 - 90.0
	if current_weather == "tempête":
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_flash = 1.0
			lightning_timer = 2.4 + fmod(weather_time * 0.73, 3.8)
	else:
		lightning_flash = 0.0
	lightning_flash = move_toward(lightning_flash, 0.0, delta * 4.4)
	sun.light_energy = (0.16 + daylight * 1.48) * lerpf(1.0, 0.48, storm_strength) + lightning_flash * 3.8
	environment.ambient_light_energy = (0.20 + daylight * 0.58) * lerpf(1.0, 0.62, storm_strength) + lightning_flash * 0.55
	environment.fog_density = lerpf(environment.fog_density, target_fog_density, 1.0 - exp(-1.8 * delta))
	var daylight_color := Color("1e6da6").lerp(Color("07111f"), 1.0 - daylight)
	var horizon_color := Color("8bd6ee").lerp(Color("14283b"), 1.0 - daylight)
	var weather_top := Color("26384a") if current_weather == "tempête" else Color("493632") if current_weather == "cendres" else Color("53697a")
	var weather_horizon := Color("778896") if current_weather == "tempête" else Color("8a5c48") if current_weather == "cendres" else Color("91a8b5")
	sky_material.sky_top_color = daylight_color.lerp(weather_top, storm_strength * 0.82).lightened(lightning_flash * 0.35)
	sky_material.sky_horizon_color = horizon_color.lerp(weather_horizon, storm_strength * 0.68).lightened(lightning_flash * 0.42)
	particles.global_position = player_position + Vector3(0, 12, 0)

func weather_for_zone(zone_index: int) -> String:
	return String(WEATHER[clampi(zone_index, 0, WEATHER.size() - 1)])

func set_zone_weather(zone_index: int) -> void:
	var weather := weather_for_zone(zone_index)
	current_weather = weather
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
			target_fog_density = 0.009
		"neige":
			particles.amount = 850
			particle_material.direction = Vector3(0.15, -1, 0.08)
			particle_material.initial_velocity_min = 2.0
			particle_material.initial_velocity_max = 5.0
			quad.size = Vector2(0.12, 0.12)
			material.albedo_color = Color(1, 1, 1, 0.92)
			target_fog_density = 0.014
		"tempête":
			particles.amount = 1700
			particle_material.direction = Vector3(-0.58, -1, 0.12)
			particle_material.initial_velocity_min = 20.0
			particle_material.initial_velocity_max = 30.0
			quad.size = Vector2(0.03, 0.92)
			material.albedo_color = Color(0.55, 0.72, 0.9, 0.76)
			target_fog_density = 0.025
		"cendres":
			particles.amount = 650
			particle_material.direction = Vector3(0.1, -0.3, 0.05)
			particle_material.initial_velocity_min = 1.0
			particle_material.initial_velocity_max = 3.0
			quad.size = Vector2(0.10, 0.10)
			material.albedo_color = Color(0.25, 0.19, 0.17, 0.88)
			target_fog_density = 0.018
		_:
			particles.amount = 1
			particles.emitting = false
			target_fog_density = 0.003
	quad.material = material
	var gust_strength := 1.0 if weather == "tempête" else 0.62 if weather in ["pluie", "cendres"] else 0.30 if weather == "neige" else 0.08
	for foliage_material in foliage_material_cache.values():
		(foliage_material as ShaderMaterial).set_shader_parameter("weather_gust", gust_strength)
	for grass_material in grass_materials:
		grass_material.set_shader_parameter("weather_gust", gust_strength)
	if is_instance_valid(ocean_material):
		var sea_strength := 1.0 if weather == "tempête" else 0.68 if weather == "cendres" else 0.52 if weather == "pluie" else 0.34 if weather == "neige" else 0.18
		ocean_material.set_shader_parameter("wave_height", lerpf(0.52, 1.05, sea_strength))
		ocean_material.set_shader_parameter("wave_speed", lerpf(0.72, 1.18, sea_strength))
		ocean_material.set_shader_parameter("roughness_value", lerpf(0.09, 0.24, sea_strength))
		ocean_material.set_shader_parameter("storm_strength", sea_strength)
	if particles.emitting:
		particles.restart()
	weather_changed.emit(weather.capitalize())

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
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
		add_child(root)
		var ground := MeshInstance3D.new()
		ground.name = "TerrainRelief"
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
		_build_destination_marker(root, zone_index, radius, Vector3(zone["dock_dir"]))

func _create_island_mesh(zone_index: int, island_radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_count := 13
	var segment_count := 72
	var center := _terrain_point(zone_index, island_radius, 0.0, 0.0)
	for segment in range(segment_count):
		var angle_current := TAU * float(segment) / float(segment_count)
		var angle_next := TAU * float(segment + 1) / float(segment_count)
		var current := _terrain_point(zone_index, island_radius, 1.0 / float(ring_count), angle_current)
		var next := _terrain_point(zone_index, island_radius, 1.0 / float(ring_count), angle_next)
		_add_terrain_vertex(surface, center, island_radius)
		_add_terrain_vertex(surface, current, island_radius)
		_add_terrain_vertex(surface, next, island_radius)
	for ring in range(1, ring_count):
		var inner_ratio := float(ring) / float(ring_count)
		var outer_ratio := float(ring + 1) / float(ring_count)
		for segment in range(segment_count):
			var angle_current := TAU * float(segment) / float(segment_count)
			var angle_next := TAU * float(segment + 1) / float(segment_count)
			var inner_current := _terrain_point(zone_index, island_radius, inner_ratio, angle_current)
			var inner_next := _terrain_point(zone_index, island_radius, inner_ratio, angle_next)
			var outer_current := _terrain_point(zone_index, island_radius, outer_ratio, angle_current)
			var outer_next := _terrain_point(zone_index, island_radius, outer_ratio, angle_next)
			_add_terrain_vertex(surface, inner_current, island_radius)
			_add_terrain_vertex(surface, outer_next, island_radius)
			_add_terrain_vertex(surface, inner_next, island_radius)
			_add_terrain_vertex(surface, inner_current, island_radius)
			_add_terrain_vertex(surface, outer_current, island_radius)
			_add_terrain_vertex(surface, outer_next, island_radius)
	for segment in range(segment_count):
		var angle_current := TAU * float(segment) / float(segment_count)
		var angle_next := TAU * float(segment + 1) / float(segment_count)
		var top_current := _terrain_point(zone_index, island_radius, 1.0, angle_current)
		var top_next := _terrain_point(zone_index, island_radius, 1.0, angle_next)
		var bottom_current := Vector3(top_current.x, -3.2, top_current.z)
		var bottom_next := Vector3(top_next.x, -3.2, top_next.z)
		_add_terrain_vertex(surface, top_current, island_radius)
		_add_terrain_vertex(surface, top_next, island_radius)
		_add_terrain_vertex(surface, bottom_next, island_radius)
		_add_terrain_vertex(surface, top_current, island_radius)
		_add_terrain_vertex(surface, bottom_next, island_radius)
		_add_terrain_vertex(surface, bottom_current, island_radius)
	surface.generate_normals()
	surface.generate_tangents()
	return surface.commit()

func _terrain_point(zone_index: int, island_radius: float, radial_ratio: float, angle: float) -> Vector3:
	var edge_variation := (
		sin(angle * 3.0 + float(zone_index) * 0.7) * 0.024
		+ sin(angle * 7.0 - float(zone_index) * 1.2) * 0.018
		+ sin(angle * 13.0 + 0.8) * 0.010
	)
	var shaped_ratio := radial_ratio * (1.0 + edge_variation * smoothstep(0.45, 1.0, radial_ratio))
	var local_radius := island_radius * shaped_ratio
	var x := cos(angle) * local_radius
	var z := sin(angle) * local_radius
	return Vector3(x, _terrain_height(zone_index, x, z, island_radius), z)

func _add_terrain_vertex(surface: SurfaceTool, point: Vector3, island_radius: float) -> void:
	surface.set_uv(Vector2(point.x / island_radius * 0.5 + 0.5, point.z / island_radius * 0.5 + 0.5))
	surface.add_vertex(point)

func _terrain_height(zone_index: int, x: float, z: float, island_radius: float) -> float:
	var ratio := clampf(Vector2(x, z).length() / maxf(island_radius, 0.01), 0.0, 1.08)
	var terrain_seed := float(zone_index) * 1.73
	var broad := sin(x * 0.050 + terrain_seed) * cos(z * 0.044 - terrain_seed * 0.7)
	var crossed := sin((x + z) * 0.027 + terrain_seed * 2.1) * 0.56
	var detail := cos(x * 0.113 - z * 0.086 + terrain_seed) * 0.24
	var relief_amounts := [1.15, 2.65, 2.05, 1.55, 3.25, 2.10]
	var interior := pow(clampf(1.0 - ratio, 0.0, 1.0), 1.15)
	var relief := maxf(0.0, broad * 0.58 + crossed * 0.30 + detail * 0.12 + 0.38)
	var plateau := 1.52 + relief * float(relief_amounts[zone_index]) * interior
	var shore_blend := smoothstep(0.76, 1.0, ratio)
	return lerpf(plateau, 0.48, shore_blend)

func _terrain_material(zone_index: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/terrain_realistic.gdshader")
	material.set_shader_parameter("ground_color", GROUND_COLORS[zone_index])
	material.set_shader_parameter("ground_detail", GROUND_DETAIL_COLORS[zone_index])
	material.set_shader_parameter("shore_color", SHORE_COLORS[zone_index])
	material.set_shader_parameter("rock_color", ROCK_COLORS[zone_index])
	material.set_shader_parameter("wetness", 0.28 if zone_index in [0, 1, 2] else 0.12)
	return material

func _build_shore_foam(root: Node3D, island_radius: float) -> void:
	var foam_ring := MeshInstance3D.new()
	foam_ring.name = "ÉcumeDuRivage"
	var mesh := TorusMesh.new()
	mesh.inner_radius = island_radius * 0.985
	mesh.outer_radius = island_radius * 1.022
	mesh.rings = 72
	mesh.ring_segments = 6
	foam_ring.mesh = mesh
	foam_ring.position.y = 0.10
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.80, 0.95, 1.0, 0.42)
	material.emission_enabled = true
	material.emission = Color("b9efff")
	material.emission_energy_multiplier = 1.25
	foam_ring.material_override = material
	foam_ring.visibility_range_end = 360.0
	root.add_child(foam_ring)

func _build_zone_props(root: Node3D, zone_index: int, island_radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + zone_index * 997
	var prop_count := 96 if zone_index in [0, 1] else 74
	for i in range(prop_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(island_radius * 0.30, island_radius * 0.82)
		var prop_position := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		prop_position.y = _terrain_height(zone_index, prop_position.x, prop_position.z, island_radius) + 0.03
		match zone_index:
			0, 1:
				if i % 5 == 0:
					_build_shrub(root, prop_position, rng.randf_range(0.75, 1.35), zone_index)
				else:
					_build_tree(root, prop_position, rng.randf_range(0.72, 1.36), zone_index == 0)
			2:
				_build_snow_pine(root, prop_position, rng.randf_range(0.8, 1.5))
			3:
				if i % 6 == 0:
					_build_fallen_log(root, prop_position, rng.randf_range(0.8, 1.4), Color("8d6039"))
				else:
					_build_rock(root, prop_position, Color("9c6e40"), rng.randf_range(0.8, 1.8))
			4:
				_build_rock(root, prop_position, Color("30292b"), rng.randf_range(0.9, 2.2))
			_:
				_build_rock(root, prop_position, Color("4c5960"), rng.randf_range(0.8, 1.8))
	if zone_index in [0, 1, 3]:
		_build_grass(root, rng, island_radius, zone_index)
	if zone_index in [0, 1]:
		for index in range(18):
			var shrub_angle := rng.randf_range(0.0, TAU)
			var shrub_radius := rng.randf_range(island_radius * 0.18, island_radius * 0.72)
			var shrub_position := Vector3(cos(shrub_angle) * shrub_radius, 0.0, sin(shrub_angle) * shrub_radius)
			shrub_position.y = _terrain_height(zone_index, shrub_position.x, shrub_position.z, island_radius)
			_build_shrub(root, shrub_position, rng.randf_range(0.55, 1.05), zone_index)

func _build_tree(root: Node3D, position: Vector3, scale_value: float, palm: bool) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.32 * scale_value
	trunk_mesh.bottom_radius = 0.48 * scale_value
	trunk_mesh.height = 7.0 * scale_value
	trunk_mesh.radial_segments = 14
	trunk.mesh = trunk_mesh
	trunk.position = position + Vector3(0, 3.5 * scale_value, 0)
	trunk.material_override = _material(Color("6a442c"), 0.9)
	trunk.visibility_range_end = 210.0
	root.add_child(trunk)
	if palm:
		for leaf_index in range(8):
			var leaf := MeshInstance3D.new()
			leaf.name = "Palme"
			var leaf_mesh := SphereMesh.new()
			leaf_mesh.radius = 1.0
			leaf_mesh.height = 2.0
			leaf.mesh = leaf_mesh
			var leaf_angle := TAU * float(leaf_index) / 8.0
			leaf.position = position + Vector3(cos(leaf_angle) * 1.42, 7.30 * scale_value, sin(leaf_angle) * 1.42)
			leaf.scale = Vector3(2.7, 0.18, 0.72) * scale_value
			leaf.rotation_degrees = Vector3(8.0, -rad_to_deg(leaf_angle), sin(leaf_angle) * 18.0)
			leaf.material_override = _foliage_material(Color("25733d").lightened(float(leaf_index % 3) * 0.045), 0.30)
			leaf.visibility_range_end = 210.0
			root.add_child(leaf)
	else:
		var crown_offsets := [
			Vector3(0, 0.25, 0),
			Vector3(1.45, -0.15, 0.45),
			Vector3(-1.35, -0.05, 0.30),
			Vector3(0.20, -0.10, -1.25)
		]
		for crown_index in range(crown_offsets.size()):
			var crown := MeshInstance3D.new()
			crown.name = "Feuillage"
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			crown.mesh = sphere
			crown.position = position + Vector3(0, 7.1 * scale_value, 0) + Vector3(crown_offsets[crown_index]) * scale_value
			crown.scale = Vector3(2.2, 1.45, 2.0) * scale_value
			crown.material_override = _foliage_material(Color("1f6b35").lightened(float(crown_index) * 0.035), 0.18)
			crown.visibility_range_end = 210.0
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

func _build_shrub(root: Node3D, position: Vector3, scale_value: float, zone_index: int) -> void:
	var colors := [Color("3d7736"), Color("257342"), Color("58734b")]
	for cluster_index in range(3):
		var shrub := MeshInstance3D.new()
		shrub.name = "SousBois"
		var mesh := SphereMesh.new()
		mesh.radius = 0.72 * scale_value
		mesh.height = 1.05 * scale_value
		shrub.mesh = mesh
		var angle := TAU * float(cluster_index) / 3.0
		shrub.position = position + Vector3(cos(angle) * 0.48, 0.42 * scale_value, sin(angle) * 0.48)
		shrub.scale = Vector3(1.35, 0.72, 1.15)
		shrub.material_override = _foliage_material(colors[clampi(zone_index, 0, colors.size() - 1)].lightened(float(cluster_index) * 0.035), 0.24)
		shrub.visibility_range_end = 110.0
		root.add_child(shrub)

func _build_fallen_log(root: Node3D, position: Vector3, scale_value: float, color: Color) -> void:
	var fallen_log := MeshInstance3D.new()
	fallen_log.name = "TroncÉchoué"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42 * scale_value
	mesh.bottom_radius = 0.50 * scale_value
	mesh.height = 4.2 * scale_value
	mesh.radial_segments = 14
	fallen_log.mesh = mesh
	fallen_log.position = position + Vector3(0, 0.46 * scale_value, 0)
	fallen_log.rotation_degrees = Vector3(90.0, position.x * 2.3, 0.0)
	fallen_log.material_override = _material(color, 0.94)
	root.add_child(fallen_log)

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

func _build_grass(root: Node3D, rng: RandomNumberGenerator, island_radius: float, zone_index: int) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 3400 if zone_index == 1 else 2500
	var blade := QuadMesh.new()
	blade.size = Vector2(0.18, 1.25)
	var grass_material := ShaderMaterial.new()
	grass_material.shader = load("res://shaders/grass.gdshader")
	grass_materials.append(grass_material)
	if zone_index == 3:
		grass_material.set_shader_parameter("grass_dark", Color("75511f"))
		grass_material.set_shader_parameter("grass_light", Color("d0a14c"))
		grass_material.set_shader_parameter("wind_strength", 0.28)
	elif zone_index == 0:
		grass_material.set_shader_parameter("grass_dark", Color("244c24"))
		grass_material.set_shader_parameter("grass_light", Color("6f9a3d"))
	blade.material = grass_material
	multimesh.mesh = blade
	for i in range(multimesh.instance_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = sqrt(rng.randf()) * island_radius * 0.92
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var y := _terrain_height(zone_index, x, z, island_radius) + 0.06
		var blade_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		var scale_value: float = rng.randf_range(0.65, 1.35)
		blade_basis = blade_basis.scaled(Vector3.ONE * scale_value)
		multimesh.set_instance_transform(i, Transform3D(blade_basis, Vector3(x, y, z)))
	var instance := MultiMeshInstance3D.new()
	instance.name = "HerbeDense"
	instance.multimesh = multimesh
	instance.visibility_range_end = 130.0
	root.add_child(instance)

func _build_animals(root: Node3D, zone_index: int, island_radius: float) -> void:
	var species_by_zone := [
		["mouette", "sanglier"],
		["singe", "cerf"],
		["pingouin", "aigle"],
		["chameau", "lézard"],
		["lézard", "aigle"],
		["aigle", "cerf"]
	]
	var colors_by_zone := [
		[Color("f3f0e7"), Color("5a3525")],
		[Color("6b3f2c"), Color("9a7048")],
		[Color("20282d"), Color("6c5940")],
		[Color("b88958"), Color("5d6934")],
		[Color("6f3e2c"), Color("302f34")],
		[Color("657785"), Color("7a6048")]
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 24820 + zone_index * 431
	for animal_index in range(10):
		var species_index: int = animal_index % 2
		var species := String(species_by_zone[zone_index][species_index])
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(island_radius * 0.20, island_radius * 0.70)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var y := _terrain_height(zone_index, x, z, island_radius) + (7.5 if species in ["mouette", "aigle"] else 0.05)
		var animal := AMBIENT_ANIMAL_SCRIPT.new() as QuinetAmbientAnimal
		animal.name = "%s_%02d" % [species.capitalize(), animal_index]
		root.add_child(animal)
		animal.configure(species, Color(colors_by_zone[zone_index][species_index]), Vector3(x, y, z), 90000 + zone_index * 100 + animal_index)

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

func _build_dock(root: Node3D, _zone_index: int, island_radius: float, raw_direction: Vector3) -> void:
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
	var dock_sign := Label3D.new()
	dock_sign.text = "QUAI • BATEAU"
	dock_sign.font_size = 42
	dock_sign.outline_size = 9
	dock_sign.modulate = Color("ffe08a")
	dock_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dock_sign.position = sign_position + Vector3(0, 5.5, 0)
	root.add_child(dock_sign)

func _build_destination_marker(root: Node3D, zone_index: int, island_radius: float, raw_direction: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "BaliseDestination_%d" % zone_index
	marker.position = raw_direction.normalized() * (island_radius + 32.0)
	root.add_child(marker)
	var beam := MeshInstance3D.new()
	beam.name = "Faisceau"
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.16
	beam_mesh.bottom_radius = 0.62
	beam_mesh.height = 16.0
	beam.mesh = beam_mesh
	beam.position.y = 8.0
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.visibility_range_begin = 34.0
	beam.visibility_range_begin_margin = 8.0
	beam.material_override = _glow_material(Color(1.0, 0.73, 0.18, 0.14), 2.6)
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
			var route_position := start.lerp(finish, ratio)
			var buoy := Node3D.new()
			buoy.name = "BouéeRoute_%d_%d" % [zone_index, step]
			buoy.position = route_position
			add_child(buoy)
			_add_cylinder(buoy, "CorpsBouée", Vector3(0, 0.8, 0), 0.52, 0.72, 1.3, Color("d94b32"), false, false)
			_add_cone(buoy, "SommetBouée", Vector3(0, 1.85, 0), 0.62, 0.8, Color("f2cf55"), true)

func _zone_water_dock(zone_index: int) -> Vector3:
	var zone: Dictionary = zones[zone_index]
	var direction: Vector3 = zone["dock_dir"]
	var result: Vector3 = Vector3(zone["center"]) + direction.normalized() * (float(zone["radius"]) + 32.0)
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
	if not glow:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Collision"
		collision.position = position
		collision.rotation.y = yaw
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		_decoration_collision_body(root).add_child(collision)

func _add_cylinder(root: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, glow: bool = false, collision_enabled: bool = true) -> void:
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
	if not glow and collision_enabled:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Collision"
		collision.position = position
		var shape := CylinderShape3D.new()
		shape.radius = maxf(top_radius, bottom_radius)
		shape.height = height
		collision.shape = shape
		_decoration_collision_body(root).add_child(collision)

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
	if not glow:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Collision"
		collision.position = position
		var shape := SphereShape3D.new()
		shape.radius = radius
		collision.shape = shape
		_decoration_collision_body(root).add_child(collision)

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
	if not glow:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Collision"
		collision.position = position
		var shape := CylinderShape3D.new()
		shape.radius = radius * 0.78
		shape.height = height
		collision.shape = shape
		_decoration_collision_body(root).add_child(collision)

func _decoration_collision_body(root: Node3D) -> StaticBody3D:
	var existing := root.get_node_or_null("CollisionsDécor") as StaticBody3D
	if existing != null:
		return existing
	var body := StaticBody3D.new()
	body.name = "CollisionsDécor"
	root.add_child(body)
	return body

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
