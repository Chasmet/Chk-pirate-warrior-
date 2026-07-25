class_name QuinetHeroAnimator
extends Node

var controller: PlayerController
var animation_time := 0.0
var attack_pose_time := 0.0
var power_pose_time := 0.0
var previous_attack_cooldown := 0.0
var previous_skill_cooldown := 0.0
var previous_health := 0.0
var camera_rest_position := Vector3.ZERO
var smoothed_movement := 0.0
var previous_controller_yaw := 0.0
var smoothed_turn := 0.0
var shake_strength := 0.0

func bind(player: PlayerController) -> void:
	controller = player
	previous_health = player.health
	previous_attack_cooldown = player.attack_cooldown
	previous_skill_cooldown = player.skill_cooldown
	previous_controller_yaw = player.rotation.y
	if is_instance_valid(player.camera):
		camera_rest_position = player.camera.position
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(controller.hero_visual):
		return
	animation_time += delta
	_detect_actions()
	attack_pose_time = maxf(0.0, attack_pose_time - delta)
	power_pose_time = maxf(0.0, power_pose_time - delta)
	shake_strength = move_toward(shake_strength, 0.0, delta * 3.4)
	if controller.boat_mode:
		_update_boat_pose(controller.hero_visual, delta)
	else:
		_update_land_pose(controller.hero_visual, delta)
	_update_camera_feedback()

func _detect_actions() -> void:
	if controller.attack_cooldown > previous_attack_cooldown + 0.05:
		attack_pose_time = 0.38
		shake_strength = maxf(shake_strength, 0.18)
	if controller.skill_cooldown > previous_skill_cooldown + 0.08:
		power_pose_time = 0.80
		shake_strength = maxf(shake_strength, 0.38)
	if controller.health < previous_health - 0.1:
		shake_strength = maxf(shake_strength, 0.52)
	previous_attack_cooldown = controller.attack_cooldown
	previous_skill_cooldown = controller.skill_cooldown
	previous_health = controller.health

func _update_land_pose(visual: CharacterBody3D, delta: float) -> void:
	var speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	var target := clampf(speed / maxf(controller._movement_speed(), 0.1), 0.0, 1.2)
	smoothed_movement = lerpf(smoothed_movement, target, 1.0 - exp(-10.0 * delta))
	var yaw_delta := wrapf(controller.rotation.y - previous_controller_yaw, -PI, PI)
	previous_controller_yaw = controller.rotation.y
	smoothed_turn = lerpf(smoothed_turn, clampf(yaw_delta / maxf(delta, 0.001) / 7.0, -1.0, 1.0), 1.0 - exp(-10.0 * delta))

	var cadence := lerpf(3.4, 8.8, clampf(smoothed_movement, 0.0, 1.0))
	var stride := sin(animation_time * cadence) * clampf(smoothed_movement, 0.0, 1.0)
	var hips := visual.get_node_or_null("RigVisuel/CharacterModel/Hips") as Node3D
	if hips == null:
		return
	var arm_l := hips.get_node_or_null("ArmL") as Node3D
	var arm_r := hips.get_node_or_null("ArmR") as Node3D
	var leg_l := hips.get_node_or_null("LegL") as Node3D
	var leg_r := hips.get_node_or_null("LegR") as Node3D

	if arm_l != null:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, stride * 0.65, 1.0 - exp(-12.0 * delta))
	if arm_r != null:
		var attack_swing := -1.25 if attack_pose_time > 0.0 else -stride * 0.65
		arm_r.rotation.x = lerpf(arm_r.rotation.x, attack_swing, 1.0 - exp(-14.0 * delta))
		arm_r.rotation.z = lerpf(arm_r.rotation.z, -0.45 if power_pose_time > 0.0 else 0.0, 1.0 - exp(-12.0 * delta))
	if leg_l != null:
		leg_l.rotation.x = lerpf(leg_l.rotation.x, -stride * 0.72, 1.0 - exp(-12.0 * delta))
	if leg_r != null:
		leg_r.rotation.x = lerpf(leg_r.rotation.x, stride * 0.72, 1.0 - exp(-12.0 * delta))

	hips.position.y = 0.92 + absf(stride) * 0.035
	hips.rotation.z = lerpf(hips.rotation.z, -smoothed_turn * 0.10, 1.0 - exp(-9.0 * delta))
	visual.rotation.x = lerpf(visual.rotation.x, -0.08 * smoothed_movement, 1.0 - exp(-8.0 * delta))
	visual.rotation.z = lerpf(visual.rotation.z, -smoothed_turn * 0.06, 1.0 - exp(-8.0 * delta))

	var aura := visual.get_node_or_null("RigVisuel/Aura") as GPUParticles3D
	if aura != null:
		aura.emitting = controller.aura_time > 0.0 or power_pose_time > 0.0

func _update_boat_pose(visual: CharacterBody3D, delta: float) -> void:
	var speed_ratio := clampf(absf(controller.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var turn_ratio := clampf(controller.boat_turn_rate / 1.8, -1.0, 1.0)
	var sea_roll := sin(animation_time * (1.6 + speed_ratio)) * (0.012 + controller.sea_state * 0.020)
	visual.position.y = sin(animation_time * 2.2) * 0.010
	visual.rotation.x = lerpf(visual.rotation.x, -speed_ratio * 0.05, 1.0 - exp(-6.0 * delta))
	visual.rotation.z = lerpf(visual.rotation.z, -turn_ratio * 0.11 + sea_roll, 1.0 - exp(-6.0 * delta))

	var hips := visual.get_node_or_null("RigVisuel/CharacterModel/Hips") as Node3D
	if hips == null:
		return
	var arm_l := hips.get_node_or_null("ArmL") as Node3D
	var arm_r := hips.get_node_or_null("ArmR") as Node3D
	var leg_l := hips.get_node_or_null("LegL") as Node3D
	var leg_r := hips.get_node_or_null("LegR") as Node3D
	if arm_l != null:
		arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.62, 0.0, -0.32), 1.0 - exp(-8.0 * delta))
	if arm_r != null:
		arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.62, 0.0, 0.32), 1.0 - exp(-8.0 * delta))
	if leg_l != null:
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.10, 1.0 - exp(-8.0 * delta))
	if leg_r != null:
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.10, 1.0 - exp(-8.0 * delta))
	hips.rotation.z = lerpf(hips.rotation.z, -turn_ratio * 0.16, 1.0 - exp(-8.0 * delta))
	hips.rotation.x = lerpf(hips.rotation.x, -speed_ratio * 0.08, 1.0 - exp(-8.0 * delta))

func _update_camera_feedback() -> void:
	if not is_instance_valid(controller.camera):
		return
	if controller.boat_mode:
		controller.camera.position = camera_rest_position
		return
	var shake := Vector3(sin(animation_time * 47.0), cos(animation_time * 41.0), sin(animation_time * 31.0)) * shake_strength * 0.045
	controller.camera.position = camera_rest_position + shake