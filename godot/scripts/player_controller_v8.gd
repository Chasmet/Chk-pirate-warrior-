class_name PlayerControllerV8
extends PlayerController

# Contrôleur ciblé Android : une seule autorité pour le déplacement du bateau,
# le héros au gouvernail et les angles de caméra. Les systèmes historiques
# restent hérités de PlayerController.
const BOAT_HELM_POSITION_V8 := Vector3(0.0, 0.82, 0.28)
const BOAT_HERO_SCALE_V8 := 1.06
const BOAT_INPUT_DEADZONE_V8 := 0.10

var boat_steering_input_v8 := 0.0
var boat_throttle_input_v8 := 0.0

func _physics_boat(delta: float) -> void:
	var raw_input := _active_move_input()
	var raw_throttle := _filtered_boat_axis(-raw_input.y)
	var raw_steering := _filtered_boat_axis(raw_input.x)
	# Le filtre absorbe les petites oscillations du joystick tactile sans créer
	# de retard perceptible au démarrage ou lors d'un changement de cap.
	boat_throttle_input_v8 = move_toward(boat_throttle_input_v8, raw_throttle, 5.8 * delta)
	boat_steering_input_v8 = move_toward(boat_steering_input_v8, raw_steering, 7.4 * delta)
	var throttle := boat_throttle_input_v8
	var steering := boat_steering_input_v8
	var weather_speed_factor := lerpf(1.0, 0.78, sea_state)
	var maximum_forward_speed := BOAT_MAX_SPEED * weather_speed_factor
	var speed_ratio := clampf(absf(boat_speed) / maxf(maximum_forward_speed, 0.1), 0.0, 1.0)
	var steering_grip := lerpf(0.62, 1.0, smoothstep(0.0, 0.70, speed_ratio))
	var reverse_factor := -0.72 if boat_speed < -0.35 else 1.0
	var desired_turn_rate := steering * steering_grip * lerpf(1.54, 1.28, sea_state) * reverse_factor
	if absf(throttle) < 0.045 and absf(boat_speed) < 0.55:
		desired_turn_rate = 0.0
	boat_turn_rate = move_toward(boat_turn_rate, desired_turn_rate, 4.6 * delta)
	boat_heading -= boat_turn_rate * delta

	var target_speed := throttle * (maximum_forward_speed if throttle >= 0.0 else 7.0)
	var engine_response := (7.6 if absf(throttle) > 0.05 else 2.8) * lerpf(1.0, 0.78, sea_state)
	boat_speed = move_toward(boat_speed, target_speed, engine_response * delta)
	var forward: Vector3 = -Basis(Vector3.UP, boat_heading).z
	var desired_velocity := forward * boat_speed
	var hull_grip := lerpf(10.2, 7.6, sea_state)
	velocity.x = move_toward(velocity.x, desired_velocity.x, hull_grip * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, hull_grip * delta)
	velocity.y = 0.0
	rotation.y = boat_heading
	move_and_slide()

	var ocean_height := BOAT_WATERLINE + _sample_ocean_wave(global_position) * lerpf(0.52, 1.05, sea_state)
	global_position.y = lerpf(global_position.y, ocean_height, 1.0 - exp(-6.2 * delta))
	if is_instance_valid(boat_visual):
		speed_ratio = clampf(absf(boat_speed) / maxf(maximum_forward_speed, 0.1), 0.0, 1.0)
		var wave_time := float(Time.get_ticks_msec()) * 0.001
		boat_visual.position.y = sin(wave_time * 2.65) * (0.020 + sea_state * 0.065)
		var wave_roll := sin(wave_time * 1.82 + global_position.x * 0.013) * sea_state * 0.078
		var target_roll := -steering * 0.068 * speed_ratio + wave_roll
		boat_visual.rotation.z = lerpf(boat_visual.rotation.z, target_roll, 1.0 - exp(-3.8 * delta))
		boat_visual.rotation.x = sin(wave_time * 1.46 + global_position.z * 0.011) * (0.012 + sea_state * 0.054 + speed_ratio * 0.016)
		var wake := boat_visual.get_node_or_null("Sillage") as GPUParticles3D
		if wake != null:
			wake.emitting = absf(boat_speed) > 1.6
			wake.amount_ratio = lerpf(0.30, 1.0, speed_ratio)
		var helm := boat_visual.get_node_or_null("PosteDePilotage/Gouvernail3D") as Node3D
		if helm != null:
			helm.rotation.z = lerp_angle(helm.rotation.z, -steering * 0.92, 1.0 - exp(-8.5 * delta))
		var rudder := boat_visual.get_node_or_null("GouvernailArrière") as Node3D
		if rudder != null:
			rudder.rotation.y = lerp_angle(rudder.rotation.y, steering * 0.58, 1.0 - exp(-7.0 * delta))
		var sail_root := boat_visual.get_node_or_null("Voilure") as Node3D
		if sail_root != null:
			var wind_sway := sin(wave_time * 2.1) * sea_state * 0.035
			sail_root.rotation.y = lerp_angle(sail_root.rotation.y, steering * 0.10 + wind_sway, 1.0 - exp(-2.4 * delta))
	_set_boat_hero_art(steering)
	if not boat_pilot_marker_emitted and is_instance_valid(hero_visual) and hero_visual.visible:
		boat_pilot_marker_emitted = true
		print("CHK_BOAT_HELMSMAN_V8_READY hero=%s stable_input=1" % hero_id)
	boat_steering_changed.emit(hero_id, steering, throttle, speed_ratio)

