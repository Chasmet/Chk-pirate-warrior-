class_name QuinetHeroAnimator
extends Node

var controller: PlayerController
var animation_time := 0.0
var attack_pose_time := 0.0
var power_pose_time := 0.0
var shake_strength := 0.0
var previous_attack_cooldown := 0.0
var previous_skill_cooldown := 0.0
var previous_health := 0.0
var previous_aura_time := 0.0
var tracked_visual_id := 0
var displayed_frame := -1
var camera_rest_position := Vector3.ZERO
var smoothed_movement := 0.0
var smoothed_turn := 0.0
var previous_controller_yaw := 0.0
var landing_recovery := 0.0
var was_on_floor := true

func bind(player: PlayerController) -> void:
	controller = player
	previous_health = player.health
	previous_aura_time = player.aura_time
	previous_controller_yaw = player.rotation.y
	was_on_floor = player.is_on_floor()
	if is_instance_valid(player.camera):
		camera_rest_position = player.camera.position
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(controller.hero_visual):
		return
	var visual := controller.hero_visual
	if visual.get_instance_id() != tracked_visual_id:
		tracked_visual_id = visual.get_instance_id()
		displayed_frame = -1
		attack_pose_time = 0.0
		power_pose_time = 0.0
		smoothed_movement = 0.0
		smoothed_turn = 0.0
		previous_controller_yaw = controller.rotation.y

	animation_time += delta
	if controller.boat_mode:
		_update_boat_pose(visual, delta)
		_update_camera_feedback()
		return

	_detect_actions()
	_update_timers(delta)
	_update_land_pose(visual, delta)
	_update_camera_feedback()

func _detect_actions() -> void:
	if controller.attack_cooldown > previous_attack_cooldown + 0.06:
		attack_pose_time = 0.34 if controller.hero_id == "yvane" else 0.42
		shake_strength = maxf(shake_strength, 0.13 if controller.hero_id == "yvane" else 0.20)
	if controller.skill_cooldown > previous_skill_cooldown + 0.12:
		power_pose_time = 0.82
		shake_strength = maxf(shake_strength, 0.42)
	if controller.health < previous_health - 0.1:
		shake_strength = maxf(shake_strength, 0.55)
	if controller.aura_time > previous_aura_time + 1.0:
		power_pose_time = 1.08
		shake_strength = maxf(shake_strength, 0.74)
	if controller.is_on_floor() and not was_on_floor:
		landing_recovery = 0.18
		shake_strength = maxf(shake_strength, 0.12)
	was_on_floor = controller.is_on_floor()
	previous_attack_cooldown = controller.attack_cooldown
	previous_skill_cooldown = controller.skill_cooldown
	previous_health = controller.health
	previous_aura_time = controller.aura_time

func _update_timers(delta: float) -> void:
	attack_pose_time = maxf(0.0, attack_pose_time - delta)
	power_pose_time = maxf(0.0, power_pose_time - delta)
	landing_recovery = maxf(0.0, landing_recovery - delta)
	shake_strength = move_toward(shake_strength, 0.0, delta * 3.7)

func _update_land_pose(visual: CharacterBody3D, delta: float) -> void:
	var horizontal_speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	var movement_target := clampf(horizontal_speed / maxf(controller._movement_speed(), 0.1), 0.0, 1.15)
	smoothed_movement = lerpf(smoothed_movement, movement_target, 1.0 - exp(-10.0 * delta))

	var yaw_delta := wrapf(controller.rotation.y - previous_controller_yaw, -PI, PI)
	previous_controller_yaw = controller.rotation.y
	var turn_target := clampf(yaw_delta / maxf(delta, 0.001) / 8.0, -1.0, 1.0)
	smoothed_turn = lerpf(smoothed_turn, turn_target, 1.0 - exp(-11.0 * delta))

	var frame := 0
	if power_pose_time > 0.0 or controller.aura_time > 0.0:
		frame = 3
	elif attack_pose_time > 0.0:
		frame = 2
	elif smoothed_movement > 0.12:
		frame = 1

	var sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite != null:
		sprite.frame = frame
		if frame != displayed_frame:
			displayed_frame = frame
			controller.emit_hero_pose(frame)
		var cadence := lerpf(7.4, 12.8, clampf(smoothed_movement, 0.0, 1.0))
		var stride := sin(animation_time * cadence)
		var breathing := sin(animation_time * 2.7) * 0.009 * (1.0 - clampf(smoothed_movement, 0.0, 1.0))
		var running_bob := absf(stride) * 0.052 * clampf(smoothed_movement, 0.0, 1.0)
		var landing_drop := sin(clampf(landing_recovery / 0.18, 0.0, 1.0) * PI) * -0.045
		sprite.position.y = float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + breathing + running_bob + landing_drop
		sprite.position.x = lerpf(sprite.position.x, -smoothed_turn * 0.035, 1.0 - exp(-12.0 * delta))
		sprite.modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.10 if controller.aura_time > 0.0 else 0.0)

	var run_wave := sin(animation_time * lerpf(7.2, 12.6, clampf(smoothed_movement, 0.0, 1.0)))
	var forward_lean := -0.045 * clampf(smoothed_movement, 0.0, 1.0)
	if attack_pose_time > 0.0:
		forward_lean -= 0.055
	if power_pose_time > 0.0:
		forward_lean += sin(animation_time * 16.0) * 0.012
	visual.position = Vector3(0.0, -absf(run_wave) * 0.018 * smoothed_movement, 0.0)
	visual.rotation.x = lerpf(visual.rotation.x, forward_lean, 1.0 - exp(-9.0 * delta))
	visual.rotation.z = lerpf(visual.rotation.z, -smoothed_turn * 0.065 + run_wave * smoothed_movement * 0.012, 1.0 - exp(-10.0 * delta))
	var squash := 1.0 - absf(run_wave) * 0.012 * clampf(smoothed_movement, 0.0, 1.0)
	var pulse := 1.0 + (sin(animation_time * 18.0) * 0.025 if power_pose_time > 0.0 else 0.0)
	visual.scale = Vector3(pulse / maxf(squash, 0.94), pulse * squash, pulse)

func _update_boat_pose(visual: CharacterBody3D, delta: float) -> void:
	var speed_ratio := clampf(absf(controller.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var turn_ratio := clampf(controller.boat_turn_rate / 1.8, -1.0, 1.0)
	var sea_roll := sin(animation_time * (1.6 + speed_ratio * 1.2)) * (0.010 + controller.sea_state * 0.018)
	visual.position = Vector3(0.0, sin(animation_time * 2.6) * 0.008, 0.0)
	visual.rotation.x = lerpf(visual.rotation.x, -speed_ratio * 0.035, 1.0 - exp(-6.0 * delta))
	visual.rotation.z = lerpf(visual.rotation.z, -turn_ratio * 0.075 + sea_roll, 1.0 - exp(-6.0 * delta))
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	var pilot_sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if pilot_sprite != null:
		pilot_sprite.position.y = float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + sin(animation_time * 2.6) * 0.008

func _update_camera_feedback() -> void:
	if not is_instance_valid(controller.camera):
		return
	if controller.boat_mode:
		controller.camera.position = camera_rest_position
		return
	var shake := Vector3(
		sin(animation_time * 47.0),
		cos(animation_time * 41.0),
		sin(animation_time * 31.0)
	) * shake_strength * 0.045
	controller.camera.position = camera_rest_position + shake
