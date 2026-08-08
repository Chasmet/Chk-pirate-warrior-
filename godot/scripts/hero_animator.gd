class_name QuinetHeroAnimator
extends Node

enum PoseState {
	INTRO,
	IDLE,
	WALK,
	RUN,
	JUMP,
	ATTACK,
	POWER,
	SPECIAL,
	DODGE,
	HURT,
	KNOCKBACK,
	LAND,
	DEFEAT,
	VICTORY,
	BOAT
}

const STATE_NAMES := [
	"intro", "idle", "walk", "run", "jump", "attack", "power", "special",
	"dodge", "hurt", "knockback", "land", "defeat", "victory", "boat"
]

const HERO_MOTION := {
	"cheikh": {
		"idle_rate": 2.15,
		"idle_amp": 0.010,
		"walk_rate": 7.0,
		"run_rate": 10.8,
		"bob": 0.046,
		"sway": 0.020,
		"lean": 0.050,
		"attack_tilt": 0.17,
		"dodge_tilt": 0.22
	},
	"yvane": {
		"idle_rate": 2.85,
		"idle_amp": 0.008,
		"walk_rate": 8.8,
		"run_rate": 14.2,
		"bob": 0.036,
		"sway": 0.027,
		"lean": 0.070,
		"attack_tilt": 0.12,
		"dodge_tilt": 0.30
	},
	"nelvyn": {
		"idle_rate": 2.55,
		"idle_amp": 0.013,
		"walk_rate": 8.1,
		"run_rate": 12.6,
		"bob": 0.054,
		"sway": 0.030,
		"lean": 0.060,
		"attack_tilt": 0.15,
		"dodge_tilt": 0.27
	}
}

var controller: PlayerController
var animation_time := 0.0
var state := PoseState.INTRO
var state_time := 0.0
var state_duration := 0.90
var shake_strength := 0.0
var previous_attack_cooldown := 0.0
var previous_skill_cooldown := 0.0
var previous_dodge_time := 0.0
var previous_health := 0.0
var previous_aura_time := 0.0
var tracked_visual_id := 0
var displayed_frame := -1
var smoothed_movement := 0.0
var smoothed_turn := 0.0
var previous_controller_yaw := 0.0
var was_on_floor := true
var navigation_visual_active := false
var attack_combo_step := 1

func bind(player: PlayerController) -> void:
	controller = player
	previous_health = player.health
	previous_aura_time = player.aura_time
	previous_attack_cooldown = player.attack_cooldown
	previous_skill_cooldown = player.skill_cooldown
	previous_dodge_time = player.dodge_time
	previous_controller_yaw = player.rotation.y
	was_on_floor = player.is_on_floor()
	if not player.enemy_defeated.is_connected(_on_enemy_defeated):
		player.enemy_defeated.connect(_on_enemy_defeated)
	_set_state(PoseState.INTRO, 0.90, true)
	set_process(true)

func supported_states() -> PackedStringArray:
	return PackedStringArray(STATE_NAMES)

func current_state_name() -> String:
	return String(STATE_NAMES[clampi(state, 0, STATE_NAMES.size() - 1)])

func _process(delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(controller.hero_visual):
		return
	var visual := controller.hero_visual
	if visual.get_instance_id() != tracked_visual_id:
		_reset_for_visual(visual)

	animation_time += delta
	state_time += delta
	_update_timers(delta)

	if controller.boat_mode:
		if not navigation_visual_active:
			navigation_visual_active = true
			HeroFactory.set_navigation_visual(visual, true)
			_set_state(PoseState.BOAT, 0.0, true)
		_update_boat_pose(visual, delta)
		_publish_state(visual)
		return
	elif navigation_visual_active:
		navigation_visual_active = false
		HeroFactory.set_navigation_visual(visual, false)
		displayed_frame = -1
		_set_state(PoseState.INTRO, 0.52, true)

	_detect_actions()
	var horizontal_speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	_resolve_state(horizontal_speed)
	_update_land_pose(visual, horizontal_speed, delta)
	_publish_state(visual)

func _reset_for_visual(visual: CharacterBody3D) -> void:
	tracked_visual_id = visual.get_instance_id()
	displayed_frame = -1
	smoothed_movement = 0.0
	smoothed_turn = 0.0
	previous_controller_yaw = controller.rotation.y
	navigation_visual_active = false
	HeroFactory.set_navigation_visual(visual, controller.boat_mode)
	_set_state(PoseState.BOAT if controller.boat_mode else PoseState.INTRO, 0.90, true)

func _detect_actions() -> void:
	var current_health := controller.health
	var took_damage := current_health < previous_health - 0.1
	var started_special := controller.aura_time > previous_aura_time + 1.0
	var started_power := controller.skill_cooldown > previous_skill_cooldown + 0.12
	var started_attack := controller.attack_cooldown > previous_attack_cooldown + 0.06
	var started_dodge := controller.dodge_time > previous_dodge_time + 0.02
	var just_landed := controller.is_on_floor() and not was_on_floor

	# Défaite et victoire sont protégées contre les entrées de combat résiduelles.
	if current_health <= 0.0:
		_set_state(PoseState.DEFEAT, 1.25, true)
	elif state == PoseState.VICTORY and _state_is_locked():
		pass
	elif took_damage:
		var damage := previous_health - current_health
		if damage >= maxf(18.0, controller.max_health * 0.13):
			_set_state(PoseState.KNOCKBACK, 0.46, true)
			shake_strength = maxf(shake_strength, 0.72)
		else:
			_set_state(PoseState.HURT, 0.30, true)
			shake_strength = maxf(shake_strength, 0.48)
	elif started_special:
		_set_state(PoseState.SPECIAL, 1.08, true)
		shake_strength = maxf(shake_strength, 0.70)
	elif started_power:
		_set_state(PoseState.POWER, 0.82, true)
		shake_strength = maxf(shake_strength, 0.42)
	elif started_dodge:
		_set_state(PoseState.DODGE, maxf(0.24, controller.dodge_time), true)
		shake_strength = maxf(shake_strength, 0.16)
	elif started_attack:
		attack_combo_step = maxi(1, controller.combo_step)
		_set_state(PoseState.ATTACK, _attack_duration(), true)
		shake_strength = maxf(shake_strength, 0.13 if controller.hero_id == "yvane" else 0.20)
	elif just_landed:
		_set_state(PoseState.LAND, 0.22, true)
		shake_strength = maxf(shake_strength, 0.14)

	was_on_floor = controller.is_on_floor()
	previous_attack_cooldown = controller.attack_cooldown
	previous_skill_cooldown = controller.skill_cooldown
	previous_dodge_time = controller.dodge_time
	previous_health = current_health
	previous_aura_time = controller.aura_time

func _resolve_state(horizontal_speed: float) -> void:
	if state == PoseState.DEFEAT:
		return
	if _state_is_locked():
		return
	if not controller.is_on_floor():
		_set_state(PoseState.JUMP, 0.0)
		return
	var movement_ratio := horizontal_speed / maxf(controller._movement_speed(), 0.1)
	if movement_ratio >= 0.68:
		_set_state(PoseState.RUN, 0.0)
	elif movement_ratio >= 0.10:
		_set_state(PoseState.WALK, 0.0)
	else:
		_set_state(PoseState.IDLE, 0.0)

func _state_is_locked() -> bool:
	match state:
		PoseState.IDLE, PoseState.WALK, PoseState.RUN, PoseState.JUMP, PoseState.BOAT:
			return false
		PoseState.DEFEAT:
			return true
		_:
			return state_time < state_duration

func _set_state(next_state: int, duration: float, force: bool = false) -> void:
	if state == PoseState.DEFEAT and next_state != PoseState.DEFEAT:
		return
	if state == next_state and not force:
		if duration > 0.0:
			state_duration = maxf(state_duration, duration)
		return
	state = next_state
	state_time = 0.0
	state_duration = maxf(duration, 0.001)

func _attack_duration() -> float:
	var base := 0.36 if controller.hero_id == "yvane" else 0.46 if controller.hero_id == "cheikh" else 0.41
	return base * (1.14 if attack_combo_step >= 3 else 1.0)

func _update_timers(delta: float) -> void:
	shake_strength = move_toward(shake_strength, 0.0, delta * 3.9)

func _update_land_pose(visual: CharacterBody3D, horizontal_speed: float, delta: float) -> void:
	var movement_target := clampf(horizontal_speed / maxf(controller._movement_speed(), 0.1), 0.0, 1.15)
	smoothed_movement = lerpf(smoothed_movement, movement_target, 1.0 - exp(-10.0 * delta))
	var yaw_delta := wrapf(controller.rotation.y - previous_controller_yaw, -PI, PI)
	previous_controller_yaw = controller.rotation.y
	var turn_target := clampf(yaw_delta / maxf(delta, 0.001) / 8.0, -1.0, 1.0)
	smoothed_turn = lerpf(smoothed_turn, turn_target, 1.0 - exp(-11.0 * delta))

	var sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	var profile: Dictionary = HERO_MOTION.get(controller.hero_id, HERO_MOTION["cheikh"])
	var progress := clampf(state_time / maxf(state_duration, 0.001), 0.0, 1.0)
	var smooth_progress := progress * progress * (3.0 - 2.0 * progress)
	var frame := _frame_for_state(progress)
	if frame != displayed_frame:
		displayed_frame = frame
		sprite.frame = frame
		controller.emit_hero_pose(frame)
	else:
		sprite.frame = frame

	var base_y := float(HeroFactory.HEROES[controller.hero_id]["sprite_y"])
	var target_visual_position := Vector3.ZERO
	var target_visual_rotation := Vector3.ZERO
	var target_visual_scale := Vector3.ONE
	var target_sprite_position := Vector3(-smoothed_turn * 0.035, base_y, 0.0)
	var target_sprite_rotation := 0.0
	var target_sprite_scale := Vector3.ONE
	var target_modulate := Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.10 if controller.aura_time > 0.0 else 0.0)
	var cadence := float(profile["walk_rate"])
	var stride := 0.0
	var state_motion := 0.0

	match state:
		PoseState.INTRO:
			var reveal := smooth_progress
			var bounce := sin(progress * PI) * 0.12
			target_visual_position.y = -0.10 + reveal * 0.10 + bounce
			target_visual_scale = Vector3.ONE * lerpf(0.82, 1.0, reveal)
			target_sprite_rotation = sin(progress * PI * 2.0) * 0.025 * (1.0 - progress)
		PoseState.IDLE:
			var breath := sin(animation_time * float(profile["idle_rate"]))
			target_sprite_position.y += breath * float(profile["idle_amp"])
			target_visual_rotation.z = sin(animation_time * 1.25) * 0.008
			target_visual_scale = Vector3(1.0 - breath * 0.0025, 1.0 + breath * 0.004, 1.0)
		PoseState.JUMP:
			var vertical_ratio := clampf(controller.velocity.y / 9.0, -1.0, 1.0)
			var rising := maxf(vertical_ratio, 0.0)
			var falling := maxf(-vertical_ratio, 0.0)
			target_visual_position.y = 0.035 + rising * 0.07 - falling * 0.025
			target_visual_rotation.x = -rising * 0.08 + falling * 0.055
			target_visual_scale = Vector3(1.0 - rising * 0.035 + falling * 0.045, 1.0 + rising * 0.075 - falling * 0.055, 1.0)
			target_sprite_position.y += rising * 0.022
		PoseState.WALK, PoseState.RUN:
			state_motion = clampf(smoothed_movement, 0.0, 1.0)
			cadence = float(profile["run_rate"]) if state == PoseState.RUN else float(profile["walk_rate"])
			stride = sin(animation_time * cadence)
			var bob := absf(stride) * float(profile["bob"]) * state_motion
			var sway := stride * float(profile["sway"]) * state_motion
			target_sprite_position.y += bob
			target_visual_position.y = -bob * 0.32
			target_visual_rotation.x = -float(profile["lean"]) * (1.0 if state == PoseState.RUN else 0.48)
			target_visual_rotation.z = -smoothed_turn * 0.065 + sway
			var squash := 1.0 - absf(stride) * (0.016 if state == PoseState.RUN else 0.009)
			target_visual_scale = Vector3(1.0 / maxf(squash, 0.95), squash, 1.0)
		PoseState.ATTACK:
			var direction_sign := -1.0 if attack_combo_step % 2 == 0 else 1.0
			var anticipation := clampf(progress / 0.23, 0.0, 1.0)
			var strike := clampf((progress - 0.23) / 0.31, 0.0, 1.0)
			var recovery := clampf((progress - 0.54) / 0.46, 0.0, 1.0)
			var attack_curve := sin(strike * PI)
			target_visual_position.z = -attack_curve * (0.16 + float(attack_combo_step) * 0.035)
			target_visual_rotation.x = -attack_curve * 0.11
			target_visual_rotation.z = direction_sign * (-anticipation * 0.07 + attack_curve * float(profile["attack_tilt"])) * (1.0 - recovery * 0.72)
			target_sprite_position.y += attack_curve * 0.035
			target_visual_scale = Vector3(1.0 + attack_curve * 0.06, 1.0 - attack_curve * 0.025, 1.0)
		PoseState.POWER:
			var charge := sin(clampf(progress / 0.58, 0.0, 1.0) * PI * 0.5)
			var release := sin(clampf((progress - 0.48) / 0.52, 0.0, 1.0) * PI)
			target_visual_position.y = charge * 0.05
			target_visual_rotation.z = sin(animation_time * 18.0) * 0.012 * charge
			target_visual_scale = Vector3.ONE * (1.0 + charge * 0.055 + release * 0.045)
			target_modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.22 + charge * 0.22)
		PoseState.SPECIAL:
			var surge := sin(progress * PI)
			var pulse := 1.0 + surge * 0.11 + sin(animation_time * 22.0) * 0.018
			target_visual_position.y = surge * 0.10
			target_visual_rotation.z = sin(animation_time * 21.0) * 0.018
			target_visual_scale = Vector3(pulse, pulse, pulse)
			target_modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.46)
		PoseState.DODGE:
			var dodge_arc := sin(progress * PI)
			var side := signf(controller.dodge_direction.dot(controller.global_transform.basis.x))
			if is_zero_approx(side):
				side = 1.0
			target_visual_position.x = side * dodge_arc * 0.26
			target_visual_position.y = dodge_arc * 0.04
			target_visual_rotation.z = -side * dodge_arc * float(profile["dodge_tilt"])
			target_visual_scale = Vector3(1.0 + dodge_arc * 0.08, 1.0 - dodge_arc * 0.08, 1.0)
			target_modulate.a = lerpf(1.0, 0.72, dodge_arc)
		PoseState.HURT:
			var hurt_curve := sin(progress * PI)
			target_visual_position.x = sin(progress * PI * 5.0) * 0.045 * hurt_curve
			target_visual_rotation.z = sin(progress * PI * 3.0) * 0.075 * hurt_curve
			target_visual_scale = Vector3(1.0 - hurt_curve * 0.05, 1.0 + hurt_curve * 0.03, 1.0)
			target_modulate = Color.WHITE.lerp(Color(1.0, 0.28, 0.24), 0.52 * hurt_curve)
		PoseState.KNOCKBACK:
			var knock_curve := sin(progress * PI)
			target_visual_position.z = knock_curve * 0.18
			target_visual_position.y = knock_curve * 0.04
			target_visual_rotation.x = knock_curve * 0.20
			target_visual_rotation.z = sin(progress * PI * 2.0) * 0.11
			target_modulate = Color.WHITE.lerp(Color(1.0, 0.20, 0.16), 0.62 * knock_curve)
		PoseState.LAND:
			var impact := sin(progress * PI)
			target_visual_position.y = -impact * 0.075
			target_visual_scale = Vector3(1.0 + impact * 0.12, 1.0 - impact * 0.18, 1.0)
			target_sprite_position.y -= impact * 0.025
		PoseState.DEFEAT:
			var fall := clampf(state_time / 0.82, 0.0, 1.0)
			var fall_smooth := fall * fall * (3.0 - 2.0 * fall)
			target_visual_position.y = -fall_smooth * 0.38
			target_visual_position.x = fall_smooth * 0.22
			target_visual_rotation.z = fall_smooth * 1.43
			target_visual_scale = Vector3(1.02, 0.96, 1.0)
			target_modulate = Color(0.58, 0.58, 0.62, 0.92)
		PoseState.VICTORY:
			var victory_wave := absf(sin(progress * PI * 2.0))
			target_visual_position.y = victory_wave * 0.18
			target_visual_rotation.z = sin(progress * PI * 2.0) * 0.065
			target_visual_scale = Vector3.ONE * (1.0 + victory_wave * 0.075)
			target_modulate = Color.WHITE.lerp(Color(HeroFactory.HEROES[controller.hero_id]["aura"]), 0.26)

	var jitter := sin(animation_time * 47.0) * shake_strength * 0.012
	target_visual_position.x += jitter
	var blend_speed := 15.0 if _uses_fast_blend() else 10.0
	var blend := 1.0 - exp(-blend_speed * delta)
	visual.position = visual.position.lerp(target_visual_position, blend)
	visual.rotation = visual.rotation.lerp(target_visual_rotation, blend)
	visual.scale = visual.scale.lerp(target_visual_scale, blend)
	sprite.position = sprite.position.lerp(target_sprite_position, blend)
	sprite.rotation.z = lerpf(sprite.rotation.z, target_sprite_rotation, blend)
	sprite.scale = sprite.scale.lerp(target_sprite_scale, blend)
	sprite.modulate = sprite.modulate.lerp(target_modulate, blend)
	sprite.flip_h = smoothed_turn > 0.18

