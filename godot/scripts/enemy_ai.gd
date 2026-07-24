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
var attack_windup := 0.0
var hit_stun := 0.0
var boss := false
var phase := 1
var orbit_sign := 1.0
var preferred_distance := 2.1
var difficulty := "intermediaire"
var attack_delay_multiplier := 1.0
var aura_particles: GPUParticles3D
var attack_marker: MeshInstance3D
var health_bar_root: Node3D
var health_fill: MeshInstance3D
var health_bar_width := 2.2

func configure(data: Dictionary, player: Node3D) -> void:
	profile = data
	target = player
	boss = bool(profile.get("boss", false))
	difficulty = String(profile.get("difficulty", "intermediaire"))
	max_health = float(profile.get("health", 100.0))
	speed = float(profile.get("speed", 3.2))
	attack_range = float(profile.get("range", 1.7))
	attack_damage = float(profile.get("damage", 8.0))
	match difficulty:
		"decouverte":
			max_health *= 0.78 if not boss else 0.68
			speed *= 0.86
			attack_damage *= 0.34
			attack_delay_multiplier = 1.42
		"difficile":
			max_health *= 1.32 if not boss else 1.48
			speed *= 1.12
			attack_damage *= 1.58
			attack_delay_multiplier = 0.78
		_:
			attack_delay_multiplier = 1.0
	health = max_health
	preferred_distance = maxf(attack_range * 0.92, 1.55)
	orbit_sign = -1.0 if randi() % 2 == 0 else 1.0
	attack_cooldown = randf_range(0.35, 1.15)
	add_to_group("enemies")
	if boss:
		add_to_group("bosses")
	_build_attack_marker()
	_build_health_bar()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hit_stun = maxf(0.0, hit_stun - delta)
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	if hit_stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 14.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 14.0)
		move_and_slide()
		_update_health_bar()
		return

	var flat_delta := target.global_position - global_position
	flat_delta.y = 0.0
	var distance := flat_delta.length()
	var direction := flat_delta.normalized() if distance > 0.001 else Vector3.ZERO
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 9.0)

	if attack_windup > 0.0:
		attack_windup -= delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
		_update_attack_marker(true)
		if attack_windup <= 0.0:
			_finish_attack(distance)
	else:
		_update_attack_marker(false)
		var steering := Vector3.ZERO
		if distance > preferred_distance + 0.65:
			steering = direction
		elif distance < preferred_distance * 0.72:
			steering = -direction * 0.65
		else:
			steering = Vector3(-direction.z, 0.0, direction.x) * orbit_sign * 0.74
		steering += _separation_force() * 1.2
		if steering.length_squared() > 1.0:
			steering = steering.normalized()
		velocity.x = move_toward(velocity.x, steering.x * speed, delta * 15.0)
		velocity.z = move_toward(velocity.z, steering.z * speed, delta * 15.0)
		if distance <= attack_range + 0.35 and attack_cooldown <= 0.0 and _attack_slot_available():
			_start_attack()

	move_and_slide()
	_update_boss_phase()
	_update_health_bar()

func take_damage(amount: float, impulse: Vector3 = Vector3.ZERO) -> void:
	if health <= 0.0:
		return
	health -= amount
	hit_stun = 0.20 if not boss else 0.09
	attack_windup = 0.0
	_update_attack_marker(false)
	velocity += impulse
	_flash_model()
	_update_health_bar()
	if health <= 0.0:
		_die()

func health_ratio() -> float:
	return clampf(health / max_health, 0.0, 1.0)

func _start_attack() -> void:
	attack_windup = (0.48 if not boss else 0.38) * lerpf(1.0, attack_delay_multiplier, 0.45)
	attack_cooldown = (1.45 if not boss else 1.02) * attack_delay_multiplier
	velocity.x = 0.0
	velocity.z = 0.0
	_update_attack_marker(true)

func _finish_attack(distance: float) -> void:
	_update_attack_marker(false)
	var boss_reach := float(phase - 1) * 0.55 if boss else 0.0
	if distance <= attack_range + 0.85 + boss_reach and is_instance_valid(target):
		player_hit.emit(attack_damage * (1.0 + 0.25 * float(phase - 1)))
		var forward := (target.global_position - global_position).normalized()
		velocity += forward * (5.0 if not boss else 8.5)

