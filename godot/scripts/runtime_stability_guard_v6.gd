class_name RuntimeStabilityGuardV6
extends Node

const CHECK_INTERVAL := 0.20
const ENEMY_SWEEP_INTERVAL := 1.25
const MAX_LAND_VELOCITY := 44.0
const MAX_BOAT_VELOCITY := 34.0
# Limites du grand archipel V7. Les anciennes limites V6 s'arrêtaient à
# x=2750 et immobilisaient le bateau exactement sur la route Forteresse ->
# Île des Gâteaux, à environ 474 m de l'arrivée.
const MIN_WORLD_X := -650.0
const MAX_WORLD_X := 5700.0
const MIN_WORLD_Z := -1500.0
const MAX_WORLD_Z := 1600.0
const WORLD_SWEEP_MARGIN := 420.0
const MIN_WORLD_Y := -24.0
const MAX_WORLD_Y := 320.0

var world: GameWorldV6
var player: PlayerController
var check_timer := 0.0
var enemy_sweep_timer := 0.0
var last_safe_position := Vector3.ZERO
var last_safe_rotation := 0.0
var has_safe_position := false
var recovery_count := 0
var invalid_enemy_count := 0

func configure(target_world: GameWorldV6, target_player: PlayerController) -> void:
	world = target_world
	player = target_player
	_capture_safe_transform(true)
	set_process(true)
	set_meta("runtime_stability_v6", true)
	set_meta("grand_archipelago_bounds_v7", true)
	# Le marqueur V6 reste volontairement présent pour les tests historiques.
	print("CHK_RUNTIME_STABILITY_V6_READY interval=%.2f grand_archipelago_v7=true bounds=[%.0f,%.0f]x[%.0f,%.0f]" % [CHECK_INTERVAL, MIN_WORLD_X, MAX_WORLD_X, MIN_WORLD_Z, MAX_WORLD_Z])

func _process(delta: float) -> void:
	check_timer -= delta
	enemy_sweep_timer -= delta
	if check_timer <= 0.0:
		check_timer = CHECK_INTERVAL
		_run_stability_check()
	if enemy_sweep_timer <= 0.0:
		enemy_sweep_timer = ENEMY_SWEEP_INTERVAL
		_sweep_invalid_enemies()

func reset_safe_checkpoint() -> void:
	has_safe_position = false
	_capture_safe_transform(true)

func run_check_for_test() -> void:
	_run_stability_check()
	_sweep_invalid_enemies()

func _run_stability_check() -> void:
	if not is_instance_valid(world):
		set_process(false)
		return
	if not is_instance_valid(player):
		var candidate = world.get_player() if world.has_method("get_player") else null
		if candidate is PlayerController:
			player = candidate as PlayerController
		else:
			return

	if not _player_state_is_finite():
		_recover_player("état numérique invalide")
		return

	var maximum_velocity := MAX_BOAT_VELOCITY if player.boat_mode else MAX_LAND_VELOCITY
	if player.velocity.length() > maximum_velocity:
		player.velocity = player.velocity.limit_length(maximum_velocity)
	if not is_finite(player.boat_speed):
		player.boat_speed = 0.0
	else:
		player.boat_speed = clampf(player.boat_speed, -8.0, PlayerController.BOAT_MAX_SPEED * 1.08)
	if not is_finite(player.boat_turn_rate):
		player.boat_turn_rate = 0.0
	else:
		player.boat_turn_rate = clampf(player.boat_turn_rate, -2.5, 2.5)

	player.camera_pitch = clampf(player.camera_pitch, -0.62, 0.24)
	player.camera_target_pitch = clampf(player.camera_target_pitch, -0.62, 0.24)
	player.camera_yaw = wrapf(player.camera_yaw, -PI, PI)
	player.camera_target_yaw = wrapf(player.camera_target_yaw, -PI, PI)
	player.rotation.y = wrapf(player.rotation.y, -PI, PI)

	if is_instance_valid(player.assisted_target):
		if player.assisted_target.health <= 0.0 or player.assisted_target.global_position.distance_squared_to(player.global_position) > 6400.0:
			player.assisted_target = null
	elif player.assisted_target != null:
		player.assisted_target = null

	if _position_inside_world(player.global_position):
		_capture_safe_transform(false)
	else:
		_recover_player("hors limites du monde")

func _player_state_is_finite() -> bool:
	return player.global_position.is_finite() \
		and player.velocity.is_finite() \
		and is_finite(player.rotation.y) \
		and is_finite(player.camera_yaw) \
		and is_finite(player.camera_pitch) \
		and is_finite(player.camera_target_yaw) \
		and is_finite(player.camera_target_pitch)

func _position_inside_world(value: Vector3) -> bool:
	return value.is_finite() \
		and value.x >= MIN_WORLD_X \
		and value.x <= MAX_WORLD_X \
		and value.z >= MIN_WORLD_Z \
		and value.z <= MAX_WORLD_Z \
		and value.y >= MIN_WORLD_Y \
		and value.y <= MAX_WORLD_Y

func _capture_safe_transform(force: bool) -> void:
	if not is_instance_valid(player) or not _position_inside_world(player.global_position):
		return
	if not force and not player.boat_mode and not player.is_on_floor():
		return
	last_safe_position = player.global_position
	last_safe_rotation = player.rotation.y
	has_safe_position = true

func _recover_player(reason: String) -> void:
	if not is_instance_valid(player):
		return
	var recovery_position := last_safe_position if has_safe_position else _zone_spawn()
	if not _position_inside_world(recovery_position):
		recovery_position = _zone_spawn()
	player.global_position = recovery_position
	player.velocity = Vector3.ZERO
	player.rotation.y = last_safe_rotation if is_finite(last_safe_rotation) else 0.0
	player.camera_yaw = player.rotation.y
	player.camera_target_yaw = player.rotation.y
	player.camera_pitch = PlayerController.BOAT_CAMERA_REST_PITCH if player.boat_mode else -0.14
	player.camera_target_pitch = player.camera_pitch
	player.boat_speed = 0.0
	player.boat_turn_rate = 0.0
	player.attack_lunge_time = 0.0
	player.dodge_time = 0.0
	player.assisted_target = null
	player.invulnerability = maxf(player.invulnerability, 1.0)
	if player.has_method("_snap_camera_to_player"):
		player.call("_snap_camera_to_player")
	recovery_count += 1
	print("CHK_RUNTIME_RECOVERY_V7 reason=%s count=%d position=%s" % [reason, recovery_count, str(recovery_position)])

func _zone_spawn() -> Vector3:
	if is_instance_valid(world) and not world.zones_v5.is_empty():
		var zone_index := clampi(world.current_zone, 0, world.zones_v5.size() - 1)
		return Vector3(world.zones_v5[zone_index].get("spawn", Vector3(0.0, 8.0, 0.0)))
	return Vector3(0.0, 8.0, 0.0)

func _sweep_invalid_enemies() -> void:
	if not is_instance_valid(player):
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var actor := node as Node3D
		var outside_extended_world := actor.global_position.x < MIN_WORLD_X - WORLD_SWEEP_MARGIN \
			or actor.global_position.x > MAX_WORLD_X + WORLD_SWEEP_MARGIN \
			or actor.global_position.z < MIN_WORLD_Z - WORLD_SWEEP_MARGIN \
			or actor.global_position.z > MAX_WORLD_Z + WORLD_SWEEP_MARGIN
		if not actor.global_position.is_finite() or outside_extended_world:
			if player.assisted_target == node:
				player.assisted_target = null
			node.queue_free()
			invalid_enemy_count += 1
