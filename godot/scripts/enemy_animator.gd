class_name QuinetEnemyAnimator
extends Node

var enemy: EnemyAI
var animation_time: float = 0.0
var attack_time: float = 0.0
var previous_attack_cooldown: float = 0.0
var rest_transforms: Dictionary = {}

func bind(target_enemy: EnemyAI) -> void:
	enemy = target_enemy
	_capture_rest_transforms()
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(enemy):
		return
	animation_time += delta
	if enemy.attack_cooldown > previous_attack_cooldown + 0.12:
		attack_time = 0.58 if enemy.boss else 0.42
	previous_attack_cooldown = enemy.attack_cooldown
	attack_time = maxf(0.0, attack_time - delta)

	var horizontal_speed: float = Vector2(enemy.velocity.x, enemy.velocity.z).length()
	var movement: float = clampf(horizontal_speed / maxf(enemy.speed, 0.1), 0.0, 1.0)
	var stride: float = sin(animation_time * lerpf(4.5, 10.0, movement))
	var attack_progress: float = 0.0
	if attack_time > 0.0:
		attack_progress = sin((1.0 - attack_time / 0.58) * PI)
	var hit_progress: float = clampf(enemy.hit_stun / 0.16, 0.0, 1.0)
	var boss_pulse: float = 0.0
	if enemy.boss and enemy.phase > 1:
		boss_pulse = (0.018 + float(enemy.phase - 1) * 0.012) * sin(animation_time * (7.0 + enemy.phase))

	_animate_parts(stride, movement, attack_progress, hit_progress, boss_pulse)

func _capture_rest_transforms() -> void:
	rest_transforms.clear()
	if not is_instance_valid(enemy):
		return
	for child: Node in enemy.get_children():
		if child is MeshInstance3D:
			rest_transforms[child.get_instance_id()] = (child as Node3D).transform

func _animate_parts(stride: float, movement: float, attack_progress: float, hit_progress: float, boss_pulse: float) -> void:
	for child: Node in enemy.get_children():
		if not child is MeshInstance3D:
			continue
		var part := child as MeshInstance3D
		var id: int = part.get_instance_id()
		if not rest_transforms.has(id):
			rest_transforms[id] = part.transform
		var rest: Transform3D = rest_transforms[id]
		part.transform = rest
		var name_lower: String = String(part.name).to_lower()
		var side: float = signf(rest.origin.x)

		if name_lower.begins_with("jambe") or name_lower.begins_with("patte"):
			part.rotation.x += stride * movement * 0.58 * (side if side != 0.0 else 1.0)
		elif name_lower.begins_with("bras"):
			part.rotation.x -= stride * movement * 0.46 * side
			part.rotation.z += attack_progress * 0.85 * side
		elif name_lower.contains("sabre") or name_lower.contains("arme") or name_lower.contains("trident"):
			part.rotation.x += attack_progress * 1.15
			part.rotation.z += attack_progress * 0.85
		elif name_lower.contains("têtearme"):
			part.position.z -= attack_progress * 0.55
		elif name_lower.contains("aile"):
			part.rotation.z += sin(animation_time * 9.5) * 0.72 * side
		elif name_lower.contains("pince"):
			part.rotation.y += sin(animation_time * 4.0 + side) * 0.16 * side
			part.position.x += attack_progress * 0.32 * side
		elif name_lower.contains("torse") or name_lower.contains("corps") or name_lower.contains("carapace"):
			part.position.y += absf(stride) * movement * 0.06
			part.rotation.z += hit_progress * 0.22 * (side if side != 0.0 else 1.0)

		if enemy.boss:
			part.scale = Vector3.ONE * (1.0 + boss_pulse)
		if hit_progress > 0.0:
			part.rotation.x += hit_progress * 0.08
