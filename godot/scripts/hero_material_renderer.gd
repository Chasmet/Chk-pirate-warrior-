extends Node

# Les héros restent dans le monde 3D : perspective, occultation par les murs,
# distance réelle et caméra 360°. Le shader retire le fond magenta des JPEG
# sans projeter le personnage comme une image collée à l'écran.

const VISIBLE_LAYER := 1
const WORLD_SHADER := preload("res://shaders/hero_chroma_world.gdshader")

var player: PlayerController
var tracked_visual_id := 0
var source_sprite: Sprite3D
var world_material: ShaderMaterial
var tracked_texture: Texture2D
var label_cleanup_timer := 0.0
var renderer_logged := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 2000
	set_process(true)

func _process(delta: float) -> void:
	label_cleanup_timer -= delta
	if label_cleanup_timer <= 0.0:
		label_cleanup_timer = 0.35
		_hide_broken_world_labels()

	if not is_instance_valid(player):
		player = _find_player()
		tracked_visual_id = 0
		renderer_logged = false
		if not is_instance_valid(player):
			return

	if not is_instance_valid(player.hero_visual):
		return
	if player.hero_visual.get_instance_id() != tracked_visual_id:
		tracked_visual_id = player.hero_visual.get_instance_id()
		_bind_current_hero()
	if not is_instance_valid(source_sprite):
		_bind_current_hero()
	if not is_instance_valid(source_sprite) or not is_instance_valid(player.camera):
		return

	_apply_world_space_rules()
	_sync_material()

func _bind_current_hero() -> void:
	source_sprite = null
	world_material = null
	tracked_texture = null
	if not is_instance_valid(player) or not is_instance_valid(player.hero_visual):
		return
	source_sprite = player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if source_sprite == null:
		return
	world_material = ShaderMaterial.new()
	world_material.shader = WORLD_SHADER
	world_material.set_shader_parameter("key_inner", 0.075)
	world_material.set_shader_parameter("key_outer", 0.31)
	world_material.set_shader_parameter("contrast", 1.07)
	world_material.set_shader_parameter("saturation", 1.08)
	source_sprite.material_override = world_material
	_sync_material(true)
	if not renderer_logged:
		renderer_logged = true
		print("CHK_HERO_WORLD_MATERIAL_READY hero=%s depth_test=1 chroma_key=1" % player.hero_id)

func _apply_world_space_rules() -> void:
	source_sprite.layers = VISIBLE_LAYER
	source_sprite.visible = true
	source_sprite.no_depth_test = false
	source_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	source_sprite.double_sided = true
	source_sprite.shaded = false
	source_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Sur le bateau, la cabine, la roue et la voile occupent la même zone de
	# profondeur. Une priorité plus haute garde le héros choisi lisible tout en
	# conservant le test de profondeur et l'intégration réelle dans le monde 3D.
	source_sprite.render_priority = 10 if player.boat_mode else 4
	player.camera.cull_mask |= VISIBLE_LAYER

func _sync_material(force: bool = false) -> void:
	if not is_instance_valid(source_sprite) or world_material == null:
		return
	var texture := source_sprite.texture
	if texture == null:
		source_sprite.visible = false
		return
	if force or texture != tracked_texture:
		tracked_texture = texture
		world_material.set_shader_parameter("albedo_texture", texture)
	world_material.set_shader_parameter("tint", source_sprite.modulate)

func _hide_broken_world_labels() -> void:
	_hide_labels_recursive(get_tree().root)

func _hide_labels_recursive(node: Node) -> void:
	if node is Label3D:
		var label := node as Label3D
		label.visible = false
		label.layers = 1 << 19
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