func _attack_slot_available() -> bool:
	var attackers := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not is_instance_valid(node) or not node is EnemyAI:
			continue
		var other := node as EnemyAI
		if other.attack_windup > 0.0 and other.global_position.distance_to(target.global_position) < 7.0:
			attackers += 1
	var maximum := 1 if boss else 2
	return attackers < maximum

func _separation_force() -> Vector3:
	var force := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not is_instance_valid(node) or not node is EnemyAI:
			continue
		var other := node as EnemyAI
		var offset := global_position - other.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > 0.001 and distance < 2.3:
			force += offset.normalized() * (1.0 - distance / 2.3)
	return force

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

func _build_attack_marker() -> void:
	attack_marker = MeshInstance3D.new()
	attack_marker.name = "AlerteAttaque"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.25 if not boss else 2.6
	cylinder.bottom_radius = cylinder.top_radius
	cylinder.height = 0.025
	cylinder.radial_segments = 48
	attack_marker.mesh = cylinder
	attack_marker.position.y = 0.04
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.08, 0.03, 0.30)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.03, 0.01)
	material.emission_energy_multiplier = 4.5
	attack_marker.material_override = material
	attack_marker.visible = false
	add_child(attack_marker)

func _update_attack_marker(active: bool) -> void:
	if not is_instance_valid(attack_marker):
		return
	attack_marker.visible = active
	if active:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.025) * 0.14
		attack_marker.scale = Vector3(pulse, 1.0, pulse)

func _build_health_bar() -> void:
	health_bar_width = 4.2 if boss else 2.35
	health_bar_root = Node3D.new()
	health_bar_root.name = "BarreDeVie"
	health_bar_root.position.y = 4.9 if boss else 2.75
	add_child(health_bar_root)
	var back := MeshInstance3D.new()
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(health_bar_width, 0.26 if boss else 0.18)
	back.mesh = back_mesh
	back.material_override = _billboard_material(Color(0.02, 0.02, 0.025, 0.92))
	health_bar_root.add_child(back)
	health_fill = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(health_bar_width, 0.20 if boss else 0.13)
	health_fill.mesh = fill_mesh
	health_fill.position.z = 0.01
	health_fill.material_override = _billboard_material(Color("d83a32") if boss else Color("e39b3f"))
	health_bar_root.add_child(health_fill)
	_update_health_bar()

func _billboard_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material

func _update_health_bar() -> void:
	if not is_instance_valid(health_fill):
		return
	var ratio := health_ratio()
	health_fill.scale.x = maxf(0.001, ratio)
	health_fill.position.x = -health_bar_width * (1.0 - ratio) * 0.5
	if is_instance_valid(health_bar_root):
		health_bar_root.visible = health > 0.0 and (boss or ratio < 0.999)

func _flash_model() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var material: Material = mesh_node.material_override
			if material is StandardMaterial3D:
				var standard := material as StandardMaterial3D
				standard.emission_enabled = true
				standard.emission = Color(1.0, 0.25, 0.12)
				standard.emission_energy_multiplier = 2.2
			elif material is ShaderMaterial:
				(material as ShaderMaterial).set_shader_parameter("hit_flash", 1.0)
	get_tree().create_timer(0.10).timeout.connect(_clear_flash)

func _clear_flash() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var material: Material = mesh_node.material_override
			if material is StandardMaterial3D:
				(material as StandardMaterial3D).emission_enabled = false
			elif material is ShaderMaterial:
				(material as ShaderMaterial).set_shader_parameter("hit_flash", 0.0)

func _die() -> void:
	set_physics_process(false)
	_update_attack_marker(false)
	if is_instance_valid(health_bar_root):
		health_bar_root.hide()
	var reward_xp := int(profile.get("xp", 30))
	var reward_coins := int(profile.get("coins", 12))
	defeated.emit(self, reward_xp, reward_coins)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.08, 1.15), 0.28)
	tween.tween_callback(queue_free)
