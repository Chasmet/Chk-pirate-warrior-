class_name PlayerController
extends CharacterBody3D

signal stats_changed(health: float, max_health: float, energy: float, aura: float, level: int, xp: int, coins: int)
signal hero_changed(hero_id: String, display_name: String)
signal hero_pose_changed(hero_id: String, frame: int)
signal hero_view_changed(hero_id: String, frame: int, front_view: bool)
signal boat_mode_changed(active: bool)
signal boat_steering_changed(hero_id: String, steering: float, throttle: float, speed_ratio: float)
signal player_defeated
signal enemy_defeated(profile: Dictionary)

const HERO_ORDER := ["cheikh", "yvane", "nelvyn"]

var save_data: Dictionary = {}
var hero_id := "cheikh"
var hero_visual: CharacterBody3D
var move_input := Vector2.ZERO
var camera_stick_input := Vector2.ZERO
var camera_yaw := 0.0
var camera_pitch := -0.14
var camera_target_yaw := 0.0
var camera_target_pitch := -0.14
var camera_manual_timer := 0.0
var camera_recenter_timer := 0.0
var assist_lock_time := 0.0
var health := 140.0
var max_health := 140.0
var energy := 100.0
var aura := 0.0
var aura_time := 0.0
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var dodge_cooldown := 0.0
var dodge_time := 0.0
var dodge_direction := Vector3.ZERO
var attack_lunge_time := 0.0
var attack_lunge_direction := Vector3.ZERO
var queued_attack_time := 0.0
var invulnerability := 0.0
var combo_step := 0
var combo_timer := 0.0
var level := 1
var xp := 0
var coins := 0
var training: Dictionary = {"force": 0, "vitesse": 0, "energie": 0}
var camera_pivot: Node3D
var camera_arm: SpringArm3D
var camera: Camera3D
var combat_fx: GPUParticles3D
var assisted_target: EnemyAI
var stats_emit_timer := 0.0
var hero_frame_probe_time := 0.0
var hero_frame_confirmed := false
var current_hero_frame := 0
var camera_front_view := false
var difficulty := "intermediaire"
var damage_taken_multiplier := 1.0
var can_be_defeated := true
var boat_mode := false
var boat_visual: Node3D
var boat_heading := 0.0
var boat_speed := 0.0
var boat_turn_rate := 0.0

func configure(data: Dictionary) -> void:
	save_data = data
	hero_id = String(save_data.get("hero", "cheikh"))
	level = int(save_data.get("level", 1))
	xp = int(save_data.get("xp", 0))
	coins = int(save_data.get("coins", 250))
	training = save_data.get("training", {"force": 0, "vitesse": 0, "energie": 0})
	set_difficulty(String(save_data.get("difficulty", "intermediaire")))
	_recalculate_stats()
	_build_collision()
	_build_camera()
	_build_fx()
	_build_boat()
	set_hero(hero_id)
	_emit_stats()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	attack_lunge_time = maxf(0.0, attack_lunge_time - delta)
	queued_attack_time = maxf(0.0, queued_attack_time - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	camera_manual_timer = maxf(0.0, camera_manual_timer - delta)
	camera_recenter_timer = maxf(0.0, camera_recenter_timer - delta)
	assist_lock_time = maxf(0.0, assist_lock_time - delta)
	if combo_timer <= 0.0:
		combo_step = 0
	energy = minf(100.0, energy + delta * (9.0 + float(training.get("energie", 0)) * 0.75))
	if aura_time > 0.0:
		aura_time -= delta
		if aura_time <= 0.0:
			_set_aura_visual(false)

	if boat_mode:
		_physics_boat(delta)
		_update_camera(delta, -global_transform.basis.z)
		stats_emit_timer -= delta
		if stats_emit_timer <= 0.0:
			stats_emit_timer = 0.12
			_emit_stats()
		return

	if queued_attack_time > 0.0 and attack_cooldown <= 0.0 and dodge_time <= 0.0:
		queued_attack_time = 0.0
		_perform_attack()

	var direction := _world_move_direction()
	var analog_strength := clampf(_active_move_input().length(), 0.0, 1.0)
	if dodge_time > 0.0:
		velocity.x = dodge_direction.x * _dodge_speed()
		velocity.z = dodge_direction.z * _dodge_speed()
	elif attack_lunge_time > 0.0:
		velocity.x = attack_lunge_direction.x * _attack_lunge_speed()
		velocity.z = attack_lunge_direction.z * _attack_lunge_speed()
	else:
		var response := smoothstep(0.08, 1.0, analog_strength)
		var speed_factor := lerpf(0.34, 1.0, response)
		if analog_strength > 0.88:
			speed_factor = lerpf(speed_factor, 1.08, smoothstep(0.88, 1.0, analog_strength))
		var speed := _movement_speed() * speed_factor * (1.24 if aura_time > 0.0 else 1.0)
		var desired_velocity := direction * speed if direction.length_squared() > 0.02 else Vector3.ZERO
		var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
		var acceleration := 25.0 if not desired_velocity.is_zero_approx() else 32.0
		if not desired_velocity.is_zero_approx() and horizontal_velocity.length_squared() > 0.1:
			var alignment := horizontal_velocity.normalized().dot(desired_velocity.normalized())
			acceleration = lerpf(38.0, 22.0, clampf((alignment + 1.0) * 0.5, 0.0, 1.0))
		horizontal_velocity = horizontal_velocity.move_toward(desired_velocity, acceleration * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
		if direction.length_squared() > 0.02:
			var target_angle := atan2(-direction.x, -direction.z)
			var turn_speed := 15.0 if analog_strength > 0.72 else 10.0
			rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	move_and_slide()
	_update_camera(delta, direction)

	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("skill"):
		skill()
	if Input.is_action_just_pressed("aura"):
		activate_aura()
	if Input.is_action_just_pressed("switch_hero"):
		switch_hero()
	if InputMap.has_action("dodge") and Input.is_action_just_pressed("dodge"):
		dodge()
	stats_emit_timer -= delta
	if stats_emit_timer <= 0.0:
		stats_emit_timer = 0.08
		_emit_stats()

func set_move_input(value: Vector2) -> void:
	move_input = value.limit_length(1.0) if value.length() >= 0.08 else Vector2.ZERO

func set_camera_stick(value: Vector2) -> void:
	camera_stick_input = value.limit_length(1.0) if value.length() >= 0.08 else Vector2.ZERO
	if not camera_stick_input.is_zero_approx():
		camera_manual_timer = 1.8
		camera_recenter_timer = 1.15

func add_camera_drag(relative: Vector2) -> void:
	camera_target_yaw -= relative.x * 0.0037
	camera_target_pitch = clampf(camera_target_pitch - relative.y * 0.0028, -0.48, 0.12)
	camera_manual_timer = 1.45
	camera_recenter_timer = 0.85

func set_hero(new_hero_id: String) -> void:
	if is_instance_valid(hero_visual):
		hero_visual.queue_free()
	hero_id = new_hero_id if HERO_ORDER.has(new_hero_id) else "cheikh"
	hero_visual = HeroFactory.create_hero(hero_id)
	hero_visual.name = "Visuel_" + hero_id
	hero_visual.set_collision_layer_value(1, false)
	hero_visual.set_collision_mask_value(1, false)
	add_child(hero_visual)
	hero_visual.position = Vector3.ZERO
	var character_art := hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if character_art != null:
		# Le héros est cadré proprement dans le HUD 2.5D. Masquer cette copie
		# 3D évite la grande silhouette coupée qui apparaissait à gauche.
		character_art.visible = false
	if boat_mode:
		hero_visual.hide()
	save_data["hero"] = hero_id
	_recalculate_stats()
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	hero_changed.emit(hero_id, String(profile["display_name"]))
	hero_view_changed.emit(hero_id, current_hero_frame, camera_front_view)
	if boat_mode:
		boat_steering_changed.emit(hero_id, 0.0, 0.0, clampf(absf(boat_speed) / 22.5, 0.0, 1.0))
	_set_aura_visual(aura_time > 0.0)

func switch_hero() -> void:
	var index := HERO_ORDER.find(hero_id)
	set_hero(HERO_ORDER[(index + 1) % HERO_ORDER.size()])
	Input.vibrate_handheld(25)
	VoiceFR.speak("Tu contrôles maintenant " + String(HeroFactory.HEROES[hero_id]["display_name"]) + ".")

func attack() -> void:
	if boat_mode or dodge_time > 0.0:
		return
	if attack_cooldown > 0.0:
		if attack_cooldown <= 0.24:
			queued_attack_time = 0.34
		return
	_perform_attack()

func _perform_attack() -> void:
	assisted_target = _nearest_enemy(_attack_assist_range())
	if is_instance_valid(assisted_target):
		_face_enemy(assisted_target)
		assist_lock_time = 0.62
	combo_step = combo_step % 3 + 1
	combo_timer = 1.05
	var base_cooldown := 0.43 if hero_id == "cheikh" else 0.25 if hero_id == "yvane" else 0.32
	attack_cooldown = base_cooldown * (1.20 if combo_step == 3 else 1.0)
	var multiplier := 1.0 if combo_step == 1 else 1.22 if combo_step == 2 else 1.82
	var damage := _attack_damage() * multiplier
	var hits := 0

	if hero_id == "yvane":
		hits = _yvane_ranged_attack(damage)
	elif is_instance_valid(assisted_target):
		var offset := assisted_target.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() > 0.01:
			attack_lunge_direction = offset.normalized()
			attack_lunge_time = 0.15 if combo_step < 3 else 0.22
		var splash_radius := 2.4 if hero_id == "cheikh" else 3.1
		hits = _damage_around_point(assisted_target.global_position, damage, splash_radius, 5.0 if combo_step < 3 else 10.0)
	else:
		hits = _damage_in_front(damage, 4.5 if hero_id == "cheikh" else 5.2, 0.18, 5.0 if combo_step < 3 else 10.0)

	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 0.34 + float(combo_step) * 0.14)
	_spawn_attack_arc(Color(HeroFactory.HEROES[hero_id]["aura"]), 1.0 + float(combo_step) * 0.26, hits > 0)
	Input.vibrate_handheld(24 if combo_step < 3 else 58)
	if hits > 0:
		aura = minf(100.0, aura + float(hits) * (6.5 + combo_step))

func _yvane_ranged_attack(damage: float) -> int:
	var targets := _enemies_by_distance(15.0)
	if targets.is_empty():
		return 0
	var count := 1 if combo_step < 3 else mini(3, targets.size())
	for index in range(count):
		var enemy := targets[index] as EnemyAI
		var impulse := (enemy.global_position - global_position).normalized() * (3.0 if combo_step < 3 else 7.0)
		enemy.take_damage(damage * (0.78 if index > 0 else 1.0), impulse)
	return count

func skill() -> void:
	if boat_mode or skill_cooldown > 0.0 or energy < 30.0 or dodge_time > 0.0:
		return
	assisted_target = _nearest_enemy(18.0)
	if is_instance_valid(assisted_target):
		_face_enemy(assisted_target)
		assist_lock_time = 0.92
	skill_cooldown = 4.0 if hero_id == "cheikh" else 3.0 if hero_id == "yvane" else 3.5
	energy -= 30.0
	var damage := _skill_damage()
	var hits := 0
	if hero_id == "cheikh":
		hits = _damage_nearby(damage, 8.5, 13.0)
	elif hero_id == "yvane":
		var targets := _enemies_by_distance(18.0)
		var count := mini(6, targets.size())
		for index in range(count):
			var enemy := targets[index] as EnemyAI
			enemy.take_damage(damage * (1.0 - float(index) * 0.07), (enemy.global_position - global_position).normalized() * 8.0)
			hits += 1
	else:
		var center := assisted_target.global_position if is_instance_valid(assisted_target) else global_position - global_transform.basis.z * 4.0
		hits = _damage_around_point(center, damage, 9.5, 12.0)
	aura = minf(100.0, aura + float(hits) * 10.0 + 7.0)
	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 0.82)
	_spawn_attack_arc(Color(HeroFactory.HEROES[hero_id]["aura"]), 2.7, hits > 0)
	Input.vibrate_handheld(90)
	var skill_name := "Onde du capitaine" if hero_id == "cheikh" else "Éclair des sept vagues" if hero_id == "yvane" else "Atelier suprême Quinet"
	VoiceFR.speak(skill_name + " !", true)

func dodge() -> void:
	if boat_mode or dodge_cooldown > 0.0 or dodge_time > 0.0:
		return
	var direction := _world_move_direction()
	if direction.length_squared() < 0.02:
		direction = -global_transform.basis.z
		direction.y = 0.0
		direction = direction.normalized()
	dodge_direction = direction
	dodge_time = 0.31 if hero_id == "yvane" else 0.27
	dodge_cooldown = 0.52 if hero_id == "yvane" else 0.64
	invulnerability = maxf(invulnerability, 0.48)
	rotation.y = atan2(-direction.x, -direction.z)
	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 0.22)
	Input.vibrate_handheld(24)

func activate_aura() -> void:
	if boat_mode or aura < 100.0 or aura_time > 0.0:
		return
	aura = 0.0
	aura_time = 16.0 + float(training.get("energie", 0))
	invulnerability = maxf(invulnerability, 1.0)
	_set_aura_visual(true)
	_damage_nearby(_skill_damage() * 0.95, 10.5, 18.0)
	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 1.15)
	Input.vibrate_handheld(170)
	var title := "Volonté du Premier Capitaine" if hero_id == "cheikh" else "Éclair Fantôme" if hero_id == "yvane" else "Génie Mécanique"
	VoiceFR.speak(title + ". Déferlement d'énergie !", true)

