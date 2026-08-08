class_name MobileCrewMemberV6
extends RoamingCrewMemberV5

var follow_slot := Vector3.ZERO
var stuck_time := 0.0
var last_position := Vector3.ZERO
var neutral_pause := 0.0
var locomotion_phase := 0.0

func set_follow_slot(value: Vector3) -> void:
	follow_slot = value
	set_meta("formation_slot", value)

func set_home(value: Vector3) -> void:
	super.set_home(value)
	last_position = value

func _physics_process(delta: float) -> void:
	local_time += delta
	locomotion_phase += delta * maxf(Vector2(velocity.x, velocity.z).length(), 0.55)
	support_cooldown = maxf(0.0, support_cooldown - delta)
	neutral_pause = maxf(0.0, neutral_pause - delta)
	if attitude == "hostile":
		super._physics_process(delta)
		_apply_motion_style(delta)
		return
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = minf(velocity.y, -0.35)
	if attitude == "allied":
		_process_mobile_ally(delta)
	else:
		_process_mobile_neutral(delta)
	move_and_slide()
	_recover_when_stuck(delta)
	_update_sprite_motion()
	_apply_motion_style(delta)

func _process_mobile_ally(delta: float) -> void:
	var enemy := _nearest_regular_enemy(16.0)
	if is_instance_valid(enemy):
		var enemy_offset := enemy.global_position - global_position
		enemy_offset.y = 0.0
		var desired_range := maxf(2.3, _signature_range() * 0.76)
		if enemy_offset.length() > desired_range:
			_move_flat(enemy_offset.normalized(), speed * 1.14, delta)
		else:
			_move_flat(Vector3.ZERO, 0.0, delta)
			if support_cooldown <= 0.0:
				_use_signature_on_enemy(enemy)
				support_cooldown = _signature_cooldown()
		return
	var player_target := target as PlayerController
	if _is_healing_power() and support_cooldown <= 0.0 and player_target.health < player_target.max_health * 0.72:
		_heal_player(player_target)
		support_cooldown = 6.0
	var slot := Basis(Vector3.UP, player_target.rotation.y) * follow_slot
	var desired_position := player_target.global_position + slot
	var offset := desired_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > 44.0 and not player_target.boat_mode:
		global_position = desired_position + Vector3.UP * 2.0
		velocity = Vector3.ZERO
		last_position = global_position
		return
	if player_target.boat_mode:
		_move_flat(Vector3.ZERO, 0.0, delta)
		return
	if distance > 1.15:
		var catchup := clampf(distance / 8.0, 1.0, 1.55)
		_move_flat(offset.normalized(), speed * catchup, delta)
	else:
		var player_flat_velocity := Vector3(player_target.velocity.x, 0.0, player_target.velocity.z)
		if player_flat_velocity.length() > 0.65:
			_move_flat(player_flat_velocity.normalized(), minf(speed * 0.72, player_flat_velocity.length()), delta)
		else:
			_move_flat(Vector3.ZERO, 0.0, delta)

func _process_mobile_neutral(delta: float) -> void:
	if global_position.distance_to(home_position) > roam_radius * 1.55:
		roam_target = home_position
		neutral_pause = 0.0
	if global_position.distance_to(roam_target) < 1.0:
		if neutral_pause <= 0.0:
			neutral_pause = rng.randf_range(0.45, 1.55)
		else:
			_choose_roam_target()
	var offset := roam_target - global_position
	offset.y = 0.0
	if neutral_pause > 0.0:
		_move_flat(Vector3.ZERO, 0.0, delta)
	elif offset.length_squared() > 0.25:
		_move_flat(offset.normalized(), speed * 0.68, delta)
	else:
		_choose_roam_target()

func _recover_when_stuck(delta: float) -> void:
	var moved := Vector2(global_position.x - last_position.x, global_position.z - last_position.z).length()
	var wants_to_move := Vector2(velocity.x, velocity.z).length() > 0.55
	if wants_to_move and moved < 0.012:
		stuck_time += delta
	else:
		stuck_time = maxf(0.0, stuck_time - delta * 1.8)
	if stuck_time > 1.15:
		velocity += Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized() * 3.4
		global_position.y += 0.22
		stuck_time = 0.0
	last_position = global_position

func _apply_motion_style(delta: float) -> void:
	if not is_instance_valid(sprite):
		return
	var ratio := clampf(Vector2(velocity.x, velocity.z).length() / maxf(speed, 0.1), 0.0, 1.45)
	var attacking := attack_windup > 0.0 or support_cooldown > _signature_cooldown() * 0.74
	var bob := absf(sin(locomotion_phase * 2.85)) * 0.055 * ratio
	var breathe := sin(local_time * 2.25) * 0.012 if ratio < 0.12 else 0.0
	sprite.position.y = visual_height * 0.50 + bob + breathe
	var target_lean := clampf(-velocity.x / maxf(speed, 0.1) * 0.065, -0.08, 0.08)
	if attacking:
		target_lean = -0.10
	sprite.rotation.z = lerpf(sprite.rotation.z, target_lean, 1.0 - exp(-8.0 * delta))
	var stretch := 1.0 + sin(locomotion_phase * 2.85) * 0.028 * ratio
	if attacking:
		stretch = 1.07
	sprite.scale = sprite.scale.lerp(Vector3(2.0 - stretch, stretch, 1.0), 1.0 - exp(-9.0 * delta))
	if absf(velocity.x) > 0.20:
		sprite.flip_h = velocity.x < 0.0
