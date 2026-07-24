extends Node

const LAND_LENGTH := 5.9
const LAND_PITCH := -0.20
const LAND_MIN_HIT := 3.9
const BOAT_LENGTH := 15.2
const BOAT_PITCH := -0.38
const BOAT_MIN_HIT := 9.5

var player: PlayerController
var bypass_time := 0.0
var ready_logged := false
var sail_parts: Array[GeometryInstance3D] = []

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player(get_tree().root)
		ready_logged = false
		sail_parts.clear()
		if not is_instance_valid(player):
			return
	if not is_instance_valid(player.camera_arm) or not is_instance_valid(player.camera):
		return

	player.camera.current = true
	player.camera.near = 0.10
	if player.boat_mode:
		_update_boat_camera(delta)
	else:
		_update_land_camera(delta)

func _update_land_camera(delta: float) -> void:
	bypass_time = maxf(0.0, bypass_time - delta)
	var hit_length := player.camera_arm.get_hit_length()
	if hit_length < LAND_MIN_HIT:
		bypass_time = 0.45
		player.camera_target_pitch = minf(player.camera_target_pitch, LAND_PITCH)
	player.camera_arm.collision_mask = 0 if bypass_time > 0.0 else 1
	player.camera_arm.spring_length = maxf(player.camera_arm.spring_length, LAND_LENGTH)
	player.camera.position = player.camera.position.lerp(Vector3(0.72, 0.18, 0.0), 1.0 - exp(-10.0 * delta))
	player.camera.fov = maxf(player.camera.fov, 60.0)
	_restore_sails()
	if not ready_logged and player.camera.global_position.distance_to(player.global_position) > 4.5:
		ready_logged = true
		print("CHK_TRUE_THIRD_PERSON_READY distance=%.2f" % player.camera.global_position.distance_to(player.global_position))

func _update_boat_camera(delta: float) -> void:
	if sail_parts.is_empty():
		_cache_sails()
	var hit_length := player.camera_arm.get_hit_length()
	if hit_length < BOAT_MIN_HIT or absf(player.boat_speed) < 2.8:
		bypass_time = 1.3
	else:
		bypass_time = maxf(0.0, bypass_time - delta)
	player.camera_arm.collision_mask = 0 if bypass_time > 0.0 else 1
	player.camera_arm.spring_length = maxf(player.camera_arm.spring_length, BOAT_LENGTH)
	player.camera_target_pitch = minf(player.camera_target_pitch, BOAT_PITCH)
	player.camera.position = player.camera.position.lerp(Vector3(1.05, 0.38, 0.0), 1.0 - exp(-8.0 * delta))
	player.camera.fov = maxf(player.camera.fov, 66.0)
	var sail_center := player.boat_visual.to_global(Vector3(0.0, 4.8, -0.48)) if is_instance_valid(player.boat_visual) else player.global_position
	var hide_sail := player.camera.global_position.distance_to(sail_center) < 6.4 or hit_length < 7.2
	for part in sail_parts:
		if is_instance_valid(part):
			part.visible = not hide_sail

func _cache_sails() -> void:
	if not is_instance_valid(player.boat_visual):
		return
	var root := player.boat_visual.get_node_or_null("Voilure") as Node3D
	if root == null:
		return
	for child in root.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			var label := String(geometry.name)
			if label.begins_with("Voile") or label.begins_with("BandeRouge") or label.begins_with("Emblème"):
				sail_parts.append(geometry)

func _restore_sails() -> void:
	for part in sail_parts:
		if is_instance_valid(part):
			part.visible = true

func _find_player(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player(child)
		if is_instance_valid(found):
			return found
	return null