func receive_damage(amount: float) -> void:
	if boat_mode or invulnerability > 0.0 or health <= 0.0:
		return
	var defense := 1.0 + float(level - 1) * 0.025
	if hero_id == "cheikh":
		defense *= 1.25
	if aura_time > 0.0:
		defense *= 1.55
	health -= amount * damage_taken_multiplier / defense
	invulnerability = 0.52
	aura = minf(100.0, aura + amount * 0.45)
	combo_step = 0
	combo_timer = 0.0
	Input.vibrate_handheld(70)
	if not can_be_defeated and health <= 1.0:
		health = 1.0
		invulnerability = 1.25
	elif health <= 0.0:
		health = 0.0
		player_defeated.emit()
	_emit_stats()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	_emit_stats()

func train(stat_name: String) -> bool:
	var current := int(training.get(stat_name, 0))
	var cost := 120 + current * 90
	if coins < cost:
		return false
	coins -= cost
	training[stat_name] = current + 1
	_recalculate_stats()
	return true

func get_save_snapshot(zone: int) -> Dictionary:
	save_data["hero"] = hero_id
	save_data["zone"] = zone
	save_data["level"] = level
	save_data["xp"] = xp
	save_data["coins"] = coins
	save_data["training"] = training
	save_data["difficulty"] = difficulty
	return save_data

func set_difficulty(value: String) -> void:
	difficulty = value if ["decouverte", "intermediaire", "difficile"].has(value) else "intermediaire"
	match difficulty:
		"decouverte":
			damage_taken_multiplier = 0.28
			can_be_defeated = false
		"difficile":
			damage_taken_multiplier = 1.45
			can_be_defeated = true
		_:
			damage_taken_multiplier = 1.0
			can_be_defeated = true
	save_data["difficulty"] = difficulty

func enter_boat(spawn_position: Vector3, target_position: Vector3) -> void:
	boat_mode = true
	global_position = spawn_position
	global_position.y = 1.05
	velocity = Vector3.ZERO
	boat_speed = 0.0
	boat_turn_rate = 0.0
	var target_direction := target_position - global_position
	target_direction.y = 0.0
	if target_direction.length_squared() > 0.01:
		boat_heading = atan2(-target_direction.x, -target_direction.z)
	else:
		boat_heading = rotation.y
	rotation.y = boat_heading
	if is_instance_valid(hero_visual):
		hero_visual.hide()
	if is_instance_valid(boat_visual):
		boat_visual.show()
	camera_target_yaw = boat_heading
	camera_target_pitch = -0.16
	camera_manual_timer = 0.0
	camera_recenter_timer = 0.0
	boat_mode_changed.emit(true)
	boat_steering_changed.emit(hero_id, 0.0, 0.0, 0.0)

func exit_boat(landing_position: Vector3) -> void:
	boat_mode = false
	global_position = landing_position
	velocity = Vector3.ZERO
	boat_speed = 0.0
	boat_turn_rate = 0.0
	if is_instance_valid(boat_visual):
		boat_visual.hide()
	if is_instance_valid(hero_visual):
		hero_visual.show()
		var character_art := hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
		if character_art != null:
			character_art.hide()
	camera_target_pitch = -0.14
	camera_target_yaw = rotation.y
	boat_mode_changed.emit(false)

func emit_hero_pose(frame: int) -> void:
	current_hero_frame = clampi(frame, 0, 3)
	hero_pose_changed.emit(hero_id, current_hero_frame)
	hero_view_changed.emit(hero_id, current_hero_frame, camera_front_view)

func navigation_bearing(target_position: Vector3) -> float:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return 0.0
	var world_yaw := atan2(-direction.x, -direction.z)
	return wrapf(world_yaw - camera_yaw, -PI, PI)

func _world_move_direction() -> Vector3:
	var raw_input := _active_move_input()
	var camera_basis := Basis(Vector3.UP, camera_yaw)
	var direction := camera_basis * Vector3(raw_input.x, 0.0, raw_input.y)
	return direction.normalized() if direction.length_squared() > 0.001 else Vector3.ZERO

func _active_move_input() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return move_input if move_input.length() > keyboard.length() else keyboard

func _nearest_enemy(search_radius: float) -> EnemyAI:
	var nearest: EnemyAI
	var nearest_distance := search_radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if enemy.health <= 0.0:
			continue
		var distance := enemy.global_position.distance_to(global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _enemies_by_distance(search_radius: float) -> Array:
	var result: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is EnemyAI:
			var enemy := node as EnemyAI
			if enemy.health > 0.0 and enemy.global_position.distance_to(global_position) <= search_radius:
				result.append(enemy)
	result.sort_custom(func(a: EnemyAI, b: EnemyAI): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	return result

func _face_enemy(enemy: EnemyAI) -> void:
	if not is_instance_valid(enemy):
		return
	var target_direction := enemy.global_position - global_position
	target_direction.y = 0.0
	if target_direction.length_squared() > 0.01:
		rotation.y = atan2(-target_direction.x, -target_direction.z)

func _damage_in_front(damage: float, radius: float, minimum_dot: float, push_power: float) -> int:
	var hits := 0
	var forward: Vector3 = -global_transform.basis.z
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius and offset.normalized().dot(forward) >= minimum_dot:
			enemy.take_damage(damage * (1.65 if aura_time > 0.0 else 1.0), offset.normalized() * push_power)
			hits += 1
	return hits

func _damage_around_point(point: Vector3, damage: float, radius: float, push_power: float) -> int:
	var hits := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		var offset := enemy.global_position - point
		offset.y = 0.0
		if offset.length() <= radius:
			var push_direction := (enemy.global_position - global_position).normalized()
			enemy.take_damage(damage * (1.65 if aura_time > 0.0 else 1.0), push_direction * push_power)
			hits += 1
	return hits

func _damage_nearby(damage: float, radius: float, push_power: float) -> int:
	return _damage_around_point(global_position, damage, radius, push_power)

func register_enemy(enemy: EnemyAI) -> void:
	enemy.player_hit.connect(receive_damage)
	enemy.defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(enemy: EnemyAI, reward_xp: int, reward_coins: int) -> void:
	xp += reward_xp
	coins += reward_coins
	var old_level := level
	level = _level_for_xp(xp)
	if level > old_level:
		_recalculate_stats()
		health = max_health
		VoiceFR.speak("Niveau " + str(level) + " atteint. Nouvelle puissance maîtrisée.")
	if is_instance_valid(enemy):
		enemy_defeated.emit(enemy.profile)
	_emit_stats()

func _level_for_xp(value: int) -> int:
	var result := 1
	var required := 120
	var consumed := 0
	while value >= consumed + required and result < 50:
		consumed += required
		result += 1
		required = 120 + result * 85
	return result

func _recalculate_stats() -> void:
	var health_ratio := clampf(health / maxf(max_health, 1.0), 0.01, 1.0)
	var base_hp := 165.0 if hero_id == "cheikh" else 115.0 if hero_id == "yvane" else 125.0
	max_health = base_hp + float(level - 1) * 13.0 + float(training.get("force", 0)) * 15.0
	health = clampf(max_health * health_ratio, 1.0, max_health)

func _movement_speed() -> float:
	var base := 7.4 if hero_id == "cheikh" else 10.2 if hero_id == "yvane" else 8.7
	return base + float(training.get("vitesse", 0)) * 0.48 + float(level - 1) * 0.04

func _dodge_speed() -> float:
	var base := 22.0 if hero_id == "cheikh" else 29.0 if hero_id == "yvane" else 25.5
	return base + float(training.get("vitesse", 0)) * 0.65

func _attack_lunge_speed() -> float:
	return 16.5 if hero_id == "cheikh" else 14.0 if hero_id == "nelvyn" else 0.0

func _attack_assist_range() -> float:
	return 7.5 if hero_id == "cheikh" else 15.0 if hero_id == "yvane" else 9.0

func _attack_damage() -> float:
	var base := 38.0 if hero_id == "cheikh" else 25.0 if hero_id == "yvane" else 29.0
	return base + float(level - 1) * 4.0 + float(training.get("force", 0)) * 5.0

func _skill_damage() -> float:
	var base := 95.0 if hero_id == "cheikh" else 78.0 if hero_id == "yvane" else 88.0
	return base + float(level - 1) * 7.0 + float(training.get("energie", 0)) * 6.0

func _physics_boat(delta: float) -> void:
	var input_value := _active_move_input()
	var throttle := clampf(-input_value.y, -1.0, 1.0)
	var steering := clampf(input_value.x, -1.0, 1.0)
	var speed_ratio := clampf(absf(boat_speed) / 22.5, 0.0, 1.0)
	var steering_grip := lerpf(0.28, 1.0, speed_ratio)
	var reverse_factor := -0.72 if boat_speed < -0.35 else 1.0
	var desired_turn_rate := steering * steering_grip * 1.32 * reverse_factor
	if absf(throttle) < 0.06 and absf(boat_speed) < 0.65:
		desired_turn_rate = 0.0
	boat_turn_rate = move_toward(boat_turn_rate, desired_turn_rate, 2.8 * delta)
	boat_heading -= boat_turn_rate * delta
	var target_speed := throttle * (22.5 if throttle >= 0.0 else 7.5)
	var engine_response := 5.8 if absf(throttle) > 0.05 else 1.55
	boat_speed = move_toward(boat_speed, target_speed, engine_response * delta)
	var forward: Vector3 = -Basis(Vector3.UP, boat_heading).z
	var desired_velocity: Vector3 = forward * boat_speed
	velocity.x = move_toward(velocity.x, desired_velocity.x, 5.4 * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, 5.4 * delta)
	velocity.y = 0.0
	rotation.y = boat_heading
	move_and_slide()
	global_position.y = 1.05
	if is_instance_valid(boat_visual):
		speed_ratio = clampf(absf(boat_speed) / 22.5, 0.0, 1.0)
		boat_visual.position.y = sin(Time.get_ticks_msec() * 0.0034) * (0.045 + speed_ratio * 0.075)
		boat_visual.rotation.z = lerpf(boat_visual.rotation.z, -steering * 0.075 * speed_ratio, 1.0 - exp(-3.6 * delta))
		boat_visual.rotation.x = sin(Time.get_ticks_msec() * 0.0022) * (0.018 + speed_ratio * 0.024)
		var wake := boat_visual.get_node_or_null("Sillage") as GPUParticles3D
		if wake != null:
			wake.emitting = absf(boat_speed) > 1.6
		var helm := boat_visual.get_node_or_null("PosteDePilotage/Gouvernail3D") as Node3D
		if helm != null:
			helm.rotation.z = lerp_angle(helm.rotation.z, -steering * 0.92, 1.0 - exp(-8.5 * delta))
		var rudder := boat_visual.get_node_or_null("GouvernailArrière") as Node3D
		if rudder != null:
			rudder.rotation.y = lerp_angle(rudder.rotation.y, steering * 0.58, 1.0 - exp(-7.0 * delta))
		var sail_root := boat_visual.get_node_or_null("Voilure") as Node3D
		if sail_root != null:
			sail_root.rotation.y = lerp_angle(sail_root.rotation.y, steering * 0.10, 1.0 - exp(-2.4 * delta))
	boat_steering_changed.emit(hero_id, steering, throttle, speed_ratio)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionJoueur"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.46
	capsule.height = 1.30
	collision.shape = capsule
	collision.position.y = 0.98
	add_child(collision)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "PivotCamera"
	add_child(camera_pivot)
	camera_pivot.top_level = true
	camera_pivot.global_position = global_position + Vector3(0.0, 1.48, 0.0)
	camera_target_yaw = rotation.y
	camera_yaw = camera_target_yaw
	camera_target_pitch = -0.14
	camera_pitch = camera_target_pitch
	camera_arm = SpringArm3D.new()
	camera_arm.name = "BrasCamera"
	camera_arm.spring_length = 4.55
	camera_arm.margin = 0.22
	camera_arm.collision_mask = 1
	# Le bras ne doit jamais heurter la capsule du joueur qu'il suit.
	# Sans cette exclusion, Android rapproche la caméra au contact du héros
	# et transforme involontairement la vue troisième personne en vue subjective.
	camera_arm.add_excluded_object(get_rid())
	camera_pivot.add_child(camera_arm)
	camera = Camera3D.new()
	camera.name = "CameraJoueur"
	camera.current = true
	camera.fov = 58.0
	camera.near = 0.06
	camera.far = 1500.0
	camera.position = Vector3(0.56, 0.08, 0.0)
	camera_arm.add_child(camera)

func _update_camera(delta: float, direction: Vector3) -> void:
	if not is_instance_valid(camera_pivot):
		return
	if not camera_stick_input.is_zero_approx():
		camera_target_yaw -= camera_stick_input.x * 2.05 * delta
		camera_target_pitch = clampf(camera_target_pitch - camera_stick_input.y * 1.18 * delta, -0.54, 0.18)
		camera_manual_timer = 1.8
		camera_recenter_timer = 1.15
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var camera_forward: Vector3 = -Basis(Vector3.UP, camera_yaw).z
	var moving_forward := direction.length_squared() > 0.02 and direction.dot(camera_forward) > 0.18
	if camera_manual_timer <= 0.0 and camera_recenter_timer <= 0.0:
		if boat_mode:
			camera_target_yaw = lerp_angle(camera_target_yaw, boat_heading, 1.0 - exp(-2.4 * delta))
			camera_target_pitch = lerpf(camera_target_pitch, -0.16, 1.0 - exp(-2.0 * delta))
		elif assist_lock_time > 0.0 and is_instance_valid(assisted_target) and assisted_target.health > 0.0 and assisted_target.global_position.distance_to(global_position) < 13.0:
			var target_direction := assisted_target.global_position - global_position
			target_direction.y = 0.0
			if target_direction.length_squared() > 0.01:
				var target_yaw := atan2(-target_direction.x, -target_direction.z)
				camera_target_yaw = lerp_angle(camera_target_yaw, target_yaw, 1.0 - exp(-2.2 * delta))
		elif moving_forward and horizontal_speed > _movement_speed() * 0.48:
			camera_target_yaw = lerp_angle(camera_target_yaw, rotation.y, 1.0 - exp(-1.35 * delta))
	camera_yaw = lerp_angle(camera_yaw, camera_target_yaw, 1.0 - exp(-9.5 * delta))
	camera_pitch = lerpf(camera_pitch, camera_target_pitch, 1.0 - exp(-9.0 * delta))

	var hero_height := 3.6 if boat_mode else float(HeroFactory.HEROES[hero_id]["height"])
	var look_ahead := Vector3(velocity.x, 0.0, velocity.z) * 0.035
	var desired_anchor := global_position + Vector3(0.0, 3.35 if boat_mode else hero_height * 0.68 + 0.18, 0.0) + look_ahead
	camera_pivot.global_position = camera_pivot.global_position.lerp(desired_anchor, 1.0 - exp(-11.0 * delta))
	camera_pivot.rotation.y = camera_yaw
	camera_pivot.rotation.x = camera_pitch

	var running_ratio := clampf(horizontal_speed / (22.5 if boat_mode else maxf(_movement_speed(), 0.1)), 0.0, 1.0)
	var target_length := lerpf(10.8, 12.6, running_ratio) if boat_mode else lerpf(4.35, 4.75, running_ratio)
	camera_arm.spring_length = lerpf(camera_arm.spring_length, target_length, 1.0 - exp(-5.5 * delta))
	var target_fov := lerpf(62.0, 69.0, running_ratio) if boat_mode else lerpf(58.0, 63.0, running_ratio)
	if aura_time > 0.0:
		target_fov += 3.0
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-4.5 * delta))
	if not boat_mode:
		_update_camera_facing()
		_confirm_hero_framing(delta, hero_height)

func _update_camera_facing() -> void:
	var orbit_angle := absf(wrapf(camera_yaw - rotation.y, -PI, PI))
	var new_front_view := camera_front_view
	if camera_front_view and orbit_angle < 1.34:
		new_front_view = false
	elif not camera_front_view and orbit_angle > 1.72:
		new_front_view = true
	if new_front_view != camera_front_view:
		camera_front_view = new_front_view
		hero_view_changed.emit(hero_id, current_hero_frame, camera_front_view)

func _confirm_hero_framing(delta: float, hero_height: float) -> void:
	if hero_frame_confirmed or not is_instance_valid(hero_visual) or not camera.current:
		return
	hero_frame_probe_time += delta
	if hero_frame_probe_time < 0.35:
		return
	var hero_center := hero_visual.global_position + Vector3(0.0, hero_height * 0.52, 0.0)
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_position := camera.unproject_position(hero_center)
	var camera_distance := camera.global_position.distance_to(hero_visual.global_position)
	var framed := (
		not camera.is_position_behind(hero_center)
		and camera_arm.get_hit_length() > 3.2
		and camera_distance > 3.2
		and screen_position.x > viewport_size.x * 0.12
		and screen_position.x < viewport_size.x * 0.88
		and screen_position.y > viewport_size.y * 0.12
		and screen_position.y < viewport_size.y * 0.92
	)
	if framed:
		hero_frame_confirmed = true
		print(
			"CHK_HERO_FRAMED hero=%s camera_distance=%.2f arm=%.2f screen=%d,%d"
			% [
				hero_id,
				camera_distance,
				camera_arm.get_hit_length(),
				roundi(screen_position.x),
				roundi(screen_position.y)
			]
		)

