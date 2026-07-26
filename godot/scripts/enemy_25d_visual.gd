class_name Enemy25DVisual
extends RefCounted

# Affichage volontairement limité aux boss existants.
# Leur IA, leurs collisions, leur vie et leurs attaques restent celles du monde 3D.
static func apply(enemy: EnemyAI, profile: Dictionary) -> bool:
	if not is_instance_valid(enemy) or not enemy.boss:
		return false
	if not bool(profile.get("boss", false)) or String(profile.get("rank", "boss")) != "boss":
		return false
	if enemy.get_node_or_null("Visual25D") != null:
		return true

	var texture := Enemy25DCatalog.atlas_texture(profile)
	if texture == null:
		push_error("Texture du boss 2.5D absente pour " + String(profile.get("name", "boss")))
		return false

	_hide_procedural_model(enemy)

	var root := Node3D.new()
	root.name = "Visual25D"
	enemy.add_child(root)

	var sprite := Sprite3D.new()
	sprite.name = "Character25D"
	sprite.texture = texture
	# Le boss reste massif mais ne devient pas un géant disproportionné.
	var pixel_size := minf(float(profile.get("pixel_size", 0.0185)), 0.0185)
	sprite.pixel_size = pixel_size
	sprite.centered = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.double_sided = true
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.045
	sprite.no_depth_test = false
	sprite.render_priority = 8
	sprite.modulate = Color.WHITE
	root.add_child(sprite)

	# Même principe que les héros : le pivot visuel est placé aux pieds.
	var region: Rect2 = profile.get("atlas_region", Enemy25DCatalog.BOSS_REGION)
	root.position.y = maxf(0.80, region.size.y * pixel_size * 0.5)

	_add_ground_shadow(enemy, profile)
	var animator := Enemy25DAnimator.new()
	animator.name = "Animation25D"
	enemy.add_child(animator)
	animator.bind(enemy, root)

	enemy.set_meta("visual_pipeline", "boss_2d_realistic_in_3d")
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
		var bob := absf(stride) * movement * 0.075
		var attack_lean := 0.0
		if enemy.attack_windup > 0.0:
			attack_lean = sin(clampf(enemy.attack_windup / 0.48, 0.0, 1.0) * PI) * -0.14
		var hit_lean := clampf(enemy.hit_stun / 0.20, 0.0, 1.0) * 0.16
		visual_root.position = rest_position + Vector3(0.0, bob, 0.0)
		visual_root.rotation.z = stride * movement * 0.035 + attack_lean + hit_lean
		var pulse := 1.0
		if enemy.phase > 1:
			pulse += sin(animation_time * (5.0 + enemy.phase)) * 0.018 * float(enemy.phase - 1)
		visual_root.scale = Vector3.ONE * pulse
		_update_hit_feedback()

	func _update_hit_feedback() -> void:
		var sprite := visual_root.get_node_or_null("Character25D") as Sprite3D
		if sprite == null:
			return
		sprite.modulate = Color(1.0, 0.42, 0.30, 1.0) if enemy.hit_stun > 0.0 else Color.WHITE