func _uses_fast_blend() -> bool:
	match state:
		PoseState.ATTACK, PoseState.DODGE, PoseState.HURT, PoseState.KNOCKBACK:
			return true
		_:
			return false

func _frame_for_state(progress: float) -> int:
	match state:
		PoseState.WALK, PoseState.RUN, PoseState.JUMP, PoseState.DODGE, PoseState.LAND:
			return 1
		PoseState.ATTACK:
			return 2
		PoseState.POWER, PoseState.SPECIAL, PoseState.VICTORY:
			return 3
		PoseState.INTRO:
			return 3 if progress < 0.52 else 0
		_:
			return 0

func _update_boat_pose(visual: CharacterBody3D, delta: float) -> void:
	var speed_ratio := clampf(absf(controller.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var turn_ratio := clampf(controller.boat_turn_rate / 1.8, -1.0, 1.0)
	var sea_roll := sin(animation_time * (1.6 + speed_ratio * 1.2)) * (0.010 + controller.sea_state * 0.018)
	var target_position := Vector3(0.0, sin(animation_time * 2.6) * 0.008, 0.0)
	var target_rotation := Vector3(-speed_ratio * 0.035, 0.0, -turn_ratio * 0.075 + sea_roll)
	var blend := 1.0 - exp(-6.0 * delta)
	visual.position = visual.position.lerp(target_position, blend)
	visual.rotation = visual.rotation.lerp(target_rotation, blend)
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	var pilot_sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if pilot_sprite != null:
		pilot_sprite.position.y = lerpf(pilot_sprite.position.y, float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + sin(animation_time * 2.6) * 0.008, blend)
		pilot_sprite.rotation.z = lerpf(pilot_sprite.rotation.z, -turn_ratio * 0.035, blend)
		pilot_sprite.scale = pilot_sprite.scale.lerp(Vector3.ONE, blend)
		pilot_sprite.modulate = pilot_sprite.modulate.lerp(Color.WHITE, blend)
		pilot_sprite.flip_h = turn_ratio > 0.10

func _publish_state(visual: CharacterBody3D) -> void:
	visual.set_meta("animation_state_v6", current_state_name())
	visual.set_meta("animation_progress_v6", clampf(state_time / maxf(state_duration, 0.001), 0.0, 1.0))
	visual.set_meta("animation_pipeline_v6", true)

func _on_enemy_defeated(profile: Dictionary) -> void:
	if bool(profile.get("boss", false)) and state != PoseState.DEFEAT:
		_set_state(PoseState.VICTORY, 1.65, true)
		shake_strength = maxf(shake_strength, 0.26)
