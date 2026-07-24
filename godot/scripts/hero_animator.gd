class_name QuinetHeroAnimator
extends Node

var controller: PlayerController
var animation_time := 0.0
var attack_pose_time := 0.0
var power_pose_time := 0.0
var hurt_pose_time := 0.0
var shake_strength := 0.0
var previous_attack_cooldown := 0.0
var previous_skill_cooldown := 0.0
var previous_health := 0.0
var previous_aura_time := 0.0
var tracked_visual_id := 0
var displayed_frame := -1
var camera_rest_position := Vector3.ZERO
var model: Node3D
var torso: Node3D
var head: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var coat: Node3D
var weapon: Node3D
var boat_sail_parts: Array[GeometryInstance3D] = []
var boat_camera_bypass_time := 0.0

func bind(player: PlayerController) -> void:
	controller = player
	previous_health = player.health
	previous_aura_time = player.aura_time
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
		hurt_pose_time = 0.0
		_cache_rig(visual)

	animation_time += delta
	if controller.attack_cooldown > previous_attack_cooldown + 0.06:
		attack_pose_time = 0.34 if controller.hero_id == "yvane" else 0.44
		shake_strength = maxf(shake_strength, 0.13 if controller.hero_id == "yvane" else 0.20)
	if controller.skill_cooldown > previous_skill_cooldown + 0.12:
		power_pose_time = 0.80
		shake_strength = maxf(shake_strength, 0.42)
	if controller.health < previous_health - 0.1:
		hurt_pose_time = 0.34
		shake_strength = maxf(shake_strength, 0.55)
	if controller.aura_time > previous_aura_time + 1.0:
		power_pose_time = 1.05
		shake_strength = maxf(shake_strength, 0.74)

	previous_attack_cooldown = controller.attack_cooldown
	previous_skill_cooldown = controller.skill_cooldown
	previous_health = controller.health
	previous_aura_time = controller.aura_time
	attack_pose_time = maxf(0.0, attack_pose_time - delta)
	power_pose_time = maxf(0.0, power_pose_time - delta)
	hurt_pose_time = maxf(0.0, hurt_pose_time - delta)
	shake_strength = move_toward(shake_strength, 0.0, delta * 3.4)

	if controller.boat_mode:
		_update_boat_pose(delta, visual)
	else:
		_update_land_pose(delta, visual)
	_update_camera_feedback()

func _cache_rig(visual: Node3D) -> void:
	model = visual.get_node_or_null("RigVisuel/Model3D") as Node3D
	torso = visual.get_node_or_null("RigVisuel/Model3D/Torse") as Node3D
	head = visual.get_node_or_null("RigVisuel/Model3D/Tete") as Node3D
	left_arm = visual.get_node_or_null("RigVisuel/Model3D/BrasGauche") as Node3D
	right_arm = visual.get_node_or_null("RigVisuel/Model3D/BrasDroit") as Node3D
	left_leg = visual.get_node_or_null("RigVisuel/Model3D/JambeGauche") as Node3D
	right_leg = visual.get_node_or_null("RigVisuel/Model3D/JambeDroite") as Node3D
	coat = visual.get_node_or_null("RigVisuel/Model3D/Torse/Manteau") as Node3D
	weapon = visual.get_node_or_null("RigVisuel/Model3D/BrasDroit/Arme") as Node3D
	if is_instance_valid(model):
		model.visible = true
	_cache_boat_sail_parts()

func _update_land_pose(delta: float, visual: Node3D) -> void:
	_restore_boat_camera_safety()
	var horizontal_speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	var movement := clampf(horizontal_speed / maxf(controller._movement_speed(), 0.1), 0.0, 1.0)
	var frame := 0
	if power_pose_time > 0.0 or controller.aura_time > 0.0:
		frame = 3
	elif attack_pose_time > 0.0:
		frame = 2
	elif movement > 0.12:
		frame = 1
	_update_compatibility_sprite(visual, frame, movement)

	var stride := sin(animation_time * lerpf(7.0, 12.8, movement)) * movement
	var breathing := sin(animation_time * 2.8) * 0.012
	var running_bob := absf(sin(animation_time * 12.8)) * 0.055 * movement
	var target_torso_yaw := 0.0
	var target_torso_pitch := breathing * 0.55
	var target_head_yaw := sin(animation_time * 1.35) * 0.035 * (1.0 - movement)
	var left_arm_pitch := stride * 0.78
	var right_arm_pitch := -stride * 0.78
	var left_leg_pitch := -stride * 0.74
	var right_leg_pitch := stride * 0.74
	var arm_roll := 0.08

	if attack_pose_time > 0.0:
		var attack_phase := 1.0 - attack_pose_time / (0.34 if controller.hero_id == "yvane" else 0.44)
		var swing := sin(clampf(attack_phase, 0.0, 1.0) * PI)
		target_torso_yaw = -0.42 * swing
		right_arm_pitch = -1.45 + swing * 2.15
		left_arm_pitch = 0.35 - swing * 0.45
		right_leg_pitch *= 0.28
		left_leg_pitch *= 0.28
	elif power_pose_time > 0.0 or controller.aura_time > 0.0:
		var pulse := 0.82 + sin(animation_time * 8.0) * 0.12
		left_arm_pitch = -0.78
		right_arm_pitch = -0.78
		arm_roll = pulse
		target_torso_pitch = -0.10
	elif hurt_pose_time > 0.0:
		target_torso_pitch = 0.28
		target_torso_yaw = sin(animation_time * 24.0) * 0.18
		left_arm_pitch = 0.42
		right_arm_pitch = 0.42

	_pose_node(torso, Vector3(target_torso_pitch, target_torso_yaw, 0.0), delta, 13.0)
	_pose_node(head, Vector3(-target_torso_pitch * 0.35, target_head_yaw - target_torso_yaw * 0.28, 0.0), delta, 12.0)
	_pose_node(left_arm, Vector3(left_arm_pitch, 0.0, -arm_roll), delta, 16.0)
	_pose_node(right_arm, Vector3(right_arm_pitch, 0.0, arm_roll), delta, 16.0)
	_pose_node(left_leg, Vector3(left_leg_pitch, 0.0, 0.0), delta, 18.0)
	_pose_node(right_leg, Vector3(right_leg_pitch, 0.0, 0.0), delta, 18.0)

	if is_instance_valid(coat):
		coat.rotation.x = lerp_angle(coat.rotation.x, -movement * 0.18 + sin(animation_time * 6.0) * 0.025, 1.0 - exp(-8.0 * delta))
	if is_instance_valid(weapon):
		weapon.rotation.z = lerp_angle(weapon.rotation.z, sin(animation_time * 3.0) * 0.025, 1.0 - exp(-9.0 * delta))
	if is_instance_valid(model):
		model.position.y = breathing + running_bob
		model.rotation.z = lerp_angle(model.rotation.z, stride * movement * 0.022, 1.0 - exp(-10.0 * delta))

	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	var pulse_scale := 1.0
	if power_pose_time > 0.0:
		pulse_scale += sin(animation_time * 18.0) * 0.025
	visual.scale = visual.scale.lerp(Vector3.ONE * pulse_scale, 1.0 - exp(-12.0 * delta))

func _update_boat_pose(delta: float, visual: Node3D) -> void:
	_update_compatibility_sprite(visual, 0, 0.0)
	var active_input := controller._active_move_input()
	var steering := active_input.x
	var wave := sin(animation_time * 2.6) * (0.025 + controller.sea_state * 0.035)
	var throttle := clampf(-active_input.y, -1.0, 1.0)
	var helm_turn := clampf(steering, -1.0, 1.0)
	_pose_node(torso, Vector3(-0.10 + absf(throttle) * 0.05, helm_turn * 0.18, -helm_turn * 0.05), delta, 10.0)
	_pose_node(head, Vector3(0.03, helm_turn * 0.22, 0.0), delta, 9.0)
	_pose_node(left_arm, Vector3(-1.05, -0.24, -0.38 - helm_turn * 0.16), delta, 14.0)
	_pose_node(right_arm, Vector3(-1.05, 0.24, 0.38 - helm_turn * 0.16), delta, 14.0)
	_pose_node(left_leg, Vector3(0.16, 0.0, -0.08), delta, 10.0)
	_pose_node(right_leg, Vector3(0.16, 0.0, 0.08), delta, 10.0)
	if is_instance_valid(model):
		model.position.y = wave
		model.rotation.z = lerp_angle(model.rotation.z, -helm_turn * 0.035, 1.0 - exp(-6.0 * delta))
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-12.0 * delta))
	_update_boat_camera_safety(delta)

func _cache_boat_sail_parts() -> void:
	boat_sail_parts.clear()
	if not is_instance_valid(controller) or not is_instance_valid(controller.boat_visual):
		return
	var sail_root := controller.boat_visual.get_node_or_null("Voilure") as Node3D
	if sail_root == null:
		return
	for child in sail_root.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			var part_name := String(geometry.name)
			if part_name.begins_with("Voile") or part_name.begins_with("BandeRouge") or part_name.begins_with("Emblème"):
				boat_sail_parts.append(geometry)

func _update_boat_camera_safety(delta: float) -> void:
	if not is_instance_valid(controller.camera_arm) or not is_instance_valid(controller.camera):
		return
	if boat_sail_parts.is_empty():
		_cache_boat_sail_parts()
	var sail_center := controller.boat_visual.to_global(Vector3(0.0, 4.80, -0.48)) if is_instance_valid(controller.boat_visual) else controller.global_position
	var distance_to_sail := controller.camera.global_position.distance_to(sail_center)
	var hit_length := controller.camera_arm.get_hit_length()
	var camera_trapped := hit_length < 5.4 or distance_to_sail < 5.8
	var docking_speed := absf(controller.boat_speed) < 3.2
	if camera_trapped or docking_speed:
		boat_camera_bypass_time = 1.6
	else:
		boat_camera_bypass_time = maxf(0.0, boat_camera_bypass_time - delta)
	# Au quai, le relief peut rétracter le SpringArm jusque dans la grande voile.
	# On libère alors temporairement le bras, puis on réactive ses collisions dès
	# que le navire a pris le large. Cela évite l’écran blanc sans sacrifier la
	# protection contre les falaises pendant la navigation normale.
	controller.camera_arm.collision_mask = 0 if boat_camera_bypass_time > 0.0 else 1
	var hide_sail := distance_to_sail < 6.2
	for part in boat_sail_parts:
		if is_instance_valid(part):
			part.visible = not hide_sail
	if camera_trapped:
		controller.camera_target_pitch = minf(controller.camera_target_pitch, -0.38)

func _restore_boat_camera_safety() -> void:
	boat_camera_bypass_time = 0.0
	if is_instance_valid(controller) and is_instance_valid(controller.camera_arm):
		controller.camera_arm.collision_mask = 1
	for part in boat_sail_parts:
		if is_instance_valid(part):
			part.visible = true

func _update_compatibility_sprite(visual: Node3D, frame: int, movement: float) -> void:
	var sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	sprite.frame = clampi(frame, 0, maxi(0, sprite.hframes - 1))
	if frame != displayed_frame:
		displayed_frame = frame
		controller.emit_hero_pose(frame)
	var breathing := sin(animation_time * 3.2) * 0.010
	var running_bob := absf(sin(animation_time * 12.0)) * 0.045 * movement
	sprite.position.y = float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + breathing + running_bob
	sprite.modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.08 if controller.aura_time > 0.0 else 0.0)

func _pose_node(node: Node3D, target: Vector3, delta: float, response: float) -> void:
	if not is_instance_valid(node):
		return
	var weight := 1.0 - exp(-response * delta)
	node.rotation.x = lerp_angle(node.rotation.x, target.x, weight)
	node.rotation.y = lerp_angle(node.rotation.y, target.y, weight)
	node.rotation.z = lerp_angle(node.rotation.z, target.z, weight)

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
