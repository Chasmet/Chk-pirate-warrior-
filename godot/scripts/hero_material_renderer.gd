extends Node

const SOURCE_LAYER := 1 << 19
const VISIBLE_LAYER := 1

var player: PlayerController
var tracked_visual_id := 0
var source_sprite: Sprite3D
var renderer: MeshInstance3D
var quad: QuadMesh
var material: StandardMaterial3D
var tracked_texture: Texture2D
var tracked_hframes := -1
var tracked_frame := -1
var tracked_pixel_size := -1.0

func _ready() -> void:
	process_priority = 2000
	set_process(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player()
		tracked_visual_id = 0
		if not is_instance_valid(player):
			return
	if not is_instance_valid(player.hero_visual):
		return
	if player.hero_visual.get_instance_id() != tracked_visual_id:
		tracked_visual_id = player.hero_visual.get_instance_id()
		_bind_current_hero()
	if not is_instance_valid(source_sprite) or not is_instance_valid(renderer):
		_bind_current_hero()
	if not is_instance_valid(source_sprite) or not is_instance_valid(renderer):
		return

	# Le Sprite3D reste actif pour la logique existante (poses, changement de
	# texture avant/dos et pilotage), mais sa couche n’est pas rendue par la
	# caméra Android. Le quad ci-dessous est le seul rendu visible.
	source_sprite.layers = SOURCE_LAYER
	source_sprite.visible = true
	if is_instance_valid(player.camera):
		player.camera.cull_mask &= ~SOURCE_LAYER
		player.camera.cull_mask |= VISIBLE_LAYER

	_sync_renderer()

func _bind_current_hero() -> void:
	source_sprite = null
	renderer = null
	quad = null
	material = null
	tracked_texture = null
	tracked_hframes = -1
	tracked_frame = -1
	tracked_pixel_size = -1.0
	if not is_instance_valid(player) or not is_instance_valid(player.hero_visual):
		return
	var rig := player.hero_visual.get_node_or_null("RigVisuel") as Node3D
	if rig == null:
		return
	source_sprite = rig.get_node_or_null("CharacterArt") as Sprite3D
	if source_sprite == null:
		return
	var old := rig.get_node_or_null("CharacterRenderer3D")
	if is_instance_valid(old):
		old.queue_free()

	renderer = MeshInstance3D.new()
	renderer.name = "CharacterRenderer3D"
	renderer.layers = VISIBLE_LAYER
	renderer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad = QuadMesh.new()
	renderer.mesh = quad
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.035
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.no_depth_test = false
	material.render_priority = 8
	renderer.material_override = material
	rig.add_child(renderer)
	source_sprite.layers = SOURCE_LAYER
	_sync_renderer(true)
	print("CHK_HERO_MATERIAL_RENDERER_READY hero=%s" % player.hero_id)

func _sync_renderer(force: bool = false) -> void:
	var texture := source_sprite.texture
	var hframes := maxi(1, source_sprite.hframes)
	var frame := clampi(source_sprite.frame, 0, hframes - 1)
	var pixel_size := source_sprite.pixel_size
	if force or texture != tracked_texture:
		tracked_texture = texture
		material.albedo_texture = texture
	if force or hframes != tracked_hframes or frame != tracked_frame:
		tracked_hframes = hframes
		tracked_frame = frame
		material.uv1_scale = Vector3(1.0 / float(hframes), 1.0, 1.0)
		material.uv1_offset = Vector3(float(frame) / float(hframes), 0.0, 0.0)
	if force or not is_equal_approx(pixel_size, tracked_pixel_size) or texture != null:
		tracked_pixel_size = pixel_size
		if texture != null:
			var frame_width := float(texture.get_width()) / float(hframes)
			quad.size = Vector2(frame_width * pixel_size, float(texture.get_height()) * pixel_size)

	renderer.position = source_sprite.position
	renderer.rotation = source_sprite.rotation
	renderer.scale = source_sprite.scale
	renderer.visible = source_sprite.visible
	material.albedo_color = source_sprite.modulate

func _find_player() -> PlayerController:
	var named := get_tree().root.find_child("ÉquipageQuinet", true, false)
	if named is PlayerController:
		return named as PlayerController
	return _find_player_recursive(get_tree().root)

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
