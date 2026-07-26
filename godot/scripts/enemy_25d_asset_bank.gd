class_name Enemy25DAssetBank
extends RefCounted

# Banque mémoire strictement limitée à l’île active. Les sept personnages
# importants de cette île (boss, 3 commandants, 3 nakamas) partagent un atlas.
# Même avec 9 îles et 63 personnages importants, une seule île reste chargée.
const COMPACT_ROOT := "res://assets/roster25d/compact"
const CHUNK_ROOT := "res://assets/roster25d/chunks"
const SOURCE_SHEET_SIZE := Vector2(320.0, 240.0)
const CHARACTER_OUTPUT_SIZE := 384
const FACTION_ROOT := "res://assets/faction25d"
const FACTION_CHUNK_ROOT := "res://assets/faction25d/chunks"
const FACTION_COLUMNS := 5
const FACTION_ROWS := 2

static var _active_zone := -1
static var _texture_cache: Dictionary = {}
static var _missing_logged: Dictionary = {}

static func activate_zone(zone: int) -> void:
	var resolved := clampi(zone, 0, Enemy25DCatalog.ISLANDS.size() - 1)
	if resolved == _active_zone:
		return
	clear_active_zone()
	_active_zone = resolved
	print("CHK_25D_ASSET_BANK_ACTIVE zone=%d" % resolved)

static func clear_active_zone() -> void:
	_texture_cache.clear()
	_missing_logged.clear()
	_active_zone = -1

static func active_zone() -> int:
	return _active_zone

static func cached_texture_count() -> int:
	return _texture_cache.size()

static func asset_for_profile(profile: Dictionary) -> Dictionary:
	var zone := clampi(int(profile.get("atlas_zone", profile.get("zone", 0))), 0, Enemy25DCatalog.ISLANDS.size() - 1)
	if zone != _active_zone:
		activate_zone(zone)
	var rank := String(profile.get("rank", ""))
	if not ["boss", "commandant", "nakama"].has(rank):
		return {}

	var faction_asset := String(profile.get("faction_asset", ""))
	if not faction_asset.is_empty():
		var faction_texture := _faction_character_texture(faction_asset, int(profile.get("faction_index", 0)))
		if faction_texture != null:
			return {
				"texture": faction_texture,
				"animated": false,
				"hframes": 1,
				"vframes": 1,
				"source": "hq_isolated_faction_asset"
			}

	if zone == 0 and rank == "boss":
		var brakor := Boss25DEmbeddedAssets.texture_for_zone(0)
		if brakor != null:
			return {
				"texture": brakor,
				"animated": false,
				"hframes": 1,
				"vframes": 1,
				"source": "embedded_official_brakor"
			}

	var character_texture := _atlas_region_texture(zone, profile)
	if character_texture != null:
		return {
			"texture": character_texture,
			"animated": false,
			"hframes": 1,
			"vframes": 1,
			"source": "cleaned_island_atlas"
		}

	_log_missing_once(
		"%d:%s" % [zone, String(profile.get("id", "unknown"))],
		"Asset 2.5D manquant zone=%d personnage=%s" % [zone, String(profile.get("name", "personnage"))]
	)
	return {}


static func _faction_character_texture(asset_name: String, character_index: int) -> Texture2D:
	var resolved_index := maxi(0, character_index)
	var cache_key := "faction_region:%s:%d" % [asset_name, resolved_index]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var sheet := _faction_atlas_texture(asset_name)
	if sheet == null:
		return null
	var image := sheet.get_image()
	if image == null or image.is_empty():
		_log_missing_once(cache_key, "Atlas de faction illisible : " + asset_name)
		return null
	if image.get_width() % FACTION_COLUMNS != 0 or image.get_height() % FACTION_ROWS != 0:
		_log_missing_once(cache_key, "Dimensions d’atlas de faction invalides : %s %s" % [asset_name, image.get_size()])
		return null
	var cell_width := int(image.get_width() / FACTION_COLUMNS)
	var cell_height := int(image.get_height() / FACTION_ROWS)
	if cell_width <= 1 or cell_height <= 1:
		_log_missing_once(cache_key, "Cellule d’atlas de faction invalide : " + cache_key)
		return null
	var column := resolved_index % FACTION_COLUMNS
	var row := int(resolved_index / FACTION_COLUMNS)
	var region := Rect2i(
		column * cell_width,
		row * cell_height,
		cell_width,
		cell_height
	)
	var sheet_rect := Rect2i(Vector2i.ZERO, image.get_size())
	region = region.intersection(sheet_rect)
	if region.size.x <= 1 or region.size.y <= 1:
		_log_missing_once(cache_key, "Personnage de faction hors atlas : " + cache_key)
		return null
	var source := image.get_region(region)
	var cleaned := CharacterCutout25D.texture_from_region(source, CHARACTER_OUTPUT_SIZE)
	if cleaned == null:
		return null
	_texture_cache[cache_key] = cleaned
	return cleaned