func _build_fx() -> void:
	combat_fx = GPUParticles3D.new()
	combat_fx.amount = 190
	combat_fx.one_shot = true
	combat_fx.explosiveness = 0.94
	combat_fx.lifetime = 0.68
	combat_fx.visibility_aabb = AABB(Vector3(-12, -5, -12), Vector3(24, 16, 24))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 1.0
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.initial_velocity_min = 4.0
	process.initial_velocity_max = 14.0
	process.gravity = Vector3(0, -3.0, 0)
	combat_fx.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.58)
	combat_fx.draw_pass_1 = quad
	combat_fx.position.y = 1.05
	add_child(combat_fx)

func _build_boat() -> void:
	boat_visual = QuinetBoatFactory.create_boat()
	boat_visual.name = "BateauJouable"
	boat_visual.hide()
	add_child(boat_visual)

func _play_combat_fx(color: Color, scale_factor: float) -> void:
	var process := combat_fx.process_material as ParticleProcessMaterial
	if process != null:
		process.color = color
		process.scale_min = 0.4 + scale_factor * 0.4
		process.scale_max = 1.0 + scale_factor
	var quad := combat_fx.draw_pass_1 as QuadMesh
	if quad != null:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(color, 0.88)
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 7.0
		quad.material = material
	combat_fx.restart()

func _spawn_attack_arc(color: Color, scale_factor: float, confirmed_hit: bool) -> void:
	var arc := MeshInstance3D.new()
	arc.name = "TraînéeAttaque"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.72
	mesh.outer_radius = 1.0
	mesh.rings = 20
	mesh.ring_segments = 34
	arc.mesh = mesh
	arc.position = Vector3(0, 0.98, -0.75)
	arc.rotation_degrees.x = 90.0
	arc.scale = Vector3.ONE * (0.5 + scale_factor * 0.18)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.90 if confirmed_hit else 0.52)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 7.5 if confirmed_hit else 3.8
	arc.material_override = material
	add_child(arc)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(arc, "scale", Vector3.ONE * (1.2 + scale_factor * 0.62), 0.22)
	tween.tween_property(arc, "transparency", 1.0, 0.24)
	tween.chain().tween_callback(arc.queue_free)

func _set_aura_visual(active: bool) -> void:
	if not is_instance_valid(hero_visual):
		return
	var aura_node := hero_visual.get_node_or_null("RigVisuel/Aura") as GPUParticles3D
	if aura_node != null:
		aura_node.emitting = active

func _emit_stats() -> void:
	stats_changed.emit(health, max_health, energy, aura, level, xp, coins)
