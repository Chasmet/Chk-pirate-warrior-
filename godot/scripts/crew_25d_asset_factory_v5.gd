class_name Crew25DAssetFactoryV5
extends RefCounted

const FRAME_SIZE := 256
static var _cache: Dictionary = {}

static func texture_for(profile: Dictionary) -> Texture2D:
	var key := "%s:%s" % [String(profile.get("crew_id", "crew")), String(profile.get("id", "member"))]
	if _cache.has(key):
		return _cache[key] as Texture2D
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var body := Color(String(profile.get("body", "526170")))
	var accent := Color(String(profile.get("accent", "e4c275")))
	var skin := Color("c98e68")
	var seed := abs(key.hash())
	var tall := 8 + seed % 18
	var broad := 52 + seed % 24
	var head_radius := 28 + seed % 8

	# Ombre au sol et jambes : pivot visuel constant aux pieds.
	_fill_ellipse(image, Vector2i(128, 229), Vector2i(47, 10), Color(0, 0, 0, 0.28))
	_fill_rect_safe(image, Rect2i(93, 167, 27, 58), body.darkened(0.18))
	_fill_rect_safe(image, Rect2i(136, 167, 27, 58), body.darkened(0.24))
	_fill_rect_safe(image, Rect2i(88, 218, 38, 10), Color("302925"))
	_fill_rect_safe(image, Rect2i(132, 218, 40, 10), Color("302925"))

	# Torse, manteau et ceinture.
	_fill_ellipse(image, Vector2i(128, 137), Vector2i(broad, 62 + tall), body)
	_fill_rect_safe(image, Rect2i(76, 128, 104, 13), accent.darkened(0.12))
	_fill_rect_safe(image, Rect2i(78, 158, 100, 10), accent)
	_fill_rect_safe(image, Rect2i(118, 158, 20, 15), Color("d8b14c"))

	# Bras et mains.
	_fill_capsule(image, Vector2i(70, 137), Vector2i(20, 61), body.darkened(0.08))
	_fill_capsule(image, Vector2i(186, 137), Vector2i(20, 61), body.darkened(0.08))
	_fill_circle(image, Vector2i(68, 176), 13, skin)
	_fill_circle(image, Vector2i(188, 176), 13, skin)

	# Tête, oreilles, cheveux et expression.
	_fill_circle(image, Vector2i(128, 70), head_radius, skin)
	_fill_circle(image, Vector2i(98, 71), 7, skin.darkened(0.05))
	_fill_circle(image, Vector2i(158, 71), 7, skin.darkened(0.05))
	var hair := Color("24242a") if seed % 3 != 0 else accent.darkened(0.35)
	_fill_ellipse(image, Vector2i(128, 49), Vector2i(head_radius + 5, 19), hair)
	_fill_rect_safe(image, Rect2i(103, 50, 9, 22), hair)
	_fill_rect_safe(image, Rect2i(145, 49, 9, 24), hair)
	_fill_rect_safe(image, Rect2i(112, 70, 9, 5), Color("1a1716"))
	_fill_rect_safe(image, Rect2i(136, 70, 9, 5), Color("1a1716"))
	_fill_rect_safe(image, Rect2i(119, 89, 20, 4), Color("6f342d"))

	# Accessoire distinct par rôle, afin que chaque silhouette reste lisible.
	var role := String(profile.get("role", "pirate"))
	if role in ["capitaine", "second"]:
		_fill_rect_safe(image, Rect2i(88, 29, 80, 12), accent)
		_fill_ellipse(image, Vector2i(128, 35), Vector2i(31, 15), accent.darkened(0.15))
	elif role in ["tireuse", "canonnier", "éclaireuse"]:
		_fill_rect_safe(image, Rect2i(178, 112, 10, 86), Color("332b27"))
		_fill_rect_safe(image, Rect2i(166, 110, 36, 9), accent)
	elif role in ["sabreur", "duelliste", "espion"]:
		_fill_rect_safe(image, Rect2i(55, 95, 8, 110), Color("d9e4e8"))
		_fill_rect_safe(image, Rect2i(47, 191, 24, 8), accent)
	elif role in ["charpentier", "briseur", "gardien"]:
		_fill_circle(image, Vector2i(67, 178), 18, accent)
		_fill_circle(image, Vector2i(189, 178), 18, accent)
	elif role in ["médecin", "historien"]:
		_fill_rect_safe(image, Rect2i(111, 30, 34, 8), Color("eee9dc"))
		_fill_rect_safe(image, Rect2i(124, 17, 8, 34), Color("eee9dc"))
	else:
		_fill_rect_safe(image, Rect2i(99, 31, 58, 9), accent)

	# Bordure lumineuse légère pour la profondeur 2.5D.
	_outline_alpha(image, accent.lightened(0.18))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

static func clear_cache() -> void:
	_cache.clear()

static func _fill_rect_safe(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE))
	if clipped.size.x > 0 and clipped.size.y > 0:
		image.fill_rect(clipped, color)

static func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_sq := radius * radius
	for y in range(maxi(0, center.y - radius), mini(FRAME_SIZE, center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(FRAME_SIZE, center.x + radius + 1)):
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= radius_sq:
				image.set_pixel(x, y, color)

static func _fill_ellipse(image: Image, center: Vector2i, radii: Vector2i, color: Color) -> void:
	var rx := maxf(float(radii.x), 1.0)
	var ry := maxf(float(radii.y), 1.0)
	for y in range(maxi(0, center.y - radii.y), mini(FRAME_SIZE, center.y + radii.y + 1)):
		for x in range(maxi(0, center.x - radii.x), mini(FRAME_SIZE, center.x + radii.x + 1)):
			var nx := float(x - center.x) / rx
			var ny := float(y - center.y) / ry
			if nx * nx + ny * ny <= 1.0:
				image.set_pixel(x, y, color)

static func _fill_capsule(image: Image, center: Vector2i, size: Vector2i, color: Color) -> void:
	var radius := size.x / 2
	_fill_rect_safe(image, Rect2i(center.x - radius, center.y - size.y / 2 + radius, size.x, size.y - radius * 2), color)
	_fill_circle(image, Vector2i(center.x, center.y - size.y / 2 + radius), radius, color)
	_fill_circle(image, Vector2i(center.x, center.y + size.y / 2 - radius), radius, color)

static func _outline_alpha(image: Image, color: Color) -> void:
	var copy := image.duplicate()
	for y in range(1, FRAME_SIZE - 1):
		for x in range(1, FRAME_SIZE - 1):
			if copy.get_pixel(x, y).a > 0.02:
				continue
			var adjacent := false
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if copy.get_pixel(x + ox, y + oy).a > 0.55:
						adjacent = true
			if adjacent:
				image.set_pixel(x, y, Color(color, 0.44))