static func _faction_atlas_texture(asset_name: String) -> Texture2D:
	var key := "faction_sheet:" + asset_name
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D
	var encoded := _read_faction_encoded(asset_name)
	if encoded.is_empty():
		_log_missing_once(key, "Atlas haute qualité absent : " + asset_name)
		return null
	var texture := _decode_webp(encoded, "atlas faction " + asset_name)
	if texture != null:
		_texture_cache[key] = texture
		print("CHK_25D_FACTION_ATLAS_READY asset=%s" % asset_name)
	return texture

static func _read_faction_encoded(asset_name: String) -> String:
	var full_path := "%s/%s_atlas.webp.b64" % [FACTION_ROOT, asset_name]
	if FileAccess.file_exists(full_path):
		return FileAccess.get_file_as_string(full_path).strip_edges()
	var encoded := ""
	var chunk_index := 0
	while chunk_index < 64:
		var chunk_path := "%s/%s_%d.b64" % [FACTION_CHUNK_ROOT, asset_name, chunk_index]
		if not FileAccess.file_exists(chunk_path):
			break
		encoded += FileAccess.get_file_as_string(chunk_path).strip_edges()
		chunk_index += 1
	if chunk_index > 0:
		print("CHK_25D_FACTION_CHUNKS_READY asset=%s chunks=%d" % [asset_name, chunk_index])
	return encoded

static func _atlas_region_texture(zone: int, profile: Dictionary) -> Texture2D:
	var cache_key := "region:%d:%s" % [zone, String(profile.get("id", "unknown"))]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var sheet := _island_atlas_texture(zone)
	if sheet == null:
		return null

	var source_region := Rect2(profile.get("atlas_region", Enemy25DCatalog.BOSS_REGION))
	var scale := Vector2(
		float(sheet.get_width()) / SOURCE_SHEET_SIZE.x,
		float(sheet.get_height()) / SOURCE_SHEET_SIZE.y
	)
	var scaled_region := Rect2(source_region.position * scale, source_region.size * scale)
	var sheet_rect := Rect2(Vector2.ZERO, Vector2(sheet.get_width(), sheet.get_height()))
	scaled_region = scaled_region.intersection(sheet_rect)
	if scaled_region.size.x < 1.0 or scaled_region.size.y < 1.0:
		_log_missing_once(cache_key, "Région 2.5D invalide : " + cache_key)
		return null

	var start := Vector2i(
		clampi(int(floor(scaled_region.position.x)), 0, sheet.get_width() - 1),
		clampi(int(floor(scaled_region.position.y)), 0, sheet.get_height() - 1)
	)
	var raw_end := scaled_region.position + scaled_region.size
	var end := Vector2i(
		clampi(int(ceil(raw_end.x)), start.x + 1, sheet.get_width()),
		clampi(int(ceil(raw_end.y)), start.y + 1, sheet.get_height())
	)
	var pixel_region := Rect2i(start, end - start)
	var sheet_image := sheet.get_image()
	if sheet_image == null or sheet_image.is_empty():
		_log_missing_once(cache_key, "Image source 2.5D illisible : " + cache_key)
		return null
	var source := sheet_image.get_region(pixel_region)
	var cleaned := CharacterCutout25D.texture_from_region(source, CHARACTER_OUTPUT_SIZE)
	if cleaned == null:
		_log_missing_once(cache_key, "Détourage 2.5D impossible : " + cache_key)
		return null
	_texture_cache[cache_key] = cleaned
	return cleaned

static func _island_atlas_texture(zone: int) -> Texture2D:
	var key := "sheet:%d" % zone
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D

	var compact_path := "%s/island_%d.b64" % [COMPACT_ROOT, zone]
	var encoded := ""
	var source_path := compact_path
	if FileAccess.file_exists(compact_path):
		encoded = FileAccess.get_file_as_string(compact_path).strip_edges()
	else:
		# Les nouveaux atlas peuvent être découpés pour rester faciles à auditer
		# dans Git. Tous les morceaux consécutifs sont concaténés avant décodage.
		var chunk_index := 0
		while chunk_index < 64:
			var chunk_path := "%s/island_%d_%d.b64" % [CHUNK_ROOT, zone, chunk_index]
			if not FileAccess.file_exists(chunk_path):
				break
			encoded += FileAccess.get_file_as_string(chunk_path).strip_edges()
			chunk_index += 1
		source_path = "%s/island_%d_[0..%d].b64" % [CHUNK_ROOT, zone, chunk_index - 1]

	if encoded.is_empty():
		_log_missing_once(key, "Atlas 2.5D absent pour l’île %d" % zone)
		return null

	var texture := _decode_webp(encoded, "atlas 2.5D île %d" % zone)
	if texture != null:
		_texture_cache[key] = texture
		print("CHK_25D_ATLAS_READY zone=%d path=%s" % [zone, source_path])
	return texture

static func _decode_webp(encoded: String, label: String) -> Texture2D:
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		_log_missing_once(label, "Données WEBP vides : " + label)
		return null
	var image := Image.new()
	var error := image.load_webp_from_buffer(bytes)
	if error != OK or image.is_empty():
		_log_missing_once(label, "Décodage WEBP impossible (%d) : %s" % [error, label])
		return null
	image.convert(Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(image)

static func _log_missing_once(key: String, message: String) -> void:
	if _missing_logged.has(key):
		return
	_missing_logged[key] = true
	push_warning(message)
