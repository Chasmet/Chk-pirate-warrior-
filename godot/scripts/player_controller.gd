class_name PlayerController
extends CharacterBody3D

signal stats_changed(health: float, max_health: float, energy: float, aura: float, level: int, xp: int, coins: int)
signal hero_changed(hero_id: String, display_name: String)
signal player_defeated
signal enemy_defeated(profile: Dictionary)

const HERO_ORDER := ["cheikh", "yvane", "nelvyn"]

var save_data: Dictionary = {}
var hero_id := "cheikh"
var hero_visual: CharacterBody3D
var move_input := Vector2.ZERO
var camera_yaw := 0.0
var camera_pitch := -0.12
var camera_manual_timer := 0.0
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

func configure(data: Dictionary) -> void:
	save_data = data
	hero_id = String(save_data.get("hero", "cheikh"))
	level = int(save_data.get("level", 1))
	xp = int(save_data.get("xp", 0))
	coins = int(save_data.get("coins", 250))
	training = save_data.get("training", {"force": 0, "vitesse": 0, "energie": 0})
	_recalculate_stats()
	_build_collision()
	_build_camera()
	_build_fx()
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
	assist_lock_time = maxf(0.0, assist_lock_time - delta)
	if combo_timer <= 0.0:
		combo_step = 0
	energy = minf(100.0, energy + delta * (9.0 + float(training.get("energie", 0)) * 0.75))
	if aura_time > 0.0:
		aura_time -= delta
		if aura_time <= 0.0:
			_set_aura_visual(false)

	if queued_attack_time > 0.0 and attack_cooldown <= 0.0 and dodge_time <= 0.0:
		queued_attack_time = 0.0
		_perform_attack()

	var direction := _world_move_direction()
	var analog_strength := clampf(move_input.length(), 0.0, 1.0)
	if dodge_time > 0.0:
		velocity.x = dodge_direction.x * _dodge_speed()
		velocity.z = dodge_direction.z * _dodge_speed()
	elif attack_lunge_time > 0.0:
		velocity.x = attack_lunge_direction.x * _attack_lunge_speed()
		velocity.z = attack_lunge_direction.z * _attack_lunge_speed()
	else:
		var speed_multiplier := analog_strength
		if analog_strength > 0.92:
			speed_multiplier *= 1.08
		var speed := _movement_speed() * speed_multiplier * (1.28 if aura_time > 0.0 else 1.0)
		var acceleration := 42.0 if direction.length_squared() > 0.02 else 55.0
		velocity.x = move_toward(velocity.x, direction.x * speed, delta * acceleration)
		velocity.z = move_toward(velocity.z, direction.z * speed, delta * acceleration)
		if direction.length_squared() > 0.02:
			var target_angle := atan2(-direction.x, -direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, delta * 14.0)
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
	move_input = value if value.length() >= 0.08 else Vector2.ZERO

func add_camera_drag(relative: Vector2) -> void:
	camera_yaw -= relative.x * 0.0042
	camera_pitch = clampf(camera_pitch - relative.y * 0.0032, -0.44, 0.08)
	camera_manual_timer = 2.3

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
	save_data["hero"] = hero_id
	_recalculate_stats()
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	hero_changed.emit(hero_id, String(profile["display_name"]))
	_set_aura_visual(aura_time > 0.0)

func switch_hero() -> void:
	var index := HERO_ORDER.find(hero_id)
	set_hero(HERO_ORDER[(index + 1) % HERO_ORDER.size()])
	Input.vibrate_handheld(25)
	VoiceFR.speak("Tu contrôles maintenant " + String(HeroFactory.HEROES[hero_id]["display_name"]) + ".")

func attack() -> void:
	if dodge_time > 0.0:
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
	if skill_cooldown > 0.0 or energy < 30.0 or dodge_time > 0.0:
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
	Input.vibrate_handheld(90)
	var skill_name := "Onde du capitaine" if hero_id == "cheikh" else "Éclair des sept vagues" if hero_id == "yvane" else "Atelier suprême Quinet"
	VoiceFR.speak(skill_name + " !", true)

func dodge() -> void:
	if dodge_cooldown > 0.0 or dodge_time > 0.0:
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
	if aura < 100.0 or aura_time > 0.0:
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
	if invulnerability > 0.0 or health <= 0.0:
		return
	var defense := 1.0 + float(level - 1) * 0.025
	if hero_id == "cheikh":
		defense *= 1.25
	if aura_time > 0.0:
		defense *= 1.55
	health -= amount / defense
	invulnerability = 0.52
	aura = minf(100.0, aura + amount * 0.45)
	combo_step = 0
	combo_timer = 0.0
	Input.vibrate_handheld(70)
	if health <= 0.0:
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
	return save_data

func _world_move_direction() -> Vector3:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_input := move_input if move_input.length() > keyboard.length() else keyboard
	var basis := Basis(Vector3.UP, camera_yaw)
	var direction := basis * Vector3(raw_input.x, 0.0, raw_input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction

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
		if camera_manual_timer <= 0.0:
			camera_yaw = lerp_angle(camera_yaw, rotation.y, 0.38)

func _damage_in_front(damage: float, radius: float, minimum_dot: float, push_power: float) -> int:
	var hits := 0
	var forward := -global_transform.basis.z
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
	camera_pivot.position = Vector3(0.0, 1.28, 0.0)
	camera_arm = SpringArm3D.new()
	camera_arm.name = "BrasCamera"
	camera_arm.spring_length = 4.15
	camera_arm.margin = 0.18
	camera_arm.collision_mask = 1
	camera_pivot.add_child(camera_arm)
	camera = Camera3D.new()
	camera.name = "CameraJoueur"
	camera.current = true
	camera.fov = 61.0
	camera.near = 0.06
	camera.far = 800.0
	camera.position = Vector3(0.42, 0.22, 0.0)
	camera_arm.add_child(camera)

func _update_camera(delta: float, direction: Vector3) -> void:
	if not is_instance_valid(camera_pivot):
		return
	if camera_manual_timer <= 0.0:
		if assist_lock_time > 0.0 and is_instance_valid(assisted_target) and assisted_target.health > 0.0 and assisted_target.global_position.distance_to(global_position) < 13.0:
			var target_direction := assisted_target.global_position - global_position
			target_direction.y = 0.0
			if target_direction.length_squared() > 0.01:
				var target_yaw := atan2(-target_direction.x, -target_direction.z)
				camera_yaw = lerp_angle(camera_yaw, target_yaw, delta * 3.6)
		elif direction.length_squared() > 0.08:
			camera_yaw = lerp_angle(camera_yaw, rotation.y, delta * 2.2)
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, camera_yaw, delta * 13.0)
	camera_pivot.rotation.x = lerpf(camera_pivot.rotation.x, camera_pitch, delta * 10.0)
	var moving := Vector2(velocity.x, velocity.z).length()
	var target_fov := 65.0 if moving > _movement_speed() * 0.85 else 61.0
	if aura_time > 0.0:
		target_fov += 4.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 4.0)

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

func _set_aura_visual(active: bool) -> void:
	if not is_instance_valid(hero_visual):
		return
	var aura_node := hero_visual.get_node_or_null("RigVisuel/Aura") as GPUParticles3D
	if aura_node != null:
		aura_node.emitting = active

func _emit_stats() -> void:
	stats_changed.emit(health, max_health, energy, aura, level, xp, coins)