func _update_camera(delta: float, direction: Vector3) -> void:
	# ThirdPersonCameraGuard reste l'unique script qui place CameraJoueur.
	# Ici, seules les intentions d'orbite et les angles sont calculés afin
	# d'éviter deux déplacements concurrents de la caméra à chaque image.
	if not camera_stick_input.is_zero_approx():
		camera_target_yaw -= camera_stick_input.x * 2.05 * delta
		camera_target_pitch = clampf(camera_target_pitch - camera_stick_input.y * 1.18 * delta, -0.54, 0.18)
		camera_manual_timer = 1.8
		camera_recenter_timer = 1.15
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var camera_forward := -Basis(Vector3.UP, camera_yaw).z
	var moving_forward := direction.length_squared() > 0.02 and direction.dot(camera_forward) > 0.18
	if camera_manual_timer <= 0.0 and camera_recenter_timer <= 0.0:
		if boat_mode:
			camera_target_yaw = lerp_angle(camera_target_yaw, boat_heading, 1.0 - exp(-4.0 * delta))
			camera_target_pitch = lerpf(camera_target_pitch, BOAT_CAMERA_REST_PITCH, 1.0 - exp(-3.0 * delta))
		elif assist_lock_time > 0.0 and is_instance_valid(assisted_target) and assisted_target.health > 0.0 and assisted_target.global_position.distance_to(global_position) < 13.0:
			var target_direction := assisted_target.global_position - global_position
			target_direction.y = 0.0
			if target_direction.length_squared() > 0.01:
				camera_target_yaw = lerp_angle(camera_target_yaw, atan2(-target_direction.x, -target_direction.z), 1.0 - exp(-2.2 * delta))
		elif moving_forward and horizontal_speed > _movement_speed() * 0.48:
			camera_target_yaw = lerp_angle(camera_target_yaw, rotation.y, 1.0 - exp(-1.35 * delta))
	camera_yaw = lerp_angle(camera_yaw, camera_target_yaw, 1.0 - exp(-9.5 * delta))
	camera_pitch = lerpf(camera_pitch, camera_target_pitch, 1.0 - exp(-9.0 * delta))
	if not boat_mode:
		_update_camera_facing()
		_confirm_hero_framing(delta, float(HeroFactory.HEROES[hero_id]["height"]))

func _set_land_hero_art() -> void:
	super._set_land_hero_art()
	if is_instance_valid(hero_visual):
		hero_visual.scale = Vector3.ONE

func _set_boat_hero_art(steering: float) -> void:
	if not is_instance_valid(hero_visual):
		return
	hero_visual.visible = true
	hero_visual.position = BOAT_HELM_POSITION_V8
	hero_visual.rotation = Vector3.ZERO
	hero_visual.scale = Vector3.ONE * BOAT_HERO_SCALE_V8
	var sprite := hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	var steering_path := String(profile["steering_sprite"])
	var steering_available := ResourceLoader.exists(steering_path)
	var resolved_path := steering_path if steering_available else String(profile["third_person_sprite"])
	if sprite.texture == null or sprite.texture.resource_path != resolved_path:
		var resolved_texture := load(resolved_path) as Texture2D
		if resolved_texture != null:
			sprite.texture = resolved_texture
	sprite.hframes = 3 if steering_available else 4
	sprite.vframes = 1
	sprite.frame = (0 if steering < -0.16 else 2 if steering > 0.16 else 1) if steering_available else 0
	sprite.position.y = float(profile["sprite_y"])
	sprite.pixel_size = float(profile["pixel_size"])
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.055
	sprite.render_priority = 10
	sprite.modulate = Color.WHITE
	sprite.visible = true

func enter_boat(spawn_position: Vector3, target_position: Vector3) -> void:
	boat_steering_input_v8 = 0.0
	boat_throttle_input_v8 = 0.0
	super.enter_boat(spawn_position, target_position)
	_set_boat_hero_art(0.0)

func exit_boat(landing_position: Vector3) -> void:
	boat_steering_input_v8 = 0.0
	boat_throttle_input_v8 = 0.0
	super.exit_boat(landing_position)

func _filtered_boat_axis(value: float) -> float:
	var magnitude := absf(value)
	if magnitude <= BOAT_INPUT_DEADZONE_V8:
		return 0.0
	var normalized := clampf((magnitude - BOAT_INPUT_DEADZONE_V8) / (1.0 - BOAT_INPUT_DEADZONE_V8), 0.0, 1.0)
	return signf(value) * pow(normalized, 1.12)
