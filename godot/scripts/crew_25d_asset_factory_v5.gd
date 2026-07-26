class_name Crew25DAssetFactoryV5
extends RefCounted

const ATLAS_COLUMNS := 5
const ATLAS_ROWS := 2
const SOURCE_CELL_SIZE := 48
const OUTPUT_SIZE := 256

static var _texture_cache: Dictionary = {}
static var _atlas_cache: Dictionary = {}

static func texture_for(profile: Dictionary) -> Texture2D:
	var crew_id := String(profile.get("crew_id", ""))
	var member_id := String(profile.get("id", ""))
	var cache_key := "%s:%s" % [crew_id, member_id]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var atlas_path := String(profile.get("atlas", ""))
	var atlas := _load_reference_atlas(atlas_path)
	if atlas == null or atlas.is_empty():
		push_error("Atlas 2.5D de référence introuvable : %s" % atlas_path)
		return _missing_texture(cache_key)

	var atlas_index := clampi(int(profile.get("atlas_index", 0)), 0, ATLAS_COLUMNS * ATLAS_ROWS - 1)
	var column := atlas_index % ATLAS_COLUMNS
	var row := atlas_index / ATLAS_COLUMNS
	var source_rect := Rect2i(column * SOURCE_CELL_SIZE, row * SOURCE_CELL_SIZE, SOURCE_CELL_SIZE, SOURCE_CELL_SIZE)
	var sprite_image := atlas.get_region(source_rect)
	# Agrandissement pour conserver le pipeline 256 × 256 déjà utilisé par les
	# personnages 2.5D. Le contenu vient directement des références envoyées.
	sprite_image.resize(OUTPUT_SIZE, OUTPUT_SIZE, Image.INTERPOLATE_LANCZOS)
	var texture := ImageTexture.create_from_image(sprite_image)
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
	var expected_size := Vector2i(ATLAS_COLUMNS * SOURCE_CELL_SIZE, ATLAS_ROWS * SOURCE_CELL_SIZE)
	if image.get_size() != expected_size:
		push_error("Dimensions d’atlas invalides pour %s : %s au lieu de %s" % [path, image.get_size(), expected_size])
		return null
	_atlas_cache[path] = image
	return image

static func _missing_texture(cache_key: String) -> Texture2D:
	var image := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for value in range(32, OUTPUT_SIZE - 32):
		for thickness in range(-4, 5):
			var a := value + thickness
			var b := OUTPUT_SIZE - 1 - value + thickness
			if a >= 0 and a < OUTPUT_SIZE:
				image.set_pixel(a, value, Color(0.9, 0.1, 0.1, 0.9))
			if b >= 0 and b < OUTPUT_SIZE:
				image.set_pixel(b, value, Color(0.9, 0.1, 0.1, 0.9))
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture
