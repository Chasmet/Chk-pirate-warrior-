extends Node

const LAND_LENGTH := 6.40
const LAND_PITCH_MIN := -0.48
const LAND_PITCH_MAX := 0.10
const BOAT_LENGTH := 18.50
const BOAT_PITCH_MIN := -0.58
const BOAT_PITCH_MAX := -0.30

var player: PlayerController
var player_logged := false
var land_ready_logged := false
var boat_ready_logged := false
var sail_parts: Array[GeometryInstance3D] = []

func _ready() -> void:
	# Le garde-fou doit passer après le contrôleur du joueur afin que celui-ci
	# ne puisse jamais ramener la caméra dans le personnage ou dans le navire.
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
	# Le SpringArm provoquait les passages en vue subjective en se rétractant
	# contre le relief, le ponton ou le navire. Il est neutralisé ici ; une vraie
	# occultation progressive des obstacles sera ajoutée après stabilisation.
	player.camera_arm.collision_mask = 0
	if player.boat_mode:
		_update_boat_camera(delta)
	else:
		_update_land_camera(delta)

func _update_land_camera(delta: float) -> void:
	var hero_height := float(HeroFactory.HEROES[player.hero_id]["height"])
	var look_ahead := Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.025
	var anchor := player.global_position + Vector3(0.0, hero_height * 0.72 + 0.16, 0.0) + look_ahead
	player.camera_pivot.global_position = player.camera_pivot.global_position.lerp(anchor, 1.0 - exp(-14.0 * delta))
	player.camera_target_pitch = clampf(player.camera_target_pitch, LAND_PITCH_MIN, LAND_PITCH_MAX)
	player.camera_pitch = clampf(player.camera_pitch, LAND_PITCH_MIN, LAND_PITCH_MAX)
	player.camera_pivot.rotation = Vector3(player.camera_pitch, player.camera_yaw, 0.0)
	player.camera_arm.spring_length = lerpf(player.camera_arm.spring_length, LAND_LENGTH, 1.0 - exp(-14.0 * delta))
	player.camera.position = player.camera.position.lerp(Vector3(0.78, 0.16, 0.0), 1.0 - exp(-12.0 * delta))
	player.camera.fov = lerpf(player.camera.fov, 61.0, 1.0 - exp(-8.0 * delta))
	_force_original_hero_visible()
	_restore_sails()

	var distance := player.camera.global_position.distance_to(player.global_position)
	if not land_ready_logged and distance > 5.55:
		land_ready_logged = true
		print("CHK_TRUE_THIRD_PERSON_READY distance=%.2f" % distance)

func _update_boat_camera(delta: float) -> void:
	if sail_parts.is_empty():
		_cache_sails()
	var look_ahead := Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.045
	var anchor := player.global_position + Vector3(0.0, 5.65, 0.0) + look_ahead
	player.camera_pivot.global_position = player.camera_pivot.global_position.lerp(anchor, 1.0 - exp(-12.0 * delta))
	player.camera_target_pitch = clampf(player.camera_target_pitch, BOAT_PITCH_MIN, BOAT_PITCH_MAX)
	player.camera_pitch = clampf(player.camera_pitch, BOAT_PITCH_MIN, BOAT_PITCH_MAX)
	player.camera_pivot.rotation = Vector3(player.camera_pitch, player.camera_yaw, 0.0)
	player.camera_arm.spring_length = lerpf(player.camera_arm.spring_length, BOAT_LENGTH, 1.0 - exp(-12.0 * delta))
	player.camera.position = player.camera.position.lerp(Vector3(1.10, 0.42, 0.0), 1.0 - exp(-10.0 * delta))
	player.camera.fov = lerpf(player.camera.fov, 67.0, 1.0 - exp(-8.0 * delta))
	_force_original_hero_visible()
	# Les grandes voiles opaques masquaient totalement la vue Android au quai.
	# On conserve le mât et la vergue, mais les surfaces de voile sont masquées
	# dans la caméra de pilotage jusqu’à l’ajout d’un matériau semi-transparent.
	for part in sail_parts:
		if is_instance_valid(part):
			part.visible = false

	var distance := player.camera.global_position.distance_to(player.global_position)
	if not boat_ready_logged and distance > 15.0:
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
