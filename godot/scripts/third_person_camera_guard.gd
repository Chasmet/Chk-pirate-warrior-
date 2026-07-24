extends Node

const LAND_LENGTH := 6.35
const BOAT_LENGTH := 13.8

var player: PlayerController
var player_logged := false
var land_ready_logged := false
var boat_ready_logged := false
var sail_parts: Array[GeometryInstance3D] = []

func _ready() -> void:
	process_priority = 1000
	process_physics_priority = 1000
	set_process(true)
	set_physics_process(true)

func _process(delta: float) -> void:
	_enforce_camera(delta)

func _physics_process(delta: float) -> void:
	_enforce_camera(delta)

func _enforce_camera(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player()
		land_ready_logged = false
		boat_ready_logged = false
		sail_parts.clear()
		if not is_instance_valid(player):
			return
		if not player_logged:
			player_logged = true
			print("CHK_CAMERA_GUARD_PLAYER_FOUND name=%s" % player.name)
	if not is_instance_valid(player.camera_pivot) or not is_instance_valid(player.camera_arm) or not is_instance_valid(player.camera):
		return

	player.camera.current = true
	player.camera.near = 0.10
	player.camera.top_level = true
	player.camera_arm.collision_mask = 0
	if player.boat_mode:
		_update_boat_camera(delta)
	else:
		_update_land_camera(delta)

func _update_land_camera(delta: float) -> void:
	var hero_height := float(HeroFactory.HEROES[player.hero_id]["height"])
	var look_ahead := Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.026
	var anchor := player.global_position + Vector3(0.0, hero_height * 0.62, 0.0) + look_ahead
	var orbit := Basis(Vector3.UP, player.camera_yaw)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var desired_position := anchor + back * LAND_LENGTH + Vector3.UP * 1.52 + right * 0.48
	player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-14.0 * delta))
	player.camera.look_at(anchor, Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, 60.0, 1.0 - exp(-8.0 * delta))
	player.camera_arm.spring_length = LAND_LENGTH
	_force_original_hero_visible()
	_restore_sails()

	var distance := player.camera.global_position.distance_to(player.global_position)
	if not land_ready_logged and distance > 5.6:
		land_ready_logged = true
		print("CHK_TRUE_THIRD_PERSON_READY distance=%.2f" % distance)

func _update_boat_camera(delta: float) -> void:
	if sail_parts.is_empty():
		_cache_sails()
	var velocity_flat := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var look_ahead := velocity_flat * 0.075
	var anchor := player.global_position + Vector3(0.0, 2.15, 0.0) + look_ahead
	var orbit := Basis(Vector3.UP, player.camera_yaw)
	var back := orbit.z.normalized()
	var right := orbit.x.normalized()
	var speed_ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var dynamic_length := lerpf(BOAT_LENGTH, BOAT_LENGTH + 2.2, speed_ratio)
	var desired_position := anchor + back * dynamic_length + Vector3.UP * lerpf(4.6, 5.5, speed_ratio) + right * 0.72
	player.camera.global_position = player.camera.global_position.lerp(desired_position, 1.0 - exp(-11.5 * delta))
	player.camera.look_at(anchor + velocity_flat * 0.08, Vector3.UP)
	player.camera.fov = lerpf(player.camera.fov, lerpf(61.0, 65.0, speed_ratio), 1.0 - exp(-8.0 * delta))
	player.camera_arm.spring_length = dynamic_length
	_force_original_hero_visible()

	# Les surfaces de voile centrales restent masquées uniquement pendant le
	# pilotage pour conserver une vue extérieure claire du pont et de la coque.
	for part in sail_parts:
		if is_instance_valid(part):
			part.visible = false

	var distance := player.camera.global_position.distance_to(player.global_position)
	if not boat_ready_logged and distance > 12.0:
		boat_ready_logged = true
		print("CHK_BOAT_THIRD_PERSON_READY distance=%.2f" % distance)

func _force_original_hero_visible() -> void:
	if not is_instance_valid(player.hero_visual):
		return
	player.hero_visual.visible = true
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

func _find_player() -> PlayerController:
	var named := get_tree().root.find_child("ÉquipageQuinet", true, false)
	if named is PlayerController:
		return named as PlayerController
	return _find_player_recursive(get_tree().root)

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
