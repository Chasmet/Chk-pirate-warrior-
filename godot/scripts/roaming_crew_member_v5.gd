class_name RoamingCrewMemberV5
extends EnemyAI

var attitude := "neutral"
var home_position := Vector3.ZERO
var roam_target := Vector3.ZERO
var roam_radius := 16.0
var support_cooldown := 0.0
var local_time := 0.0
var member_profile: Dictionary = {}
var sprite: Sprite3D
var rng := RandomNumberGenerator.new()

func configure_crew(data: Dictionary, player: PlayerController, initial_attitude: String, seed_value: int) -> void:
	member_profile = data.duplicate(true)
	rng.seed = seed_value
	var combat_profile := {
		"id":"crew_%s_%s" % [String(data.get("crew_id", "crew")), String(data.get("id", "member"))],
		"name":String(data.get("name", "Pirate itinérant")),
		"health":150.0 if String(data.get("role", "")) == "capitaine" else 92.0,
		"speed":4.2,
		"range":2.1,
		"damage":14.0,
		"xp":45,
		"coins":24,
		"difficulty":"intermediaire",
		"boss":false
	}
	super.configure(combat_profile, player)
	name = "Équipage_%s_%s" % [String(data.get("crew_id", "crew")), String(data.get("id", "member"))]
	_build_collision_v5()
	_build_sprite_v5()
	set_attitude(initial_attitude)
	set_meta("crew_id", data.get("crew_id", ""))
	set_meta("crew_name", data.get("crew_name", ""))
	set_meta("member_name", data.get("name", ""))
	set_meta("role", data.get("role", ""))

func set_home(value: Vector3) -> void:
	home_position = value
	global_position = value
	_choose_roam_target()

func set_attitude(value: String) -> void:
	attitude = value if value in ["hostile", "allied", "neutral"] else "neutral"
	if attitude == "hostile":
		if not is_in_group("enemies"):
			add_to_group("enemies")
		remove_from_group("crew_allies")
		remove_from_group("crew_neutral")
	elif attitude == "allied":
		remove_from_group("enemies")
		add_to_group("crew_allies")
		remove_from_group("crew_neutral")
	else:
		remove_from_group("enemies")
		remove_from_group("crew_allies")
		add_to_group("crew_neutral")
	if is_instance_valid(health_bar_root):
		health_bar_root.visible = attitude == "hostile" and health < max_health
	if is_instance_valid(attack_marker):
		attack_marker.visible = false
	set_meta("attitude", attitude)

func _physics_process(delta: float) -> void:
	local_time += delta
	support_cooldown = maxf(0.0, support_cooldown - delta)
	if attitude == "hostile":
		super._physics_process(delta)
		_update_sprite_motion()
		return
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	if attitude == "allied":
		_process_allied(delta)
	else:
		_process_neutral(delta)
	move_and_slide()
	_update_sprite_motion()

func _process_allied(delta: float) -> void:
	var enemy := _nearest_regular_enemy(11.0)
	if is_instance_valid(enemy):
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() > 3.0:
			_move_flat(offset.normalized(), speed * 1.05, delta)
		else:
			_move_flat(Vector3.ZERO, 0.0, delta)
			if support_cooldown <= 0.0:
				enemy.take_damage(18.0, offset.normalized() * 3.5)
				support_cooldown = 1.05
		return
	var follow_offset := target.global_position - global_position
	follow_offset.y = 0.0
	var desired_distance := 5.5 + float(abs(String(member_profile.get("id", "x")).hash()) % 5)
	if follow_offset.length() > desired_distance + 1.2:
		_move_flat(follow_offset.normalized(), speed, delta)
	elif follow_offset.length() < desired_distance - 1.0:
		_move_flat(-follow_offset.normalized(), speed * 0.45, delta)
	else:
		_move_flat(Vector3.ZERO, 0.0, delta)

func _process_neutral(delta: float) -> void:
	if global_position.distance_to(roam_target) < 1.1:
		_choose_roam_target()
	var offset := roam_target - global_position
	offset.y = 0.0
	if offset.length_squared() > 0.2:
		_move_flat(offset.normalized(), speed * 0.58, delta)
	else:
		_move_flat(Vector3.ZERO, 0.0, delta)

func _move_flat(direction: Vector3, target_speed: float, delta: float) -> void:
	var desired := direction * target_speed
	velocity.x = move_toward(velocity.x, desired.x, 10.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z, 10.0 * delta)
	if direction.length_squared() > 0.02:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-7.0 * delta))

func _nearest_regular_enemy(radius: float) -> EnemyAI:
	var result: EnemyAI
	var best := radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not is_instance_valid(node) or not node is EnemyAI:
			continue
		if node is RoamingCrewMemberV5:
			continue
		var candidate := node as EnemyAI
		if candidate.health <= 0.0:
			continue
		var distance := candidate.global_position.distance_to(global_position)
		if distance < best:
			best = distance
			result = candidate
	return result

func _choose_roam_target() -> void:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(roam_radius * 0.25, roam_radius)
	roam_target = home_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	roam_target.y = home_position.y

func _build_collision_v5() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionÉquipageV5"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.42
	collision.shape = capsule
	collision.position.y = 0.94
	add_child(collision)

func _build_sprite_v5() -> void:
	sprite = Sprite3D.new()
	sprite.name = "Personnage25DOriginal"
	sprite.texture = Crew25DAssetFactoryV5.texture_for(member_profile)
	sprite.pixel_size = 0.0125
	sprite.position.y = 1.62
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(sprite)

func _update_sprite_motion() -> void:
	if not is_instance_valid(sprite):
		return
	var speed_ratio := clampf(Vector2(velocity.x, velocity.z).length() / maxf(speed, 0.1), 0.0, 1.0)
	sprite.position.y = 1.62 + absf(sin(local_time * 7.0)) * 0.055 * speed_ratio
