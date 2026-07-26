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
var ground_shadow: MeshInstance3D
var rng := RandomNumberGenerator.new()
var visual_height := 1.80
var power_id := "melee"

func configure_crew(data: Dictionary, player: PlayerController, initial_attitude: String, seed_value: int) -> void:
	member_profile = data.duplicate(true)
	visual_height = clampf(float(data.get("height", 1.80)), 0.80, 2.60)
	power_id = String(data.get("power", "melee"))
	rng.seed = seed_value
	var combat_profile := {
		"id":"crew_%s_%s" % [String(data.get("crew_id", "crew")), String(data.get("id", "member"))],
		"name":String(data.get("name", "Pirate itinérant")),
		"health":165.0 if String(data.get("role", "")) == "capitaine" else 98.0,
		"speed":4.25,
		"range":_signature_range(),
		"damage":16.0 if String(data.get("role", "")) == "capitaine" else 13.0,
		"xp":48,
		"coins":26,
		"difficulty":"intermediaire",
		"boss":false
	}
	super.configure(combat_profile, player)
	name = "Équipage_%s_%s" % [String(data.get("crew_id", "crew")), String(data.get("id", "member"))]
	_build_collision_v5()
	_build_sprite_v5()
	_build_ground_shadow_v5()
	set_attitude(initial_attitude)
	set_meta("crew_id", data.get("crew_id", ""))
	set_meta("crew_name", data.get("crew_name", ""))
	set_meta("member_name", data.get("name", ""))
	set_meta("role", data.get("role", ""))
	set_meta("signature_power", power_id)
	set_meta("visual_pipeline", "hero_style_25d_in_3d")

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

func _start_attack() -> void:
	attack_windup = _signature_windup()
	attack_cooldown = _signature_cooldown()
	velocity.x = 0.0
	velocity.z = 0.0
	_update_attack_marker(true)

func _finish_attack(distance: float) -> void:
	_update_attack_marker(false)
	if _is_healing_power():
		health = minf(max_health, health + 18.0)
		_spawn_signature_effect(global_position)
		return
	if not is_instance_valid(target) or distance > _signature_range() + 0.85:
		return
	var forward := target.global_position - global_position
	forward.y = 0.0
	if forward.length_squared() > 0.01:
		forward = forward.normalized()
	var damage := attack_damage * _signature_damage_multiplier()
	player_hit.emit(damage)
	velocity += forward * _signature_knockback()
	_spawn_signature_effect(target.global_position)

func _process_allied(delta: float) -> void:
	var enemy := _nearest_regular_enemy(14.0)
	if is_instance_valid(enemy):
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		var desired_range := maxf(2.5, _signature_range() * 0.80)
		if offset.length() > desired_range:
			_move_flat(offset.normalized(), speed * 1.05, delta)
		else:
			_move_flat(Vector3.ZERO, 0.0, delta)
			if support_cooldown <= 0.0:
				_use_signature_on_enemy(enemy)
				support_cooldown = _signature_cooldown()
		return
	if _is_healing_power() and support_cooldown <= 0.0 and is_instance_valid(target):
		var player_target := target as PlayerController
		if player_target.health < player_target.max_health * 0.72:
			_heal_player(player_target)
			support_cooldown = 6.0
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
	capsule.radius = clampf(visual_height * 0.24, 0.30, 0.62)
	capsule.height = maxf(visual_height - capsule.radius * 2.0, 0.45)
	collision.shape = capsule
	collision.position.y = visual_height * 0.50
	add_child(collision)

func _build_sprite_v5() -> void:
	sprite = Sprite3D.new()
	sprite.name = "Personnage25DHérosStyle"
	sprite.texture = Crew25DAssetFactoryV5.texture_for(member_profile)
	sprite.hframes = Crew25DAssetFactoryV5.FRAME_COUNT
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = visual_height / Crew25DAssetFactoryV5.CONTENT_HEIGHT
	sprite.position.y = visual_height * 0.50
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.double_sided = true
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.025
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.render_priority = 7
	add_child(sprite)

