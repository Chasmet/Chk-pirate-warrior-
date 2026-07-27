class_name AdaptiveLightingDirectorV7
extends Node3D

var world: GameWorldV6
var player: PlayerController
var visuals: WorldVisualsV5
var zones: Array = []
var fill_light: DirectionalLight3D
var rim_light: DirectionalLight3D
var lightning_light: DirectionalLight3D
var lanterns: Array[OmniLight3D] = []
var active_zone := 0
var average_delta := 1.0 / 60.0
var lightning_timer := 8.0
var lightning_flash := 0.0
var rng := RandomNumberGenerator.new()

func configure(target_world: GameWorldV6, target_player: PlayerController, target_visuals: WorldVisualsV5, zone_definitions: Array) -> void:
	world = target_world
	player = target_player
	visuals = target_visuals
	zones = zone_definitions
	rng.seed = 19820415
	_build_directional_lights()
	_build_lantern_pool()
	_prepare_environment()
	set_active_zone(int(world.current_zone))
	set_process(true)
	set_meta("adaptive_lighting_v7", true)
	print("CHK_LIGHTING_V7_READY dynamic=true mobile_budget=true")

func _process(delta: float) -> void:
	if not is_instance_valid(visuals):
		return
	average_delta = lerpf(average_delta, clampf(delta, 0.001, 0.08), 1.0 - exp(-1.8 * delta))
	var daylight := _daylight_ratio()
	var weather := String(visuals.current_weather)
	_update_directional_lights(delta, daylight, weather)
	_update_lanterns(delta, daylight, weather)
	_update_environment(delta, daylight, weather)
	_update_lightning(delta, weather)

func set_active_zone(zone_index: int) -> void:
	active_zone = clampi(zone_index, 0, max(0, zones.size() - 1))
	if zones.is_empty():
		return
	var zone: Dictionary = zones[active_zone]
	var center := Vector3(zone.get("center", Vector3.ZERO))
	var direction := Vector3(zone.get("dock_dir", Vector3.FORWARD)).normalized()
	var side := Vector3(-direction.z, 0.0, direction.x)
	var radius := float(zone.get("radius", 100.0))
	var positions := [
		center + direction * (radius - 19.0) + Vector3.UP * 5.2,
		center + side * radius * 0.34 + Vector3.UP * 6.6,
		center - side * radius * 0.31 + Vector3.UP * 6.1,
		center - direction * radius * 0.22 + Vector3.UP * 8.0
	]
	for index in range(lanterns.size()):
		lanterns[index].global_position = positions[index]

func _build_directional_lights() -> void:
	fill_light = DirectionalLight3D.new()
	fill_light.name = "LumièreCielV7"
	fill_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	fill_light.light_color = Color("8fbce8")
	fill_light.light_energy = 0.22
	fill_light.shadow_enabled = false
	add_child(fill_light)

	rim_light = DirectionalLight3D.new()
	rim_light.name = "ContreJourV7"
	rim_light.rotation_degrees = Vector3(-24.0, 152.0, 0.0)
	rim_light.light_color = Color("ffd39a")
	rim_light.light_energy = 0.12
	rim_light.shadow_enabled = false
	add_child(rim_light)

	lightning_light = DirectionalLight3D.new()
	lightning_light.name = "ÉclairTempêteV7"
	lightning_light.rotation_degrees = Vector3(-63.0, 42.0, 0.0)
	lightning_light.light_color = Color("d8edff")
	lightning_light.light_energy = 0.0
	lightning_light.shadow_enabled = false
	add_child(lightning_light)

func _build_lantern_pool() -> void:
	for index in range(4):
		var light := OmniLight3D.new()
		light.name = "LanterneDynamiqueV7_%02d" % index
		light.light_color = Color("ffb75d") if index != 3 else Color("70c7ff")
		light.light_energy = 0.0
		light.omni_range = 25.0 if index == 0 else 20.0
		light.omni_attenuation = 1.45
		light.shadow_enabled = false
		light.distance_fade_enabled = true
		light.distance_fade_begin = 65.0
		light.distance_fade_length = 28.0
		add_child(light)
		lanterns.append(light)

func _prepare_environment() -> void:
	if not is_instance_valid(visuals) or visuals.environment == null:
		return
	var environment := visuals.environment
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.08
	environment.adjustment_contrast = 1.10
	environment.adjustment_saturation = 1.08
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.10
	environment.tonemap_white = 2.35
	# En compatibilité OpenGL, le glow est coûteux et instable sur certains GPU.
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		environment.glow_enabled = false
	else:
		environment.glow_enabled = true
		environment.glow_intensity = 0.64
		environment.glow_bloom = 0.12

