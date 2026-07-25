class_name Enemy25DVisual
extends RefCounted

static func apply(enemy: EnemyAI, profile: Dictionary) -> bool:
	if not bool(profile.get("visual_25d", false)):
		return false
	var texture := Enemy25DCatalog.atlas_texture(profile)
	if texture == null:
		push_error("Texture 2.5D absente pour " + String(profile.get("name", "unité")))
		return false

	_hide_procedural_model(enemy)
	var root := Node3D.new()
	root.name = "Visual25D"
	root.position.y = float(profile.get("sprite_y", 1.0))
	enemy.add_child(root)

	var layer_count := clampi(int(profile.get("visual_layers", 2)), 1, 3)
	for layer_index in range(layer_count - 1, -1, -1):
		var sprite := Sprite3D.new()
		sprite.name = "Character25D" if layer_index == 0 else "Profondeur25D_%d" % layer_index
		sprite.texture = texture
		sprite.pixel_size = float(profile.get("pixel_size", 0.026))
		sprite.centered = true
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold = 0.035
		sprite.no_depth_test = false
		sprite.render_priority = 7 - layer_index
		sprite.position = Vector3(float(layer_index) * -0.018, 0.0, float(layer_index) * 0.055)
		var depth_scale := 1.0 + float(layer_index) * 0.018
		sprite.scale = Vector3(depth_scale, depth_scale, 1.0)
		if layer_index > 0:
			sprite.modulate = Color(0.28, 0.30, 0.34, 0.58 - float(layer_index - 1) * 0.13)
		root.add_child(sprite)

	_add_ground_shadow(enemy, profile)
	var animator := Enemy25DAnimator.new()
	animator.name = "Animation25D"
	enemy.add_child(animator)
	animator.bind(enemy, root)
	enemy.set_meta("visual_pipeline", "2.5d_original")
	enemy.set_meta("atlas_zone", int(profile.get("atlas_zone", 0)))
	return true

static func _hide_procedural_model(enemy: EnemyAI) -> void:
	for child in enemy.get_children():
		if child is MeshInstance3D and String(child.name) != "AlerteAttaque":
			(child as MeshInstance3D).visible = false

static func _add_ground_shadow(enemy: EnemyAI, profile: Dictionary) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "Ombre25D"
	var mesh := CylinderMesh.new()
	var scale_value := float(profile.get("scale", 1.0))
	mesh.top_radius = 0.55 * scale_value
	mesh.bottom_radius = 0.55 * scale_value
	mesh.height = 0.018
	mesh.radial_segments = 24
	shadow.mesh = mesh
	shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.01, 0.015, 0.02, 0.36)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow.material_override = material
	enemy.add_child(shadow)


class Enemy25DAnimator:
	extends Node

	var enemy: EnemyAI
	var visual_root: Node3D
	var rest_position := Vector3.ZERO
	var animation_time := 0.0
	var last_hit_stun := 0.0

	func bind(target: EnemyAI, root: Node3D) -> void:
		enemy = target
		visual_root = root
		rest_position = root.position
		set_process(true)

	func _process(delta: float) -> void:
		if not is_instance_valid(enemy) or not is_instance_valid(visual_root):
			return
		animation_time += delta
		var movement := clampf(Vector2(enemy.velocity.x, enemy.velocity.z).length() / maxf(enemy.speed, 0.1), 0.0, 1.0)
		var pace := lerpf(2.3, 8.5, movement)
		var stride := sin(animation_time * pace)
		var bob := absf(stride) * movement * (0.075 if enemy.boss else 0.052)
		var attack_lean := 0.0
		if enemy.attack_windup > 0.0:
			attack_lean = sin(clampf(enemy.attack_windup / 0.48, 0.0, 1.0) * PI) * -0.14
		var hit_lean := clampf(enemy.hit_stun / 0.20, 0.0, 1.0) * 0.16
		visual_root.position = rest_position + Vector3(0.0, bob, 0.0)
		visual_root.rotation.z = stride * movement * 0.035 + attack_lean + hit_lean
		var pulse := 1.0
		if enemy.boss and enemy.phase > 1:
			pulse += sin(animation_time * (5.0 + enemy.phase)) * 0.018 * float(enemy.phase - 1)
		visual_root.scale = Vector3.ONE * pulse
		_update_hit_feedback()

	func _update_hit_feedback() -> void:
		var active := enemy.hit_stun > 0.0
		for child in visual_root.get_children():
			if child is Sprite3D:
				var sprite := child as Sprite3D
				if active:
					sprite.modulate = Color(1.0, 0.42, 0.30, sprite.modulate.a)
				elif String(sprite.name).begins_with("Profondeur"):
					var index := int(String(sprite.name).get_slice("_", 1))
					sprite.modulate = Color(0.28, 0.30, 0.34, 0.58 - float(index - 1) * 0.13)
				else:
					sprite.modulate = Color.WHITE