func _build_ground_shadow_v5() -> void:
	ground_shadow = MeshInstance3D.new()
	ground_shadow.name = "OmbreAuSolÉquipage"
	var mesh := CylinderMesh.new()
	mesh.top_radius = clampf(visual_height * 0.28, 0.28, 0.72)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 28
	ground_shadow.mesh = mesh
	ground_shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.005, 0.008, 0.012, 0.43)
	ground_shadow.material_override = material
	add_child(ground_shadow)

func _update_sprite_motion() -> void:
	if not is_instance_valid(sprite):
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(horizontal_speed / maxf(speed, 0.1), 0.0, 1.0)
	if attack_windup > 0.0 or support_cooldown > _signature_cooldown() * 0.72:
		sprite.frame = 3
	elif speed_ratio > 0.12:
		sprite.frame = 1 + int(floor(local_time * 7.2)) % 2
	else:
		sprite.frame = 0
	sprite.position.y = visual_height * 0.50 + absf(sin(local_time * 7.0)) * 0.028 * speed_ratio

func _use_signature_on_enemy(primary: EnemyAI) -> void:
	if not is_instance_valid(primary):
		return
	if _is_healing_power():
		health = minf(max_health, health + 22.0)
		_spawn_signature_effect(global_position)
		return
	var direction := primary.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
	var damage := attack_damage * _signature_damage_multiplier() * 1.22
	var radius := _signature_radius()
	if radius > 0.1:
		for node in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(node) or not node is EnemyAI or node is RoamingCrewMemberV5:
				continue
			var candidate := node as EnemyAI
			if candidate.health > 0.0 and candidate.global_position.distance_to(primary.global_position) <= radius:
				candidate.take_damage(damage, direction * _signature_knockback())
	else:
		primary.take_damage(damage, direction * _signature_knockback())
	if power_id == "grasp_bind":
		primary.hit_stun = maxf(primary.hit_stun, 0.85)
	_spawn_signature_effect(primary.global_position)

func _heal_player(player_target: PlayerController) -> void:
	var amount := 20.0 if power_id == "guard_heal" else 16.0
	player_target.health = minf(player_target.max_health, player_target.health + amount)
	health = minf(max_health, health + amount * 0.55)
	_spawn_signature_effect(player_target.global_position)

func _signature_range() -> float:
	if power_id in ["energy_beam", "sniper_seed", "thunder_cloud", "rifle_burst", "rapid_shot", "sniper_shot"]:
		return 9.5
	if power_id in ["haki_wave", "shock_roar", "water_palm", "elastic_burst"]:
		return 4.6
	return 2.7

func _signature_radius() -> float:
	if power_id in ["haki_wave", "shock_roar"]:
		return 4.8
	if power_id in ["ground_smash", "water_palm", "thunder_cloud", "elastic_burst"]:
		return 3.2
	if power_id in ["triple_slash", "dual_slash", "ice_slash", "flame_kick"]:
		return 2.2
	return 0.0

func _signature_windup() -> float:
	if power_id in ["sniper_seed", "sniper_shot", "energy_beam", "haki_wave"]:
		return 0.62
	if power_id in ["rapid_shot", "acrobat_rush"]:
		return 0.28
	return 0.42

func _signature_cooldown() -> float:
	if _is_healing_power():
		return 5.5
	if power_id in ["haki_wave", "energy_beam", "thunder_cloud", "ground_smash"]:
		return 2.25
	if power_id in ["rapid_shot", "acrobat_rush"]:
		return 0.92
	return 1.35

func _signature_damage_multiplier() -> float:
	if power_id in ["haki_wave", "energy_beam", "ground_smash", "triple_slash"]:
		return 1.55
	if power_id in ["thunder_cloud", "water_palm", "flame_kick", "ice_slash", "shock_roar"]:
		return 1.34
	if power_id in ["rapid_shot", "acrobat_rush"]:
		return 0.88
	return 1.12

