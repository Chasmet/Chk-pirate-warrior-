extends Node

# Direction de combat non destructive : conserve l'IA existante et ajoute
# des distances tactiques, des manœuvres propres à chaque archétype et des
# attaques spéciales télégraphiées pour les six boss.

const TAG_READY := "combat_variety_ready_v31"
const META_COOLDOWN := "combat_variety_cooldown"
const META_PHASE := "combat_variety_phase"

var elapsed_time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1320
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed_time += delta
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if not is_instance_valid(enemy) or enemy.health <= 0.0:
			continue
		if not enemy.has_meta(TAG_READY):
			_initialize_enemy(enemy)
		_tick_enemy(enemy, delta)

func _initialize_enemy(enemy: EnemyAI) -> void:
	enemy.set_meta(TAG_READY, true)
	enemy.set_meta(META_PHASE, enemy.phase)
	var offset := fmod(float(enemy.get_instance_id()), 23.0) * 0.11
	enemy.set_meta(META_COOLDOWN, 2.4 + offset)
	_apply_archetype_spacing(enemy)

func _tick_enemy(enemy: EnemyAI, delta: float) -> void:
	if not is_instance_valid(enemy.target):
		return
	_apply_archetype_spacing(enemy)

	var previous_phase := int(enemy.get_meta(META_PHASE, enemy.phase))
	if enemy.boss and enemy.phase != previous_phase:
		enemy.set_meta(META_PHASE, enemy.phase)
		_on_boss_phase_changed(enemy)

	var cooldown := maxf(0.0, float(enemy.get_meta(META_COOLDOWN, 0.0)) - delta)
	enemy.set_meta(META_COOLDOWN, cooldown)
	if cooldown > 0.0 or enemy.attack_windup > 0.0 or enemy.hit_stun > 0.0:
		return

	var distance := enemy.global_position.distance_to(enemy.target.global_position)
	if enemy.boss:
		_trigger_boss_special(enemy, distance)
		enemy.set_meta(META_COOLDOWN, maxf(2.9, 6.6 - float(enemy.phase) * 0.9))
	else:
		_trigger_archetype_move(enemy, distance)

func _apply_archetype_spacing(enemy: EnemyAI) -> void:
	var weapon := String(enemy.profile.get("weapon", "saber"))
	var creature := String(enemy.profile.get("creature", ""))
	if enemy.boss:
		enemy.preferred_distance = maxf(enemy.attack_range * 0.88, 2.25)
		return
	match weapon:
		"rifle":
			enemy.preferred_distance = maxf(enemy.attack_range * 0.92, 4.7)
		"shield":
			enemy.preferred_distance = 1.65
		"hammer", "gear":
			enemy.preferred_distance = 2.05
		"dual":
			enemy.preferred_distance = 1.38
		"staff", "whip":
			enemy.preferred_distance = 2.65
		_:
			enemy.preferred_distance = maxf(enemy.attack_range * 0.92, 1.7)
	if creature == "bird":
		enemy.preferred_distance = 3.2
	elif creature == "monkey":
		enemy.preferred_distance = 1.25

func _trigger_archetype_move(enemy: EnemyAI, distance: float) -> void:
	var weapon := String(enemy.profile.get("weapon", "saber"))
	var creature := String(enemy.profile.get("creature", ""))
	var to_target := enemy.target.global_position - enemy.global_position
	to_target.y = 0.0
	var direction := to_target.normalized() if to_target.length_squared() > 0.01 else -enemy.global_transform.basis.z

	if weapon == "dual" and distance > 2.0 and distance < 7.5:
		var side := Vector3(-direction.z, 0.0, direction.x) * enemy.orbit_sign
		enemy.velocity.x = (direction * 7.0 + side * 8.0).x
		enemy.velocity.z = (direction * 7.0 + side * 8.0).z
		_spawn_motion_streak(enemy, Color("c96bea"))
		enemy.set_meta(META_COOLDOWN, 4.2)
	elif weapon == "rifle" and distance < 3.6:
		enemy.velocity.x = -direction.x * 7.4
		enemy.velocity.z = -direction.z * 7.4
		_spawn_motion_streak(enemy, Color("7fc4e9"))
		enemy.set_meta(META_COOLDOWN, 3.5)
	elif weapon == "staff":
		_heal_nearby_allies(enemy)
		enemy.set_meta(META_COOLDOWN, 7.8)
	elif creature == "bird" and distance < 8.5:
		enemy.velocity.x = direction.x * 10.5
		enemy.velocity.z = direction.z * 10.5
		_spawn_motion_streak(enemy, Color("8dd8ff"))
		enemy.set_meta(META_COOLDOWN, 4.8)
	else:
		enemy.orbit_sign *= -1.0
		enemy.set_meta(META_COOLDOWN, 3.8 + fmod(elapsed_time, 1.6))