func _update_directional_lights(delta: float, daylight: float, weather: String) -> void:
	if not is_instance_valid(fill_light) or not is_instance_valid(rim_light):
		return
	var storm_factor := 1.0 if weather == "tempête" else 0.62 if weather in ["pluie", "cendres", "neige"] else 0.0
	var fill_target := (0.18 + daylight * 0.34) * lerpf(1.0, 0.70, storm_factor)
	var rim_target := (0.05 + daylight * 0.22) * lerpf(1.0, 0.42, storm_factor)
	fill_light.light_energy = lerpf(fill_light.light_energy, fill_target, 1.0 - exp(-2.1 * delta))
	rim_light.light_energy = lerpf(rim_light.light_energy, rim_target, 1.0 - exp(-1.8 * delta))
	var night_fill := Color("5578ad")
	var day_fill := Color("a6d5ff")
	fill_light.light_color = fill_light.light_color.lerp(night_fill.lerp(day_fill, daylight), 1.0 - exp(-1.5 * delta))
	var dawn := 1.0 - absf(daylight * 2.0 - 1.0)
	rim_light.light_color = rim_light.light_color.lerp(Color("ffd7a6").lerp(Color("ff9d63"), dawn * 0.45), 1.0 - exp(-1.4 * delta))
	if is_instance_valid(visuals.sun):
		var low_fps := average_delta > 0.030
		visuals.sun.directional_shadow_max_distance = 170.0 if low_fps else 285.0
		visuals.sun.light_energy = lerpf(visuals.sun.light_energy, (0.22 + daylight * 1.08) * lerpf(1.0, 0.66, storm_factor), 1.0 - exp(-1.9 * delta))

func _update_lanterns(delta: float, daylight: float, weather: String) -> void:
	var darkness := 1.0 - smoothstep(0.12, 0.42, daylight)
	var weather_boost := 0.32 if weather in ["tempête", "pluie", "cendres", "neige"] else 0.0
	var target := clampf(darkness + weather_boost, 0.0, 1.0)
	var low_fps := average_delta > 0.030
	for index in range(lanterns.size()):
		var enabled_target := target if not low_fps or index < 2 else 0.0
		var energy := (1.25 if index == 0 else 0.86) * enabled_target
		lanterns[index].light_energy = lerpf(lanterns[index].light_energy, energy, 1.0 - exp(-3.2 * delta))
		lanterns[index].visible = lanterns[index].light_energy > 0.015

func _update_environment(delta: float, daylight: float, weather: String) -> void:
	if visuals.environment == null:
		return
	var storm_factor := 1.0 if weather == "tempête" else 0.55 if weather in ["pluie", "cendres", "neige"] else 0.0
	var brightness_target := (0.88 + daylight * 0.24) * lerpf(1.0, 0.86, storm_factor)
	var saturation_target := (0.92 + daylight * 0.17) * lerpf(1.0, 0.80, storm_factor)
	visuals.environment.adjustment_brightness = lerpf(visuals.environment.adjustment_brightness, brightness_target, 1.0 - exp(-1.4 * delta))
	visuals.environment.adjustment_saturation = lerpf(visuals.environment.adjustment_saturation, saturation_target, 1.0 - exp(-1.2 * delta))
	visuals.environment.ambient_light_energy = lerpf(visuals.environment.ambient_light_energy, (0.30 + daylight * 0.62) * lerpf(1.0, 0.75, storm_factor), 1.0 - exp(-1.6 * delta))

func _update_lightning(delta: float, weather: String) -> void:
	if weather != "tempête":
		lightning_timer = minf(lightning_timer, 6.0)
		lightning_flash = move_toward(lightning_flash, 0.0, delta * 8.0)
		lightning_light.light_energy = lightning_flash
		return
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		lightning_flash = rng.randf_range(1.6, 2.6)
		lightning_timer = rng.randf_range(7.0, 16.0)
	lightning_flash = move_toward(lightning_flash, 0.0, delta * 6.5)
	lightning_light.light_energy = lightning_flash

func _daylight_ratio() -> float:
	return clampf((sin(visuals.day_time * TAU) + 0.12) / 1.12, 0.02, 1.0)
