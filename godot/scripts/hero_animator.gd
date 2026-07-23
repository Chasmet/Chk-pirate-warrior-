class_name QuinetHeroAnimator
extends Node

var controller: PlayerController
var animation_time: float = 0.0
var attack_time: float = 0.0
var skill_time: float = 0.0
var previous_attack_cooldown: float = 0.0
var previous_skill_cooldown: float = 0.0
var tracked_visual_id: int = 0
var rest_transforms: Dictionary = {}

func bind(player: PlayerController) -> void:
	controller = player
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(controller.hero_visual):
		return

	var visual: CharacterBody3D = controller.hero_visual
	if visual.get_instance_id() != tracked_visual_id:
		tracked_visual_id = visual.get_instance_id()
		rest_transforms.clear()
		_capture_rest_transforms(visual)

	animation_time += delta
	if controller.attack_cooldown > previous_attack_cooldown + 0.08:
		attack_time = 0.34 if controller.hero_id == "yvane" else 0.48
	if controller.skill_cooldown > previous_skill_cooldown + 0.15:
		skill_time = 0.82
	previous_attack_cooldown = controller.attack_cooldown
	previous_skill_cooldown = controller.skill_cooldown
	attack_time = maxf(0.0, attack_time - delta)
	skill_time = maxf(0.0, skill_time - delta)

	var horizontal_speed: float = Vector2(controller.velocity.x, controller.velocity.z).length()
	var movement: float = clampf(horizontal_speed / 8.5, 0.0, 1.0)
	var stride_speed: float = lerpf(5.0, 12.5, movement)
	var stride: float = sin(animation_time * stride_speed)
	var bob: float = absf(sin(animation_time * stride_speed)) * 0.055 * movement
	var aura_pulse: float = 0.0
	if controller.aura_time > 0.0:
		aura_pulse = 0.018 + sin(animation_time * 12.0) * 0.012

	var attack_progress: float = 0.0
	if attack_time > 0.0:
		attack_progress = sin((1.0 - attack_time / 0.48) * PI)
	var skill_progress: float = 0.0
	if skill_time > 0.0:
		skill_progress = sin((1.0 - skill_time / 0.82) * PI)

	visual.position = Vector3(0.0, bob + aura_pulse * 0.5, 0.0)
	visual.rotation.x = -movement * 0.055 + skill_progress * 0.04
	visual.rotation.y = attack_progress * (-0.42 if controller.hero_id != "yvane" else -0.66)
	visual.rotation.z = stride * movement * 0.025
	var pulse: float = 1.0 + aura_pulse + skill_progress * 0.045
	visual.scale = Vector3.ONE * pulse

	_animate_parts(visual, stride, movement, attack_progress, skill_progress)

func _capture_rest_transforms(visual: Node) -> void:
	var rig: Node = visual.get_node_or_null("RigVisuel")
	if rig == null:
		return
	for child: Node in rig.get_children():
		if child is Node3D:
			rest_transforms[child.get_instance_id()] = (child as Node3D).transform

func _animate_parts(visual: Node, stride: float, movement: float, attack_progress: float, skill_progress: float) -> void:
	var rig: Node = visual.get_node_or_null("RigVisuel")
	if rig == null:
		return

	for child: Node in rig.get_children():
		if not child is Node3D:
			continue
		var part: Node3D = child as Node3D
		var id: int = part.get_instance_id()
		if not rest_transforms.has(id):
			rest_transforms[id] = part.transform
		var rest: Transform3D = rest_transforms[id]
		part.transform = rest
		var part_name: String = String(part.name).to_lower()
		var side: float = signf(rest.origin.x)

		if part_name.begins_with("bras"):
			part.rotation.x += stride * movement * 0.58 * -side
			part.rotation.z += attack_progress * 0.62 * side
		elif part_name.begins_with("jambe"):
			part.rotation.x += stride * movement * 0.72 * side
		elif part_name.begins_with("botte"):
			part.rotation.x += maxf(0.0, stride * side) * movement * 0.18
		elif part_name.contains("sabre") or part_name.contains("lame"):
			part.rotation.x += attack_progress * 1.25
			part.rotation.z += attack_progress * 1.05 * (side if side != 0.0 else 1.0)
		elif part_name.contains("gantelet"):
			part.position.z -= attack_progress * 0.48
			part.rotation.x += attack_progress * 0.65
		elif part_name.contains("manteau"):
			part.rotation.x += movement * 0.09 + sin(animation_time * 4.0) * 0.025
		elif part_name.contains("tresse"):
			part.rotation.x += sin(animation_time * 5.0 + rest.origin.x * 9.0) * (0.035 + movement * 0.04)

		if skill_progress > 0.0 and (part_name.contains("module") or part_name.contains("gantelet")):
			part.scale = Vector3.ONE * (1.0 + skill_progress * 0.18)
