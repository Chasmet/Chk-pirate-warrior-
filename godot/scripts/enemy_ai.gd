class_name EnemyAI
extends CharacterBody3D

signal defeated(enemy: EnemyAI, reward_xp: int, reward_coins: int)
signal player_hit(damage: float)

var profile: Dictionary = {}
var target: Node3D
var health := 100.0
var max_health := 100.0
var speed := 3.2
var attack_range := 1.7
var attack_damage := 8.0
var attack_cooldown := 0.0
var hit_stun := 0.0
var boss := false
var phase := 1
var aura_particles: GPUParticles3D

func configure(data: Dictionary, player: Node3D) -> void:
	profile = data
	target = player
	boss = bool(profile.get("boss", false))
	max_health = float(profile.get("health", 100.0))
	health = max_health
	speed = float(profile.get("speed", 3.2))
	attack_range = float(profile.get("range", 1.7))
	attack_damage = float(profile.get("damage", 8.0))
	add_to_group("enemies")
	if boss:
		add_to_group("bosses")

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hit_stun = maxf(0.0, hit_stun - delta)
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	if hit_stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 10.0)
		move_and_slide()
		return

	var flat_delta := target.global_position - global_position
	flat_delta.y = 0.0
	var distance := flat_delta.length()
	if distance > attack_range:
		var direction := flat_delta.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if direction.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 7.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 16.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 16.0)
		if attack_cooldown <= 0.0:
			attack_cooldown = 1.4 if not boss else 0.95
			player_hit.emit(attack_damage * (1.0 + 0.25 * float(phase - 1)))
	move_and_slide()
	_update_boss_phase()

func take_damage(amount: float, impulse: Vector3 = Vector3.ZERO) -> void:
	if health <= 0.0:
		return
	health -= amount
	hit_stun = 0.16 if not boss else 0.07
	velocity += impulse
	_flash_model()
	if health <= 0.0:
		_die()

func health_ratio() -> float:
	return clampf(health / max_health, 0.0, 1.0)

func _update_boss_phase() -> void:
	if not boss:
		return
	var new_phase := 1
	if health_ratio() <= 0.25:
		new_phase = 3
	elif health_ratio() <= 0.60:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		speed *= 1.12
		attack_damage *= 1.12
		if is_instance_valid(aura_particles):
			aura_particles.emitting = true

func _flash_model() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var material := mesh_node.material_override as StandardMaterial3D
			if material != null:
				material.emission_enabled = true
				material.emission = Color(1.0, 0.25, 0.12)
				material.emission_energy_multiplier = 2.2
	get_tree().create_timer(0.09).timeout.connect(_clear_flash)

func _clear_flash() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var material := mesh_node.material_override as StandardMaterial3D
			if material != null:
				material.emission_enabled = false

func _die() -> void:
	set_physics_process(false)
	var reward_xp := int(profile.get("xp", 30))
	var reward_coins := int(profile.get("coins", 12))
	defeated.emit(self, reward_xp, reward_coins)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.08, 1.15), 0.28)
	tween.tween_callback(queue_free)