func _heal_nearby_allies(medic: EnemyAI) -> void:
	var healed := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node is EnemyAI or node == medic:
			continue
		var ally := node as EnemyAI
		if ally.health <= 0.0 or ally.global_position.distance_to(medic.global_position) > 7.0:
			continue
		var missing := ally.max_health - ally.health
		if missing <= 0.5:
			continue
		ally.health = minf(ally.max_health, ally.health + ally.max_health * 0.10)
		ally._update_health_bar()
		healed += 1
		_spawn_ground_pulse(ally, Color("58e483"), 1.25, 0.32)
		if healed >= 3:
			break
	if healed > 0:
		_spawn_ground_pulse(medic, Color("b7ffd0"), 2.6, 0.46)

func _on_boss_phase_changed(enemy: EnemyAI) -> void:
	var accent: Color = enemy.profile.get("accent", enemy.profile.get("color", Color("ffb13b")))
	_spawn_ground_pulse(enemy, accent, 4.0 + float(enemy.phase), 0.72)
	enemy.attack_cooldown = maxf(enemy.attack_cooldown, 0.75)
	if is_instance_valid(enemy.aura_particles):
		enemy.aura_particles.amount = 36 + enemy.phase * 18
		enemy.aura_particles.emitting = true

func _trigger_boss_special(enemy: EnemyAI, distance: float) -> void:
	var identifier := String(enemy.profile.get("id", ""))
	var accent: Color = enemy.profile.get("accent", enemy.profile.get("color", Color("ffb13b")))
	var to_target := enemy.target.global_position - enemy.global_position
	to_target.y = 0.0
	var direction := to_target.normalized() if to_target.length_squared() > 0.01 else -enemy.global_transform.basis.z
	match identifier:
		"brakor":
			_spawn_ground_pulse(enemy, accent, 7.0, 0.72)
			_queue_area_hit(enemy, 7.4, 0.68, 0.70)
		"scorpia":
			_spawn_motion_streak(enemy, accent)
			enemy.velocity.x = (direction * 14.0 + Vector3(-direction.z, 0.0, direction.x) * enemy.orbit_sign * 5.0).x
			enemy.velocity.z = (direction * 14.0 + Vector3(-direction.z, 0.0, direction.x) * enemy.orbit_sign * 5.0).z
			_queue_area_hit(enemy, 3.0, 0.58, 0.34)
		"kryl":
			_spawn_ground_pulse(enemy, Color("a8efff"), 5.8, 0.82)
			_queue_area_hit(enemy, 10.5, 0.55, 0.80)
		"mako":
			var side := Vector3(-direction.z, 0.0, direction.x) * enemy.orbit_sign
			enemy.velocity.x = side.x * 11.0
			enemy.velocity.z = side.z * 11.0
			_spawn_ground_pulse(enemy, accent, 6.2, 0.62)
			_queue_area_hit(enemy, 6.5, 0.62, 0.60)
		"volkan":
			_spawn_ground_pulse(enemy, Color("ff4b18"), 8.2, 0.88)
			_queue_area_hit(enemy, 8.5, 0.78, 0.84)
		"vorga":
			_spawn_ground_pulse(enemy, Color("61c9ff"), 9.5, 0.68)
			_queue_area_hit(enemy, 14.0, 0.66, 0.64)
		_:
			_spawn_ground_pulse(enemy, accent, 6.0, 0.70)
			if distance < 6.5:
				_queue_area_hit(enemy, 6.5, 0.60, 0.68)
	enemy.attack_cooldown = maxf(enemy.attack_cooldown, 1.0)

func _queue_area_hit(enemy: EnemyAI, radius: float, damage_multiplier: float, delay: float) -> void:
	var enemy_ref := weakref(enemy)
	get_tree().create_timer(delay).timeout.connect(func():
		var resolved = enemy_ref.get_ref()
		if not resolved is EnemyAI:
			return
		var active := resolved as EnemyAI
		if active.health <= 0.0 or not is_instance_valid(active.target):
			return
		if active.global_position.distance_to(active.target.global_position) <= radius:
			active.player_hit.emit(active.attack_damage * damage_multiplier)
	)

func _spawn_ground_pulse(anchor: Node3D, color: Color, radius: float, duration: float) -> void:
	if not is_instance_valid(anchor.get_parent()) or not anchor.get_parent() is Node3D:
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "TélégrapheStudio"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.035
	mesh.radial_segments = 48
	pulse.mesh = mesh
	pulse.material_override = _effect_material(Color(color, 0.34), 4.0)
	(anchor.get_parent() as Node3D).add_child(pulse)
	pulse.global_position = anchor.global_position + Vector3.UP * 0.055
	pulse.scale = Vector3(0.12, 1.0, 0.12)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3(radius, 1.0, radius), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "transparency", 1.0, duration)
	tween.chain().tween_callback(pulse.queue_free)

func _spawn_motion_streak(anchor: Node3D, color: Color) -> void:
	var streak := MeshInstance3D.new()
	streak.name = "TraînéeMouvementStudio"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.48, 0.18, 2.8)
	streak.mesh = mesh
	streak.material_override = _effect_material(Color(color, 0.28), 3.2)
	anchor.add_child(streak)
	streak.position = Vector3(0.0, 0.72, 1.35)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(streak, "scale:z", 2.2, 0.28)
	tween.tween_property(streak, "transparency", 1.0, 0.34)
	tween.chain().tween_callback(streak.queue_free)

func _effect_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
