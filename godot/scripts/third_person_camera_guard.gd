extends Node

# Autorité unique de caméra troisième personne.
# Aucun autre script ne doit déplacer CameraJoueur directement.
const LAND_DISTANCE := 3.05
const LAND_RUN_DISTANCE := 3.40
const BOAT_DISTANCE := 9.8
const BOAT_RUN_DISTANCE := 11.2
const BOAT_REAR_QUARTER_BIAS := 0.22
const LAND_MIN_CLEARANCE := 0.72
const WATER_CAMERA_FLOOR := PlayerController.BOAT_WATERLINE + 1.85
const BOAT_CAMERA_FLOOR := PlayerController.BOAT_WATERLINE + 3.35

var player: PlayerController
var was_boat_mode := false
var player_logged := false

func _ready() -> void:
	process_priority = 1700
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
		if not is_instance_valid(player):
			return
		if not player_logged:
			player_logged = true
			print("CHK_CAMERA_SINGLE_AUTHORITY player=%s" % player.name)

	if not is_instance_valid(player.camera_pivot) or not is_instance_valid(player.camera_arm) or not is_instance_valid(player.camera):
		return

	player.camera.current = true
	player.camera.top_level = true
	player.camera.near = 0.08
	player.camera.far = 1500.0
	player.camera_arm.collision_mask = 1

	if player.boat_mode:
		_update_boat_camera(delta, not was_boat_mode)
	else:
		_update_land_camera(delta, was_boat_mode)
	was_boat_mode = player.boat_mode

func _update_land_camera(delta: float, snap_now: bool) -> void:
	var profile: Dictionary = HeroFactory.HEROES.get(player.hero_id, HeroFactory.HEROES["cheikh"])
	var hero_height := float(profile["height"])
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var speed_ratio := clampf(speed / maxf(player._movement_speed(), 0.1), 0.0, 1.0)
	var distance := lerpf(LAND_DISTANCE, LAND_RUN_DISTANCE, speed_ratio)
	var pitch := clampf(player.camera_pitch, -0.30, 0.06)
	var anchor := player.global_position + Vector3(0.0, hero_height * 0.70, 0.0)
	anchor += Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.010

	var orbit := Basis(Vector3.UP, player.camera_yaw)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := 1.02 - sin(pitch) * distance
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * 0.24
	var minimum_y := maxf(player.global_position.y + LAND_MIN_CLEARANCE, WATER_CAMERA_FLOOR)
	desired_position = _collision_safe_position(anchor, desired_position, minimum_y, 1.65)
	desired_position = _lift_above_surface(desired_position, minimum_y, 0.62)

	_move_camera(desired_position, delta, snap_now, 16.0)
	player.camera.look_at(anchor + Vector3.UP * 0.05, Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(49.0, 52.5, speed_ratio), 1.0 - exp(-9.0 * delta))
	player.camera_arm.spring_length = distance
	_force_hero_visible(false)

func _update_boat_camera(delta: float, snap_now: bool) -> void:
	var speed_ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var distance := lerpf(BOAT_DISTANCE, BOAT_RUN_DISTANCE, speed_ratio)
	var pitch := clampf(player.camera_pitch, -0.34, -0.08)
	var velocity_flat := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var anchor := player.global_position + Vector3(0.0, 2.70, 0.35) + velocity_flat * 0.035
	var camera_heading := player.camera_yaw + BOAT_REAR_QUARTER_BIAS
	var orbit := Basis(Vector3.UP, camera_heading)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := 2.55 - sin(pitch) * 3.6 + speed_ratio * 0.20
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * 0.80
	desired_position = _collision_safe_position(anchor, desired_position, BOAT_CAMERA_FLOOR, 4.0)
	desired_position = _lift_above_surface(desired_position, BOAT_CAMERA_FLOOR, 1.10)

	_move_camera(desired_position, delta, snap_now, 12.0)
	player.camera.look_at(anchor + velocity_flat * 0.025 + Vector3(0.0, -0.12, -0.28), Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(54.0, 58.0, speed_ratio), 1.0 - exp(-8.0 * delta))
	player.camera_arm.spring_length = distance
	_force_hero_visible(true)

func _move_camera(desired_position: Vector3, delta: float, snap_now: bool, smoothing: float) -> void:
	if snap_now or player.camera.global_position.distance_to(desired_position) > 10.0:
		player.camera.global_position = desired_position
	else:
		player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-smoothing * delta))

func _collision_safe_position(anchor: Vector3, desired_position: Vector3, minimum_y: float, minimum_distance: float) -> Vector3:
	var corrected := desired_position
	if not is_instance_valid(player) or player.get_world_3d() == null:
		corrected.y = maxf(corrected.y, minimum_y)
		return corrected

	var query := PhysicsRayQueryParameters3D.create(anchor, desired_position)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	query.collision_mask = 1
	query.hit_from_inside = true
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit.get("position", desired_position)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		corrected = hit_position + hit_normal * 0.42
		var offset := corrected - anchor
		if offset.length() < minimum_distance:
			var safe_direction := (desired_position - anchor).normalized()
			if safe_direction.length_squared() < 0.1:
				safe_direction = Vector3(0.0, 0.25, 1.0).normalized()
			corrected = anchor + safe_direction * minimum_distance
	corrected.y = maxf(corrected.y, minimum_y)
	return corrected

func _lift_above_surface(position: Vector3, minimum_y: float, clearance: float) -> Vector3:
	var corrected := position
	corrected.y = maxf(corrected.y, minimum_y)
	if not is_instance_valid(player) or player.get_world_3d() == null:
		return corrected

	var ray_start := Vector3(position.x, maxf(position.y + 8.0, player.global_position.y + 14.0), position.z)
	var ray_end := Vector3(position.x, minf(position.y - 18.0, player.global_position.y - 10.0), position.z)
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	query.collision_mask = 1
	query.hit_from_inside = true
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var surface_position: Vector3 = hit.get("position", corrected)
		var surface_normal: Vector3 = hit.get("normal", Vector3.UP)
		if surface_normal.y > 0.20:
			corrected.y = maxf(corrected.y, surface_position.y + clearance)
	corrected.y = maxf(corrected.y, minimum_y)
	return corrected

func _force_hero_visible(on_boat: bool) -> void:
	if not is_instance_valid(player.hero_visual):
		return
	player.hero_visual.visible = true
	if on_boat:
		player.hero_visual.position = player.hero_visual.position.lerp(Vector3(0.0, 0.72, 1.48), 0.35)
	var sprite := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	var profile: Dictionary = HeroFactory.HEROES.get(player.hero_id, HeroFactory.HEROES["cheikh"])
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.no_depth_test = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.060
	sprite.render_priority = 8
	sprite.pixel_size = float(profile["pixel_size"])

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
