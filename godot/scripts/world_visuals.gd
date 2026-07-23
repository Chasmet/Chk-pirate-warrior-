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

func build() -> void:
	_build_environment()
	_build_ocean()
	_build_islands()
	_build_weather()

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
	plane.size = Vector2(1150, 360)
	plane.subdivide_width = 160
	plane.subdivide_depth = 50
	ocean.mesh = plane
	ocean.position = Vector3(425, 0, 0)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/ocean.gdshader")
	ocean.material_override = shader_material
	add_child(ocean)

func _build_islands() -> void:
	for zone_index in range(GROUND_COLORS.size()):
		var root := Node3D.new()
		root.name = "Zone_%d" % zone_index
		root.position = Vector3(float(zone_index) * 170.0, 0, 0)
		add_child(root)
		var ground := MeshInstance3D.new()
		var ground_mesh := CylinderMesh.new()
		ground_mesh.top_radius = 62.0
		ground_mesh.bottom_radius = 68.0
		ground_mesh.height = 3.0
		ground_mesh.radial_segments = 48
		ground.mesh = ground_mesh
		ground.position.y = 0.0
		ground.material_override = _material(GROUND_COLORS[zone_index], 0.92)
		root.add_child(ground)
		var floor_body := StaticBody3D.new()
		var floor_collision := CollisionShape3D.new()
		var floor_shape := CylinderShape3D.new()
		floor_shape.radius = 62.0
		floor_shape.height = 3.0
		floor_collision.shape = floor_shape
		floor_body.add_child(floor_collision)
		root.add_child(floor_body)
		_build_zone_props(root, zone_index)

func _build_zone_props(root: Node3D, zone_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + zone_index * 997
	for i in range(34):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(22.0, 55.0)
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
		_build_grass(root, rng)

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

func _build_grass(root: Node3D, rng: RandomNumberGenerator) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 900
	var blade := QuadMesh.new()
	blade.size = Vector2(0.18, 1.25)
	var grass_material := ShaderMaterial.new()
	grass_material.shader = load("res://shaders/grass.gdshader")
	blade.material = grass_material
	multimesh.mesh = blade
	for i in range(multimesh.instance_count):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = sqrt(rng.randf()) * 60.0
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		var scale_value: float = rng.randf_range(0.65, 1.35)
		basis = basis.scaled(Vector3.ONE * scale_value)
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(cos(angle) * radius, 1.58, sin(angle) * radius)))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = 78.0
	root.add_child(instance)

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
