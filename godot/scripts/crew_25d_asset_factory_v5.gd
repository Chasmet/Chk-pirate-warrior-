class_name Crew25DAssetFactoryV5
extends RefCounted

const ATLAS_COLUMNS := 5
const ATLAS_ROWS := 2
const SOURCE_CELL_SIZE := 48
const OUTPUT_SIZE := 256
const FRAME_COUNT := 4

static var _texture_cache: Dictionary = {}
static var _atlas_cache: Dictionary = {}

static func texture_for(profile: Dictionary) -> Texture2D:
	var crew_id := String(profile.get("crew_id", ""))
	var member_id := String(profile.get("id", ""))
	var cache_key := "%s:%s:v2" % [crew_id, member_id]
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
	var source := atlas.get_region(source_rect)
	_cleanup_connected_black_background(source)
	var fitted := _fit_to_character_canvas(source)
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
	var expected_size := Vector2i(ATLAS_COLUMNS * SOURCE_CELL_SIZE, ATLAS_ROWS * SOURCE_CELL_SIZE)
	if image.get_size() != expected_size:
		push_error("Dimensions d’atlas invalides pour %s : %s au lieu de %s" % [path, image.get_size(), expected_size])
		return null
	image.convert(Image.FORMAT_RGBA8)
	_atlas_cache[path] = image
	return image

# Le fond noir des planches de référence doit disparaître sans supprimer les
# vêtements noirs. Seuls les pixels sombres reliés aux bords sont retirés.
static func _cleanup_connected_black_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))
	var cursor := 0
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		var offset := point.y * width + point.x
		if visited[offset] == 1:
			continue
		visited[offset] = 1
		var color := image.get_pixelv(point)
		var luminance := maxf(color.r, maxf(color.g, color.b))
		if color.a < 0.02 or luminance < 0.115:
			image.set_pixelv(point, Color(0, 0, 0, 0))
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := point + direction
				if next.x >= 0 and next.x < width and next.y >= 0 and next.y < height:
					queue.append(next)

static func _fit_to_character_canvas(source: Image) -> Image:
	var used := source.get_used_rect()
	var canvas := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	if used.size.x <= 1 or used.size.y <= 1:
		return canvas
	var character := source.get_region(used)
	var maximum_width := 226.0
	var maximum_height := 238.0
	var scale_factor := minf(maximum_width / float(character.get_width()), maximum_height / float(character.get_height()))
	var target_size := Vector2i(
		maxi(1, roundi(float(character.get_width()) * scale_factor)),
		maxi(1, roundi(float(character.get_height()) * scale_factor))
	)
	character.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var destination := Vector2i((OUTPUT_SIZE - target_size.x) / 2, OUTPUT_SIZE - target_size.y - 7)
	canvas.blit_rect(character, Rect2i(Vector2i.ZERO, target_size), destination)
	return canvas

# Même principe que les planches des héros : quatre poses dans une bande.
# Les variations sont légères pour préserver exactement l’apparence fournie.
static func _build_pose_strip(character: Image) -> Image:
	var strip := Image.create(OUTPUT_SIZE * FRAME_COUNT, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	var shifts := [Vector2i(0, 0), Vector2i(-2, -2), Vector2i(2, 0), Vector2i(0, -4)]
	for frame in range(FRAME_COUNT):
		strip.blit_rect(character, Rect2i(0, 0, OUTPUT_SIZE, OUTPUT_SIZE), Vector2i(frame * OUTPUT_SIZE, 0) + shifts[frame])
	return strip

static func _missing_texture(cache_key: String) -> Texture2D:
	var image := Image.create(OUTPUT_SIZE * FRAME_COUNT, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(FRAME_COUNT):
		var frame_x := frame * OUTPUT_SIZE
		for value in range(32, OUTPUT_SIZE - 32):
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
