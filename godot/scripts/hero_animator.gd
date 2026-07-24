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

	animation_time += delta
	if controller.attack_cooldown > previous_attack_cooldown + 0.06:
		attack_pose_time = 0.34 if controller.hero_id == "yvane" else 0.42
		shake_strength = maxf(shake_strength, 0.13 if controller.hero_id == "yvane" else 0.20)
	if controller.skill_cooldown > previous_skill_cooldown + 0.12:
		power_pose_time = 0.78
		shake_strength = maxf(shake_strength, 0.42)
	if controller.health < previous_health - 0.1:
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
	shake_strength = move_toward(shake_strength, 0.0, delta * 3.4)

	var horizontal_speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	var movement := clampf(horizontal_speed / maxf(controller._movement_speed(), 0.1), 0.0, 1.0)
	var frame := 0
	if power_pose_time > 0.0 or controller.aura_time > 0.0:
		frame = 3
	elif attack_pose_time > 0.0:
		frame = 2
	elif movement > 0.12:
		frame = 1

	var sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite != null:
		sprite.frame = frame
		if frame != displayed_frame:
			displayed_frame = frame
			controller.emit_hero_pose(frame)
		var breathing := sin(animation_time * 3.2) * 0.010
		var running_bob := absf(sin(animation_time * 12.0)) * 0.045 * movement
		sprite.position.y = float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + breathing + running_bob
		sprite.modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.08 if controller.aura_time > 0.0 else 0.0)

	var stride := sin(animation_time * 12.0)
	visual.position = Vector3(0.0, 0.0, 0.0)
	visual.rotation = Vector3(0.0, 0.0, stride * movement * 0.018)
	var pulse := 1.0
	if power_pose_time > 0.0:
		pulse += sin(animation_time * 18.0) * 0.025
	visual.scale = Vector3.ONE * pulse
	_update_camera_feedback()

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
