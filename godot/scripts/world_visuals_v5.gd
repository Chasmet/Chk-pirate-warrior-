class_name WorldVisualsV5
extends WorldVisualsV4

const OCEAN_SIZE_V7 := Vector2(6800.0, 3400.0)
const OCEAN_CENTER_V7 := Vector3(2500.0, 0.0, 50.0)

var sun_disk: MeshInstance3D
var cloud_root: Node3D
var cloud_time := 0.0
var weather_blend := 1.0
var previous_weather := "soleil"
var target_sun_color := Color("fff1cf")

func build(zone_definitions: Array, unlocked: Array = [0]) -> void:
	super.build(zone_definitions, unlocked)
	_build_sun_disk_v5()
	_build_cloud_layer_v5()
	if is_instance_valid(environment):
		environment.adjustment_enabled = true
		environment.adjustment_brightness = 1.04
		environment.adjustment_contrast = 1.08
		environment.adjustment_saturation = 1.06
	set_meta("large_ocean_v7", true)
	print("CHK_V7_VISUALS_READY ocean=6800x3400 sun=true clouds=true")

func _build_ocean() -> void:
	var ocean := MeshInstance3D.new()
	ocean.name = "OcéanContinuGrandArchipelV7"
	var plane := PlaneMesh.new()
	plane.size = OCEAN_SIZE_V7
	plane.subdivide_width = 260
	plane.subdivide_depth = 130
	ocean.mesh = plane
	ocean.position = OCEAN_CENTER_V7
	ocean_material = ShaderMaterial.new()
	ocean_material.shader = load("res://shaders/ocean.gdshader")
	ocean.material_override = ocean_material
	ocean.visibility_range_end = 7200.0
	add_child(ocean)

func update_world(delta: float, player_position: Vector3) -> void:
	super.update_world(delta, player_position)
	cloud_time += delta
	weather_blend = minf(1.0, weather_blend + delta * 0.34)
	var daylight := clampf((sin(day_time * TAU) + 0.12) / 1.12, 0.025, 1.0)
	var dawn := 1.0 - absf(daylight * 2.0 - 1.0)
	var warm := Color("ffb36b")
	var clear := Color("fff2d4")
	var storm := Color("b7c8d2")
	var desired_color := clear.lerp(warm, dawn * 0.52)
	if current_weather in ["pluie", "tempête", "cendres"]:
		desired_color = desired_color.lerp(storm, 0.52 if current_weather != "tempête" else 0.76)
	target_sun_color = desired_color
	if is_instance_valid(sun):
		sun.light_color = sun.light_color.lerp(target_sun_color, 1.0 - exp(-1.3 * delta))
		sun.directional_shadow_max_distance = 285.0
	if is_instance_valid(sun_disk) and is_instance_valid(sun):
		var sun_direction := -sun.global_transform.basis.z.normalized()
		sun_disk.global_position = player_position - sun_direction * 650.0
		sun_disk.scale = Vector3.ONE * lerpf(16.0, 24.0, dawn)
		sun_disk.visible = daylight > 0.07 and current_weather != "tempête"
		var sun_material := sun_disk.material_override as StandardMaterial3D
		if sun_material != null:
			sun_material.albedo_color = Color(target_sun_color, 0.92)
			sun_material.emission = target_sun_color
			sun_material.emission_energy_multiplier = lerpf(2.4, 5.8, daylight)
	if is_instance_valid(cloud_root):
		cloud_root.position.x = fmod(cloud_time * (1.8 if current_weather == "tempête" else 0.62), 420.0)
		cloud_root.position.z = sin(cloud_time * 0.025) * 34.0
		var cloud_alpha := 0.34 if current_weather == "soleil" else 0.60 if current_weather in ["pluie", "neige"] else 0.78
		for child in cloud_root.get_children():
			if child is MeshInstance3D:
				var material := (child as MeshInstance3D).material_override as StandardMaterial3D
				if material != null:
					material.albedo_color.a = lerpf(material.albedo_color.a, cloud_alpha, 1.0 - exp(-0.7 * delta))
	if is_instance_valid(particles):
		particles.amount_ratio = lerpf(particles.amount_ratio, 1.0 if particles.emitting else 0.0, 1.0 - exp(-2.0 * delta))

func set_zone_weather(zone_index: int) -> void:
	previous_weather = current_weather
	weather_blend = 0.0
	super.set_zone_weather(zone_index)
	if is_instance_valid(particles) and particles.emitting:
		particles.amount_ratio = 0.18

func _build_animals(root: Node3D, zone_index: int, island_radius: float) -> void:
	super._build_animals(root, zone_index, island_radius)
	var species_by_zone := [
		["mouette", "mouette", "lézard", "cerf"],
		["aigle", "singe", "cerf", "lézard"],
		["aigle", "pingouin", "mouette", "cerf"],
		["aigle", "chameau", "lézard", "mouette"],
		["aigle", "lézard", "sanglier", "mouette"],
		["aigle", "mouette", "cerf", "lézard"],
		["mouette", "singe", "cerf", "aigle"],
		["aigle", "lézard", "mouette", "sanglier"],
		["aigle", "mouette", "cerf", "lézard"]
	]
	var colors := [Color("dbe7ed"), Color("77543d"), Color("5c8d52"), Color("bd8755")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 50500 + zone_index * 911
	for animal_index in range(8):
		var species := String(species_by_zone[clampi(zone_index, 0, species_by_zone.size() - 1)][animal_index % 4])
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(island_radius * 0.18, island_radius * 0.76)
		var x := cos(angle) * distance
		var z := sin(angle) * distance
		var flying := species in ["mouette", "aigle"]
		var y := _terrain_height(zone_index, x, z, island_radius) + (rng.randf_range(8.0, 15.0) if flying else 0.08)
		var animal := QuinetAmbientAnimal.new()
		animal.name = "FauneV5_%s_%02d" % [species.capitalize(), animal_index]
		root.add_child(animal)
		animal.configure(species, colors[animal_index % colors.size()], Vector3(x, y, z), 60000 + zone_index * 100 + animal_index)
		_apply_animal_lod_v5(animal)

func _apply_animal_lod_v5(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			geometry.visibility_range_end = 145.0
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_apply_animal_lod_v5(child)

func _build_sun_disk_v5() -> void:
	sun_disk = MeshInstance3D.new()
	sun_disk.name = "SoleilV5"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	sun_disk.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("fff0b0")
	material.emission_enabled = true
	material.emission = Color("ffd987")
	material.emission_energy_multiplier = 5.0
	material.disable_receive_shadows = true
	sun_disk.material_override = material
	sun_disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sun_disk)

func _build_cloud_layer_v5() -> void:
	cloud_root = Node3D.new()
	cloud_root.name = "NuagesDynamiquesV7"
	add_child(cloud_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19820415
	for index in range(46):
		var cloud := MeshInstance3D.new()
		cloud.name = "Nuage_%02d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 10
		sphere.rings = 6
		cloud.mesh = sphere
		cloud.position = Vector3(rng.randf_range(-720.0, 5750.0), rng.randf_range(82.0, 158.0), rng.randf_range(-1620.0, 1710.0))
		cloud.scale = Vector3(rng.randf_range(16.0, 36.0), rng.randf_range(3.0, 8.0), rng.randf_range(10.0, 24.0))
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.88, 0.94, 0.98, 0.34)
		material.roughness = 1.0
		material.disable_receive_shadows = true
		cloud.material_override = material
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloud.visibility_range_end = 1300.0
		cloud_root.add_child(cloud)
