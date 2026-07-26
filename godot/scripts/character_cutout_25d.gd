class_name CharacterCutout25D
extends RefCounted

const DEFAULT_OUTPUT_SIZE := 384
const BORDER := 4

static func texture_from_region(source: Image, output_size: int = DEFAULT_OUTPUT_SIZE) -> Texture2D:
	var normalized := normalized_image(source, output_size)
	if normalized == null or normalized.is_empty():
		return null
	return ImageTexture.create_from_image(normalized)

static func normalized_image(source: Image, output_size: int = DEFAULT_OUTPUT_SIZE) -> Image:
	var canvas := Image.create(output_size, output_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	if source == null or source.is_empty():
		return canvas

	var image := source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var background := _dominant_edge_color(image)
	var padded := Image.create(image.get_width() + BORDER * 2, image.get_height() + BORDER * 2, false, Image.FORMAT_RGBA8)
	padded.fill(background)
	padded.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(BORDER, BORDER))
	_remove_edge_background(padded, background)
	_remove_dark_halo(padded)

	var used := padded.get_used_rect()
	if used.size.x <= 1 or used.size.y <= 1:
		return canvas
	var character := padded.get_region(used)
	var maximum_width := float(output_size) * 0.90
	var maximum_height := float(output_size) * 0.93
	var scale_factor := minf(
		maximum_width / maxf(1.0, float(character.get_width())),
		maximum_height / maxf(1.0, float(character.get_height()))
	)
	var target_size := Vector2i(
		maxi(1, roundi(float(character.get_width()) * scale_factor)),
		maxi(1, roundi(float(character.get_height()) * scale_factor))
	)
	character.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var destination := Vector2i((output_size - target_size.x) / 2, output_size - target_size.y - maxi(5, output_size / 48))
	canvas.blit_rect(character, Rect2i(Vector2i.ZERO, target_size), destination)
	return canvas

static func _dominant_edge_color(image: Image) -> Color:
	var buckets: Dictionary = {}
	var width := image.get_width()
	var height := image.get_height()
	for x in range(width):
		_add_edge_bucket(buckets, image.get_pixel(x, 0))
		_add_edge_bucket(buckets, image.get_pixel(x, height - 1))
	for y in range(1, height - 1):
		_add_edge_bucket(buckets, image.get_pixel(0, y))
		_add_edge_bucket(buckets, image.get_pixel(width - 1, y))
	var best_key := "0:0:0"
	var best_count := -1
	for key in buckets.keys():
		var count := int(buckets[key])
		if count > best_count:
			best_count = count
			best_key = String(key)
	var parts := best_key.split(":")
	return Color(float(parts[0]) / 15.0, float(parts[1]) / 15.0, float(parts[2]) / 15.0, 1.0)

static func _add_edge_bucket(buckets: Dictionary, color: Color) -> void:
	if color.a < 0.05:
		return
	var key := "%d:%d:%d" % [
		clampi(roundi(color.r * 15.0), 0, 15),
		clampi(roundi(color.g * 15.0), 0, 15),
		clampi(roundi(color.b * 15.0), 0, 15)
	]
	buckets[key] = int(buckets.get(key, 0)) + 1

static func _remove_edge_background(image: Image, background: Color) -> void:
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
		var point: Vector2i = queue[cursor]
		cursor += 1
		var offset := point.y * width + point.x
		if visited[offset] == 1:
			continue
		visited[offset] = 1
		var color := image.get_pixelv(point)
		if not _is_background(color, background):
			continue
		image.set_pixelv(point, Color(0, 0, 0, 0))
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_point := point + direction
			if next_point.x >= 0 and next_point.x < width and next_point.y >= 0 and next_point.y < height:
				queue.append(next_point)

static func _is_background(color: Color, background: Color) -> bool:
	if color.a < 0.035:
		return true
	var distance := Vector3(color.r - background.r, color.g - background.g, color.b - background.b).length()
	if distance < 0.26:
		return true
	var maximum := maxf(color.r, maxf(color.g, color.b))
	var minimum := minf(color.r, minf(color.g, color.b))
	var background_maximum := maxf(background.r, maxf(background.g, background.b))
	var background_minimum := minf(background.r, minf(background.g, background.b))
	if background_maximum < 0.25 and maximum < 0.22:
		return true
	if background_minimum > 0.76 and minimum > 0.80:
		return true
	return false

static func _remove_dark_halo(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var copy := image.duplicate()
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var color := copy.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var touches_transparency := false
			for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if copy.get_pixelv(Vector2i(x, y) + direction).a < 0.05:
					touches_transparency = true
					break
			if not touches_transparency:
				continue
			var maximum := maxf(color.r, maxf(color.g, color.b))
			if maximum < 0.12:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a *= 0.88
				image.set_pixel(x, y, color)
