class_name WorldVisuals
extends Node3D

signal weather_changed(label: String)

const GROUND_COLORS := [Color("8a6f43"), Color("4d6638"), Color("e8f3f8"), Color("c9954f"), Color("403435"), Color("4f5d66")]
const WEATHER := ["soleil", "pluie", "neige", "soleil", "cendres", "tempête"]

var environment: Environment
var sun: DirectionalLight3D
var particles: GPUParticles3D
var particle_material: ParticleProcessMaterial
var day_time := 0.22

func build() -> void:
	_build_environment()
	_build_ocean()
	_build_islands()
	_build_weather()

func update_world(delta: float, player_position: Vector3) -> void:
	day_time = fmod(day_time + delta / 260.0, 1.0)
	var daylight := clampf(sin(day_time * PI), 0.05, 1.0)
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
			particles.amount = 0
			environment.fog_density = 0.003
	quad.material = material
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 19820415
	for zone_index in range(6):
		var root := Node3D.new()
		root.position = Vector3(zone_index * 170.0, 0, 0)
		add_child(root)
		var island := StaticBody3D.new()
		root.add_child(island)
		var mesh_node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 66.0
		mesh.bottom_radius = 75.0
		mesh.height = 5.0
		mesh.radial_segments = 48
		mesh_node.mesh = mesh
		mesh_node.position.y = -1.0
		mesh_node.material_override = _material(GROUND_COLORS[zone_index], 0.9)
		island.add_child(mesh_node)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 66.0
		shape.height = 5.0
		collision.shape = shape
		collision.position.y = -1.0
		island.add_child(collision)
		_build_landmark(root, zone_index)
		for i in range(25):
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(18.0, 58.0)
			_build_prop(root, zone_index, Vector3(cos(angle) * radius, 3.0, sin(angle) * radius), rng)
		if zone_index not in [2, 3, 4]:
			_build_grass(root, rng)

func _build_landmark(root: Node3D, zone_index: int) -> void:
	var landmark := MeshInstance3D.new()
	if zone_index == 4:
		var cone := CylinderMesh.new()
		cone.top_radius = 5.5
		cone.bottom_radius = 24.0
		cone.height = 27.0
		landmark.mesh = cone
		landmark.position = Vector3(0, 13.5, -24)
	else:
		var box := BoxMesh.new()
		box.size = Vector3(18, 11, 12) if zone_index >= 2 else Vector3(22, 5, 8)
		landmark.mesh = box
		landmark.position = Vector3(0, 6.5 if zone_index >= 2 else 3.0, -28)
	landmark.material_override = _material(GROUND_COLORS[zone_index].darkened(0.28), 0.96)
	root.add_child(landmark)

func _build_prop(root: Node3D, zone_index: int, position: Vector3, rng: RandomNumberGenerator) -> void:
	var prop := MeshInstance3D.new()
	if zone_index == 3:
		var cactus := CapsuleMesh.new()
		cactus.radius = 0.35
		cactus.height = rng.randf_range(2.5, 4.8)
		prop.mesh = cactus
		prop.material_override = _material(Color("397446"), 0.88)
	elif zone_index == 2:
		var pine := CylinderMesh.new()
		pine.top_radius = 0.0
		pine.bottom_radius = rng.randf_range(1.3, 2.2)
		pine.height = rng.randf_range(3.8, 6.8)
		prop.mesh = pine
		prop.material_override = _material(Color("dcebf2"), 0.86)
	else:
		var tree := CylinderMesh.new()
		tree.top_radius = 0.15
		tree.bottom_radius = 0.30
		tree.height = rng.randf_range(3.5, 6.5)
		prop.mesh = tree
		prop.material_override = _material(Color("2d7042") if zone_index < 2 else Color("554b46"), 0.9)
	prop.position = position
	root.add_child(prop)

func _build_grass(root: Node3D, rng: RandomNumberGenerator) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 450
	var blade := QuadMesh.new()
	blade.size = Vector2(0.22, 0.72)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/grass.gdshader")
	blade.material = shader_material
	multimesh.mesh = blade
	for i in range(multimesh.instance_count):
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * 60.0
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		var scale_value := rng.randf_range(0.65, 1.35)
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

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
