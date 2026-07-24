extends CanvasLayer

const SOURCE_LAYER := 1 << 19
const VISIBLE_LAYER := 1

var player: PlayerController
var tracked_visual_id := 0
var source_sprite: Sprite3D
var hero_view: TextureRect
var atlas_texture: AtlasTexture
var chroma_material: ShaderMaterial
var tracked_texture: Texture2D
var tracked_hframes := -1
var tracked_frame := -1
var label_cleanup_timer := 0.0

func _ready() -> void:
	layer = 0
	process_priority = 2000
	hero_view = TextureRect.new()
	hero_view.name = "HérosOriginalProjeté"
	hero_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	hero_view.visible = false
	add_child(hero_view)
	atlas_texture = AtlasTexture.new()
	hero_view.texture = atlas_texture

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform vec3 key_color = vec3(1.0, 0.0, 1.0);
uniform float key_inner = 0.10;
uniform float key_outer = 0.32;

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float key_distance = distance(source.rgb, key_color);
    float chroma_alpha = smoothstep(key_inner, key_outer, key_distance);
    COLOR = vec4(source.rgb, source.a * chroma_alpha) * COLOR;
}
"""
	chroma_material = ShaderMaterial.new()
	chroma_material.shader = shader
	hero_view.material = chroma_material
	set_process(true)

func _process(delta: float) -> void:
	label_cleanup_timer -= delta
	if label_cleanup_timer <= 0.0:
		label_cleanup_timer = 0.35
		_hide_broken_world_labels()

	if not is_instance_valid(player):
		player = _find_player()
		tracked_visual_id = 0
		if not is_instance_valid(player):
			hero_view.visible = false
			return
	if not is_instance_valid(player.hero_visual):
		hero_view.visible = false
		return
	if player.hero_visual.get_instance_id() != tracked_visual_id:
		tracked_visual_id = player.hero_visual.get_instance_id()
		_bind_current_hero()
	if not is_instance_valid(source_sprite):
		_bind_current_hero()
	if not is_instance_valid(source_sprite) or not is_instance_valid(player.camera):
		hero_view.visible = false
		return

	source_sprite.layers = SOURCE_LAYER
	source_sprite.visible = true
	player.camera.cull_mask &= ~SOURCE_LAYER
	player.camera.cull_mask |= VISIBLE_LAYER
	var old_renderer := player.hero_visual.get_node_or_null("RigVisuel/CharacterRenderer3D") as MeshInstance3D
	if is_instance_valid(old_renderer):
		old_renderer.visible = false

	_sync_atlas()
	_update_screen_position()

func _bind_current_hero() -> void:
	source_sprite = null
	tracked_texture = null
	tracked_hframes = -1
	tracked_frame = -1
	if not is_instance_valid(player) or not is_instance_valid(player.hero_visual):
		return
	source_sprite = player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if source_sprite == null:
		return
	source_sprite.layers = SOURCE_LAYER
	_sync_atlas(true)
	print("CHK_HERO_SCREEN_RENDERER_READY hero=%s" % player.hero_id)

func _sync_atlas(force: bool = false) -> void:
	var texture := source_sprite.texture
	var hframes := maxi(1, source_sprite.hframes)
	var frame := clampi(source_sprite.frame, 0, hframes - 1)
	if texture == null:
		hero_view.visible = false
		return
	if force or texture != tracked_texture:
		tracked_texture = texture
		atlas_texture.atlas = texture
	if force or hframes != tracked_hframes or frame != tracked_frame:
		tracked_hframes = hframes
		tracked_frame = frame
		var frame_width := float(texture.get_width()) / float(hframes)
		atlas_texture.region = Rect2(frame_width * float(frame), 0.0, frame_width, float(texture.get_height()))
	hero_view.modulate = source_sprite.modulate

func _update_screen_position() -> void:
	var texture := source_sprite.texture
	if texture == null:
		hero_view.visible = false
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var frame_width := float(texture.get_width()) / float(maxi(1, source_sprite.hframes))
	var aspect := frame_width / maxf(float(texture.get_height()), 1.0)
	var display_height := viewport_size.y * (0.23 if player.boat_mode else 0.46)
	var display_size := Vector2(display_height * aspect, display_height)
	var center_x := viewport_size.x * 0.50
	var bottom_y := viewport_size.y * (0.80 if player.boat_mode else 0.92)
	hero_view.position = Vector2(center_x - display_size.x * 0.5, bottom_y - display_size.y)
	hero_view.size = display_size
	hero_view.visible = true

func _hide_broken_world_labels() -> void:
	_hide_labels_recursive(get_tree().root)

func _hide_labels_recursive(node: Node) -> void:
	if node is Label3D:
		var label := node as Label3D
		label.visible = false
		label.layers = SOURCE_LAYER
	for child in node.get_children():
		_hide_labels_recursive(child)

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
