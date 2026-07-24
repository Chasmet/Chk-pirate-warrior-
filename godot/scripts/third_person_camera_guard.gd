extends Node

const LAND_DISTANCE := 6.15
const BOAT_DISTANCE := 17.8
const LAND_MIN_HEIGHT := 1.35
const BOAT_MIN_WORLD_HEIGHT := 3.8
const BOAT_REAR_QUARTER_BIAS := 0.34

var player: PlayerController
var player_logged := false
var land_ready_logged := false
var boat_ready_logged := false
var was_boat_mode := false
var sail_parts: Array[GeometryInstance3D] = []

func _ready() -> void:
	process_priority = 1700
	set_process(true)

func _process(delta: float) -> void:
	_enforce_camera(delta)

func _enforce_camera(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
		land_ready_logged = false
		boat_ready_logged = false
		was_boat_mode = false
		sail_parts.clear()
		if not is_instance_valid(player):
			return
		if not player_logged:
			player_logged = true
			print("CHK_CAMERA_GUARD_PLAYER_FOUND name=%s" % player.name)

	if not is_instance_valid(player.camera_pivot) or not is_instance_valid(player.camera_arm) or not is_instance_valid(player.camera):
		return

	player.camera.current = true
	player.camera.top_level = true
	player.camera.near = 0.10
	player.camera.far = 1500.0
	player.camera_arm.collision_mask = 0

	if player.boat_mode:
		_update_boat_camera(delta, not was_boat_mode)
	else:
		_update_land_camera(delta, was_boat_mode)
	was_boat_mode = player.boat_mode

func _update_land_camera(delta: float, snap_now: bool) -> void:
	var hero_height := float(HeroFactory.HEROES[player.hero_id]["height"])
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var speed_ratio := clampf(speed / maxf(player._movement_speed(), 0.1), 0.0, 1.0)
	var look_ahead := Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.035
	var anchor := player.global_position + Vector3(0.0, hero_height * 0.58 + 0.12, 0.0) + look_ahead
	var pitch := clampf(player.camera_pitch, -0.50, 0.16)
	var distance := lerpf(LAND_DISTANCE, LAND_DISTANCE + 0.45, speed_ratio)
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := LAND_MIN_HEIGHT - sin(pitch) * distance
	var orbit := Basis(Vector3.UP, player.camera_yaw)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * 0.48
	desired_position = _collision_safe_position(anchor, desired_position, 2.75)

	if snap_now or player.camera.global_position.distance_to(desired_position) > 24.0:
		player.camera.global_position = desired_position
	else:
		player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-13.5 * delta))
	player.camera.look_at(anchor + Vector3.UP * 0.10, Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(59.0, 63.0, speed_ratio), 1.0 - exp(-7.5 * delta))
	player.camera_arm.spring_length = distance
	_force_original_hero_visible(false)
	_restore_sails()

	var camera_distance := player.camera.global_position.distance_to(player.global_position)
	if not land_ready_logged and camera_distance > 5.2 and camera_distance < 7.0:
		land_ready_logged = true
		print("CHK_TRUE_THIRD_PERSON_READY distance=%.2f orbit360=1" % camera_distance)

func _update_boat_camera(delta: float, snap_now: bool) -> void:
	if sail_parts.is_empty():
		_cache_sails(player.boat_visual)
	_restore_sails()

	var velocity_flat := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var speed_ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var look_ahead := velocity_flat * 0.09
	var anchor := player.global_position + Vector3(0.0, 2.42, 0.18) + look_ahead

	# Vue arrière trois-quarts par défaut : la voile ne cache plus la route et
	# le stick caméra conserve une orbite complète autour du navire.
	var camera_heading := player.camera_yaw + BOAT_REAR_QUARTER_BIAS
	var pitch := clampf(player.camera_pitch, -0.48, -0.04)
	var distance := lerpf(BOAT_DISTANCE, BOAT_DISTANCE + 2.2, speed_ratio)
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := 2.80 - sin(pitch) * 3.15 + speed_ratio * 0.40
	var orbit := Basis(Vector3.UP, camera_heading)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var shoulder_offset := lerpf(1.45, 1.90, speed_ratio)
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * shoulder_offset
	desired_position.y = maxf(desired_position.y, PlayerController.BOAT_WATERLINE + BOAT_MIN_WORLD_HEIGHT)
	desired_position = _collision_safe_position(anchor, desired_position, 7.5)
	desired_position.y = maxf(desired_position.y, PlayerController.BOAT_WATERLINE + BOAT_MIN_WORLD_HEIGHT)

	if snap_now or player.camera.global_position.distance_to(desired_position) > 38.0:
		player.camera.global_position = desired_position
	else:
		player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-10.5 * delta))
	player.camera.look_at(anchor + velocity_flat * 0.07 + Vector3(0.0, -0.18, -0.45), Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(59.0, 65.0, speed_ratio), 1.0 - exp(-7.0 * delta))
	player.camera_arm.spring_length = distance
	_force_original_hero_visible(true)

	var camera_distance := player.camera.global_position.distance_to(player.global_position)
	if not boat_ready_logged and camera_distance > 14.0:
		boat_ready_logged = true
		print("CHK_BOAT_THIRD_PERSON_READY distance=%.2f full_ship=1 pilot_visible=1 rear_quarter=1" % camera_distance)

func _collision_safe_position(anchor: Vector3, desired_position: Vector3, minimum_distance: float) -> Vector3:
	if not is_instance_valid(player) or player.get_world_3d() == null:
		return desired_position
	var query := PhysicsRayQueryParameters3D.create(anchor, desired_position)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	query.collision_mask = 1
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return desired_position
	var hit_position: Vector3 = hit.get("position", desired_position)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	var corrected := hit_position + hit_normal * 0.42
	var offset := corrected - anchor
	if offset.length() < minimum_distance:
		corrected = anchor + offset.normalized() * minimum_distance if offset.length_squared() > 0.001 else desired_position
	return corrected

func _force_original_hero_visible(on_boat: bool) -> void:
	if not is_instance_valid(player.hero_visual):
		return
	player.hero_visual.visible = true
	if on_boat:
		player.hero_visual.position = player.hero_visual.position.lerp(Vector3(0.0, 0.72, 0.18), 0.35)
	var sprite := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	var profile: Dictionary = HeroFactory.HEROES[player.hero_id]
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.no_depth_test = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.04
	sprite.render_priority = 8
	sprite.pixel_size = float(profile["pixel_size"])

func _cache_sails(root: Node) -> void:
	if not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			var label := String(geometry.name)
			if label.contains("Voile") or label.contains("Bande") or label.contains("Emblème") or label.contains("Pavillon"):
				sail_parts.append(geometry)
		_cache_sails(child)

func _restore_sails() -> void:
	for part in sail_parts:
		if is_instance_valid(part):
			part.visible = true
			part.transparency = 0.0

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
