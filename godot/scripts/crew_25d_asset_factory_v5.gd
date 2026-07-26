class_name Crew25DAssetFactoryV5
extends RefCounted

const ATLAS_COLUMNS := 5
const ATLAS_ROWS := 2
const OUTPUT_SIZE := 320
const CONTENT_HEIGHT := 298.0
const FRAME_COUNT := 4

static var _texture_cache: Dictionary = {}
static var _atlas_cache: Dictionary = {}

static func texture_for(profile: Dictionary) -> Texture2D:
	var crew_id := String(profile.get("crew_id", ""))
	var member_id := String(profile.get("id", ""))
	var cache_key := "%s:%s:v3" % [crew_id, member_id]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var atlas_path := String(profile.get("atlas", ""))
	var atlas := _load_reference_atlas(atlas_path)
	if atlas == null or atlas.is_empty():
		push_error("Atlas 2.5D de référence introuvable : %s" % atlas_path)
		return _missing_texture(cache_key)

	var cell_width := int(atlas.get_width() / ATLAS_COLUMNS)
	var cell_height := int(atlas.get_height() / ATLAS_ROWS)
	var atlas_index := clampi(int(profile.get("atlas_index", 0)), 0, ATLAS_COLUMNS * ATLAS_ROWS - 1)
	var column := atlas_index % ATLAS_COLUMNS
	var row := int(atlas_index / ATLAS_COLUMNS)
	var source_rect := Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
	var source := atlas.get_region(source_rect)
	var fitted := CharacterCutout25D.normalized_image(source, OUTPUT_SIZE)
	var strip := _build_pose_strip(fitted)
	var texture := ImageTexture.create_from_image(strip)
	_texture_cache[cache_key] = texture
	return texture

static func clear_cache() -> void:
	_texture_cache.clear()
	_atlas_cache.clear()

static func _load_reference_atlas(path: String) -> Image:
	if path.is_empty():
		return null
	if _atlas_cache.has(path):
		return _atlas_cache[path] as Image
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var encoded := file.get_as_text().strip_edges()
	var raw := Marshalls.base64_to_raw(encoded)
	if raw.is_empty():
		return null
	var image := Image.new()
	var error := image.load_webp_from_buffer(raw)
	if error != OK:
		push_error("Décodage WebP impossible pour %s : %s" % [path, error_string(error)])
		return null
	if image.get_width() < ATLAS_COLUMNS * 32 or image.get_height() < ATLAS_ROWS * 32:
		push_error("Atlas trop petit pour %s : %s" % [path, image.get_size()])
		return null
	if image.get_width() % ATLAS_COLUMNS != 0 or image.get_height() % ATLAS_ROWS != 0:
		push_error("Dimensions d’atlas non divisibles pour %s : %s" % [path, image.get_size()])
		return null
	image.convert(Image.FORMAT_RGBA8)
	_atlas_cache[path] = image
	return image

# Quatre états lisibles dans le monde 3D : attente, deux pas de marche et attaque.
# La silhouette reste identique ; seules l’amplitude et la position changent.
static func _build_pose_strip(character: Image) -> Image:
	var strip := Image.create(OUTPUT_SIZE * FRAME_COUNT, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	var used := character.get_used_rect()
	if used.size.x <= 1 or used.size.y <= 1:
		return strip
	var base := character.get_region(used)
	var scales := [1.0, 0.985, 1.015, 1.045]
	var shifts: Array[Vector2i] = [Vector2i.ZERO, Vector2i(-4, 2), Vector2i(4, -1), Vector2i(9, -4)]
	for frame in range(FRAME_COUNT):
		var variant := base.duplicate()
		var target_size := Vector2i(
			maxi(1, roundi(float(base.get_width()) * float(scales[frame]))),
			maxi(1, roundi(float(base.get_height()) * float(scales[frame])))
		)
		variant.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		var frame_canvas := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
		frame_canvas.fill(Color(0, 0, 0, 0))
		var destination := Vector2i((OUTPUT_SIZE - target_size.x) / 2, OUTPUT_SIZE - target_size.y - 7) + shifts[frame]
		frame_canvas.blit_rect(variant, Rect2i(Vector2i.ZERO, target_size), destination)
		strip.blit_rect(frame_canvas, Rect2i(0, 0, OUTPUT_SIZE, OUTPUT_SIZE), Vector2i(frame * OUTPUT_SIZE, 0))
	return strip

static func _missing_texture(cache_key: String) -> Texture2D:
	var image := Image.create(OUTPUT_SIZE * FRAME_COUNT, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(FRAME_COUNT):
		var frame_x := frame * OUTPUT_SIZE
		for value in range(42, OUTPUT_SIZE - 42):
			for thickness in range(-4, 5):
				var a := value + thickness
				var b := OUTPUT_SIZE - 1 - value + thickness
				if a >= 0 and a < OUTPUT_SIZE:
					image.set_pixel(frame_x + a, value, Color(0.9, 0.1, 0.1, 0.9))
				if b >= 0 and b < OUTPUT_SIZE:
					image.set_pixel(frame_x + b, value, Color(0.9, 0.1, 0.1, 0.9))
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture
