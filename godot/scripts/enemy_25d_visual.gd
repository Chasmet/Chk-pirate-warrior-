class_name Enemy25DVisual
extends RefCounted

const ANIMATED_RANKS := ["boss", "commandant", "nakama"]
const SHEET_COLUMNS := 7

# Remplace uniquement l’apparence visible. CharacterBody3D, collision, IA,
# statistiques, attaques et récompenses restent ceux du jeu existant.
static func apply(enemy: EnemyAI, profile: Dictionary) -> bool:
	if not is_instance_valid(enemy):
		return false
	var rank := String(profile.get("rank", ""))
	if not ANIMATED_RANKS.has(rank):
		return false
	if enemy.get_node_or_null("Visual25D") != null:
		return true

	var asset := Enemy25DAssetBank.asset_for_profile(profile)
	var texture := asset.get("texture") as Texture2D
	if texture == null:
		push_warning("Fallback 3D conservé pour " + String(profile.get("name", "personnage")))
		return false

	_hide_procedural_model(enemy)

	var root := Node3D.new()
	root.name = "Visual25D"
	enemy.add_child(root)

	var sprite := Sprite3D.new()
	sprite.name = "Character25D"
	sprite.texture = texture
	sprite.hframes = int(asset.get("hframes", 1))
	sprite.vframes = int(asset.get("vframes", 1))
	sprite.frame = 0
	var target_height := _target_height(rank, profile)
	var frame_height := float(texture.get_height()) / maxf(1.0, float(sprite.vframes))
	sprite.pixel_size = target_height / maxf(frame_height, 1.0)
	sprite.centered = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.double_sided = true
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.035
	sprite.no_depth_test = false
	sprite.render_priority = 8
	sprite.modulate = Color.WHITE
	root.add_child(sprite)

	# Le pivot physique reste au sol pendant les mouvements et les attaques.
	root.position.y = target_height * 0.5 + 0.035
	_add_ground_shadow(enemy, profile, rank)

	var animator := Enemy25DAnimator.new()
	animator.name = "Animation25D"
	enemy.add_child(animator)
	animator.bind(enemy, root, bool(asset.get("animated", false)))

	enemy.set_meta("visual_pipeline", "%s_2d_animated_in_3d" % rank)
	enemy.set_meta("visual_rank", rank)
	enemy.set_meta("atlas_zone", int(profile.get("atlas_zone", profile.get("zone", 0))))
	enemy.set_meta("visual_asset_source", String(asset.get("source", "unknown")))
	return true

static func _target_height(rank: String, profile: Dictionary) -> float:
	match rank:
		"boss":
			return clampf(float(profile.get("visual_height", 3.22)), 2.75, 3.55)
		"commandant":
			return clampf(float(profile.get("visual_height", 2.48)), 2.20, 2.75)
		_:
			return clampf(float(profile.get("visual_height", 2.18)), 1.95, 2.45)

static func _hide_procedural_model(node: Node) -> void:
	if String(node.name) == "BarreDeVie":
		return
	for child in node.get_children():
		var child_name := String(child.name)
		if child is MeshInstance3D and child_name not in ["AlerteAttaque", "Ombre25D"]:
			(child as MeshInstance3D).visible = false
		if child_name != "BarreDeVie":
			_hide_procedural_model(child)

static func _add_ground_shadow(enemy: EnemyAI, profile: Dictionary, rank: String) -> void:
	if enemy.get_node_or_null("Ombre25D") != null:
		return
	var shadow := MeshInstance3D.new()
	shadow.name = "Ombre25D"
	var mesh := CylinderMesh.new()
	var scale_value := float(profile.get("scale", 1.0))
	var radius_factor := 0.60 if rank == "boss" else 0.48 if rank == "commandant" else 0.40
	mesh.top_radius = radius_factor * scale_value
	mesh.bottom_radius = radius_factor * scale_value
	mesh.height = 0.016
	mesh.radial_segments = 20
	shadow.mesh = mesh
	shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.005, 0.008, 0.012, 0.38)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow.material_override = material
	enemy.add_child(shadow)

class Enemy25DAnimator:
	extends Node

	var enemy: EnemyAI
	var visual_root: Node3D
	var sprite: Sprite3D
	var rest_position := Vector3.ZERO
	var animation_time := 0.0
	var animated_sheet := false
	var phase_seen := 1
	var phase_intro_time := 0.0

	func bind(target: EnemyAI, root: Node3D, has_animation_sheet: bool) -> void:
		enemy = target
		visual_root = root
		sprite = root.get_node_or_null("Character25D") as Sprite3D
		rest_position = root.position
		animated_sheet = has_animation_sheet
		phase_seen = enemy.phase
		set_process(true)

	func _process(delta: float) -> void:
		if not is_instance_valid(enemy) or not is_instance_valid(visual_root) or not is_instance_valid(sprite):
			return
		animation_time += delta
		if enemy.phase != phase_seen:
			phase_seen = enemy.phase
			phase_intro_time = 0.85
		phase_intro_time = maxf(0.0, phase_intro_time - delta)

		var movement := clampf(Vector2(enemy.velocity.x, enemy.velocity.z).length() / maxf(enemy.speed, 0.1), 0.0, 1.0)
		var stride := sin(animation_time * lerpf(2.5, 9.0, movement))
		var bob := absf(stride) * movement * 0.055
		var attack_lean := 0.0
		if enemy.attack_windup > 0.0:
			attack_lean = sin(clampf(enemy.attack_windup / 0.48, 0.0, 1.0) * PI) * -0.10
		var hit_lean := clampf(enemy.hit_stun / 0.20, 0.0, 1.0) * 0.12
		visual_root.position = rest_position + Vector3(0.0, bob, 0.0)
		visual_root.rotation.z = stride * movement * 0.025 + attack_lean + hit_lean

		var pulse := 1.0
		if enemy.phase > 1:
			pulse += sin(animation_time * (5.0 + enemy.phase)) * 0.014 * float(enemy.phase - 1)
		visual_root.scale = Vector3.ONE * pulse
		if animated_sheet:
			_update_sheet_frame(movement)
		_update_hit_feedback()

	func _update_sheet_frame(movement: float) -> void:
		var row := 0
		var fps := 5.0
		if enemy.health <= 0.0:
			row = 6
			fps = 8.0
		elif enemy.hit_stun > 0.0:
			row = 5
			fps = 12.0
		elif enemy.attack_windup > 0.0:
			row = 3
			fps = 13.0
		elif phase_intro_time > 0.0:
			row = 7
			fps = 9.0
		elif movement > 0.66:
			row = 2
			fps = 11.0
		elif movement > 0.06:
			row = 1
			fps = 8.0
		elif enemy.boss and enemy.phase > 1 and fmod(animation_time, 4.0) < 0.62:
			row = 4
			fps = 9.0
		var frame_x := int(animation_time * fps + float(enemy.get_instance_id() % 7)) % SHEET_COLUMNS
		sprite.frame = row * SHEET_COLUMNS + frame_x

	func _update_hit_feedback() -> void:
		sprite.modulate = Color(1.0, 0.48, 0.34, 1.0) if enemy.hit_stun > 0.0 else Color.WHITE