func _signature_knockback() -> float:
	if power_id in ["haki_wave", "shock_roar", "ground_smash", "water_palm", "elastic_burst"]:
		return 9.0
	return 4.2

func _is_healing_power() -> bool:
	return power_id in ["guard_heal", "support_heal"]

func _power_color() -> Color:
	match power_id:
		"flame_kick":
			return Color("ff6d1f")
		"thunder_cloud", "haki_wave":
			return Color("9a63ff")
		"water_palm":
			return Color("29c9ff")
		"ice_slash":
			return Color("9fe8ff")
		"guard_heal", "support_heal":
			return Color("65f08c")
		"energy_beam", "rifle_burst", "rapid_shot", "sniper_seed", "sniper_shot":
			return Color("ffd34d")
		"grasp_bind":
			return Color("e98cff")
		_:
			return Color("f2f5ff")

func _spawn_signature_effect(target_position: Vector3) -> void:
	var color := _power_color()
	if _is_healing_power() or _signature_radius() > 0.1:
		_spawn_burst(target_position, color, maxf(1.4, _signature_radius()))
	if _signature_range() >= 8.0:
		_spawn_projectile(global_position + Vector3.UP * visual_height * 0.62, target_position + Vector3.UP * 0.9, color)
	elif power_id in ["triple_slash", "dual_slash", "ice_slash", "flame_kick", "sky_kick"]:
		_spawn_slash(target_position + Vector3.UP * 0.9, color)

func _spawn_burst(position: Vector3, color: Color, radius: float) -> void:
	var effect := MeshInstance3D.new()
	effect.name = "PouvoirZone_%s" % power_id
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.035
	mesh.radial_segments = 36
	effect.mesh = mesh
	effect.material_override = _power_material(color, 0.48)
	_effect_parent().add_child(effect)
	effect.global_position = position + Vector3.UP * 0.08
	effect.scale = Vector3(0.18, 1.0, 0.18)
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", Vector3(radius, 1.0, radius), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(effect.queue_free)

func _spawn_projectile(origin: Vector3, destination: Vector3, color: Color) -> void:
	var projectile := MeshInstance3D.new()
	projectile.name = "Projectile_%s" % power_id
	var mesh := SphereMesh.new()
	mesh.radius = 0.20
	mesh.height = 0.40
	projectile.mesh = mesh
	projectile.material_override = _power_material(color, 0.92)
	_effect_parent().add_child(projectile)
	projectile.global_position = origin
	var tween := projectile.create_tween()
	tween.tween_property(projectile, "global_position", destination, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(projectile, "scale", Vector3(2.0, 2.0, 2.0), 0.08)
	tween.tween_callback(projectile.queue_free)

func _spawn_slash(position: Vector3, color: Color) -> void:
	for index in range(3):
		var slash := MeshInstance3D.new()
		slash.name = "Entaille_%s_%d" % [power_id, index]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.055, 1.75, 0.50)
		slash.mesh = mesh
		slash.material_override = _power_material(color, 0.72)
		_effect_parent().add_child(slash)
		slash.global_position = position + Vector3(float(index - 1) * 0.28, 0.0, 0.0)
		slash.rotation = Vector3(0.0, global_rotation.y, -0.65 + float(index) * 0.34)
		slash.scale = Vector3(0.15, 0.15, 0.15)
		var tween := slash.create_tween()
		tween.tween_property(slash, "scale", Vector3.ONE, 0.12)
		tween.tween_interval(0.09)
		tween.tween_callback(slash.queue_free)

func _power_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.8
	return material

func _effect_parent() -> Node:
	if is_instance_valid(get_tree().current_scene):
		return get_tree().current_scene
	return get_parent()
