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
var camera_pitch := -0.22
var health := 140.0
var max_health := 140.0
var energy := 100.0
var aura := 0.0
var aura_time := 0.0
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var invulnerability := 0.0
var level := 1
var xp := 0
var coins := 0
var training: Dictionary = {"force": 0, "vitesse": 0, "energie": 0}
var camera_pivot: Node3D
var camera: Camera3D
var combat_fx: GPUParticles3D

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
	invulnerability = maxf(0.0, invulnerability - delta)
	energy = minf(100.0 + float(training.get("energie", 0)) * 5.0, energy + delta * 8.0)
	if aura_time > 0.0:
		aura_time -= delta
		if aura_time <= 0.0:
			_set_aura_visual(false)

	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_input := move_input if move_input.length() > keyboard.length() else keyboard
	var basis := Basis(Vector3.UP, camera_yaw)
	var direction := basis * Vector3(raw_input.x, 0.0, raw_input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var speed := _movement_speed() * (1.28 if aura_time > 0.0 else 1.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 22.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 22.0)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	if direction.length_squared() > 0.02:
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 10.0)
	move_and_slide()
	_update_camera(delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("skill"):
		skill()
	if Input.is_action_just_pressed("aura"):
		activate_aura()
	if Input.is_action_just_pressed("switch_hero"):
		switch_hero()
	_emit_stats()

func set_move_input(value: Vector2) -> void:
	move_input = value

func add_camera_drag(relative: Vector2) -> void:
	camera_yaw -= relative.x * 0.0045
	camera_pitch = clampf(camera_pitch - relative.y * 0.0035, -0.65, 0.18)

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
	VoiceFR.speak("Tu contrôles maintenant " + String(HeroFactory.HEROES[hero_id]["display_name"]) + ".")

func attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.50 if hero_id == "cheikh" else 0.30 if hero_id == "yvane" else 0.40
	var damage := _attack_damage()
	var radius := 2.8 if hero_id == "cheikh" else 3.3 if hero_id == "yvane" else 3.0
	var hits := _damage_nearby(damage, radius, 4.0)
	if hits > 0:
		aura = minf(100.0, aura + float(hits) * 7.0)
		_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 0.25)

func skill() -> void:
	if skill_cooldown > 0.0 or energy < 30.0:
		return
	skill_cooldown = 4.2 if hero_id == "cheikh" else 3.4 if hero_id == "yvane" else 3.8
	energy -= 30.0
	var damage := _skill_damage()
	var radius := 6.4 if hero_id == "cheikh" else 7.5 if hero_id == "yvane" else 8.2
	var hits := _damage_nearby(damage, radius, 10.0)
	aura = minf(100.0, aura + float(hits) * 10.0 + 5.0)
	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 0.65)
	var skill_name := "Onde du capitaine" if hero_id == "cheikh" else "Éclair des sept vagues" if hero_id == "yvane" else "Atelier suprême Quinet"
	VoiceFR.speak(skill_name + " !", true)

func activate_aura() -> void:
	if aura < 100.0 or aura_time > 0.0:
		return
	aura = 0.0
	aura_time = 16.0 + float(training.get("energie", 0))
	_set_aura_visual(true)
	_damage_nearby(_skill_damage() * 0.85, 9.5, 16.0)
	_play_combat_fx(Color(HeroFactory.HEROES[hero_id]["aura"]), 1.0)
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
	invulnerability = 0.45
	aura = minf(100.0, aura + amount * 0.45)
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

func _damage_nearby(damage: float, radius: float, push_power: float) -> int:
	var hits := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius:
			var impulse := offset.normalized() * push_power
			enemy.take_damage(damage * (1.65 if aura_time > 0.0 else 1.0), impulse)
			hits += 1
	return hits

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
	var base_hp := 165.0 if hero_id == "cheikh" else 115.0 if hero_id == "yvane" else 125.0
	max_health = base_hp + float(level - 1) * 13.0 + float(training.get("force", 0)) * 15.0
	health = clampf(health, 1.0, max_health)

func _movement_speed() -> float:
	var base := 6.3 if hero_id == "cheikh" else 8.6 if hero_id == "yvane" else 7.2
	return base + float(training.get("vitesse", 0)) * 0.45 + float(level - 1) * 0.035

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
	capsule.radius = 0.42
	capsule.height = 1.18
	collision.shape = capsule
	collision.position.y = 0.94
	add_child(collision)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "PivotCamera"
	add_child(camera_pivot)
	camera_pivot.position.y = 1.35
	camera = Camera3D.new()
	camera.name = "CameraJoueur"
	camera.current = true
	camera.fov = 62.0
	camera.near = 0.08
	camera.far = 800.0
	camera_pivot.add_child(camera)
	camera.position = Vector3(0, 2.4, 7.8)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera_pivot):
		return
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, camera_yaw, delta * 10.0)
	camera_pivot.rotation.x = lerpf(camera_pivot.rotation.x, camera_pitch, delta * 8.0)

func _build_fx() -> void:
	combat_fx = GPUParticles3D.new()
	combat_fx.amount = 120
	combat_fx.one_shot = true
	combat_fx.explosiveness = 0.92
	combat_fx.lifetime = 0.65
	combat_fx.visibility_aabb = AABB(Vector3(-10, -4, -10), Vector3(20, 14, 20))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 1.0
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.initial_velocity_min = 3.0
	process.initial_velocity_max = 12.0
	process.gravity = Vector3(0, -3.0, 0)
	combat_fx.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.52)
	combat_fx.draw_pass_1 = quad
	combat_fx.position.y = 1.0
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
		material.albedo_color = Color(color, 0.85)
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 6.0
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
