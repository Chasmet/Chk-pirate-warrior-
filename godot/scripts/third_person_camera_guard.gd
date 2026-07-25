extends Node

# Caméra réellement proche pour les héros 2D dans le monde 3D.
const LAND_DISTANCE := 3.25
const LAND_RUN_DISTANCE := 3.65
const BOAT_DISTANCE := 11.5
const BOAT_RUN_DISTANCE := 13.0
const BOAT_REAR_QUARTER_BIAS := 0.26

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
			print("CHK_CLOSE_CAMERA_PLAYER_FOUND name=%s" % player.name)

	if not is_instance_valid(player.camera_pivot) or not is_instance_valid(player.camera_arm) or not is_instance_valid(player.camera):
		return

	player.camera.current = true
	player.camera.top_level = true
	player.camera.near = 0.05
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
	var pitch := clampf(player.camera_pitch, -0.38, 0.10)
	var anchor := player.global_position + Vector3(0.0, hero_height * 0.72, 0.0)
	anchor += Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.014

	var orbit := Basis(Vector3.UP, player.camera_yaw)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := 0.78 - sin(pitch) * distance
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * 0.32
	desired_position.y = maxf(desired_position.y, player.global_position.y + 0.68)
	desired_position = _collision_safe_position(anchor, desired_position)
	desired_position.y = maxf(desired_position.y, player.global_position.y + 0.58)

	_move_camera(desired_position, delta, snap_now, 14.0)
	player.camera.look_at(anchor + Vector3.UP * 0.08, Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(52.0, 56.0, speed_ratio), 1.0 - exp(-8.0 * delta))
	player.camera_arm.spring_length = distance
	_force_hero_visible(false)

func _update_boat_camera(delta: float, snap_now: bool) -> void:
	var speed_ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var distance := lerpf(BOAT_DISTANCE, BOAT_RUN_DISTANCE, speed_ratio)
	var pitch := clampf(player.camera_pitch, -0.40, -0.08)
	var velocity_flat := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var anchor := player.global_position + Vector3(0.0, 2.55, 0.28) + velocity_flat * 0.045
	var camera_heading := player.camera_yaw + BOAT_REAR_QUARTER_BIAS
	var orbit := Basis(Vector3.UP, camera_heading)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var horizontal_distance := cos(pitch) * distance
	var vertical_offset := 2.15 - sin(pitch) * 4.2 + speed_ratio * 0.25
	var desired_position := anchor + back * horizontal_distance + Vector3.UP * vertical_offset + right * 0.95
	desired_position.y = maxf(desired_position.y, PlayerController.BOAT_WATERLINE + 2.8)
	desired_position = _collision_safe_position(anchor, desired_position)
	desired_position.y = maxf(desired_position.y, PlayerController.BOAT_WATERLINE + 2.6)

	_move_camera(desired_position, delta, snap_now, 11.0)
	player.camera.look_at(anchor + velocity_flat * 0.035 + Vector3(0.0, -0.18, -0.35), Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(56.0, 61.0, speed_ratio), 1.0 - exp(-7.0 * delta))
	player.camera_arm.spring_length = distance
	_force_hero_visible(true)

func _move_camera(desired_position: Vector3, delta: float, snap_now: bool, smoothing: float) -> void:
	if snap_now or player.camera.global_position.distance_to(desired_position) > 16.0:
		player.camera.global_position = desired_position
	else:
		player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-smoothing * delta))

func _collision_safe_position(anchor: Vector3, desired_position: Vector3) -> Vector3:
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
	var corrected := hit_position + hit_normal * 0.28
	# On ne repousse jamais la caméra derrière l'obstacle : elle se rapproche
	# temporairement du héros au lieu de traverser un arbre, un mur ou le sol.
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
	sprite.alpha_scissor_threshold = 0.055
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
