extends CanvasLayer

const SOURCE_LAYER := 1 << 19
const VISIBLE_LAYER := 1

var player: PlayerController
var tracked_visual_id := 0
var source_sprite: Sprite3D
var hero_view: TextureRect
var atlas_texture: AtlasTexture
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
	set_process(true)

func _process(delta: float) -> void:
	label_cleanup_timer -= delta
	if label_cleanup_timer <= 0.0:
		label_cleanup_timer = 0.5
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

	# Le Sprite3D conserve toute la logique existante (poses, avant/dos,
	# pilotage), mais sa couche n’est jamais dessinée par la caméra Android.
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
	var camera := player.camera
	var texture := source_sprite.texture
	if texture == null:
		hero_view.visible = false
		return
	var frame_width := float(texture.get_width()) / float(maxi(1, source_sprite.hframes))
	var world_height := float(texture.get_height()) * source_sprite.pixel_size
	var world_width := frame_width * source_sprite.pixel_size
	var center := source_sprite.global_position
	if camera.is_position_behind(center):
		hero_view.visible = false
		return

	var screen_center := camera.unproject_position(center)
	var top_screen := camera.unproject_position(center + Vector3.UP * world_height * 0.5)
	var bottom_screen := camera.unproject_position(center - Vector3.UP * world_height * 0.5)
	var projected_height := absf(bottom_screen.y - top_screen.y)
	var viewport_size := get_viewport().get_visible_rect().size
	var minimum_height := viewport_size.y * (0.18 if player.boat_mode else 0.30)
	var maximum_height := viewport_size.y * (0.40 if player.boat_mode else 0.58)
	var display_height := clampf(projected_height, minimum_height, maximum_height)
	var aspect := world_width / maxf(world_height, 0.01)
	var display_size := Vector2(display_height * aspect, display_height)
	var display_position := screen_center - display_size * 0.5

	# Le personnage reste entièrement visible sans passer sur les commandes.
	display_position.x = clampf(display_position.x, 12.0, viewport_size.x - display_size.x - 12.0)
	display_position.y = clampf(display_position.y, 90.0, viewport_size.y - display_size.y - 24.0)
	hero_view.position = display_position
	hero_view.size = display_size
	hero_view.visible = true

func _hide_broken_world_labels() -> void:
	# Label3D produit des rectangles blancs avec le pilote OpenGL de certains
	# téléphones et de l’émulateur. Les objectifs restent affichés dans le HUD.
	for node in get_tree().root.find_children("*", "Label3D", true, false):
		var label := node as Label3D
		if is_instance_valid(label):
			label.visible = false

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
