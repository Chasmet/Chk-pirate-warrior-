class_name Enemy25DAssetBank
extends RefCounted

# Banque mémoire strictement limitée à l’île active. Les sept personnages
# importants de cette île (boss, 3 commandants, 3 nakamas) partagent un atlas.
# Même avec 9 îles et 63 personnages importants, une seule île reste chargée.
const COMPACT_ROOT := "res://assets/roster25d/compact"
const CHUNK_ROOT := "res://assets/roster25d/chunks"
const SOURCE_SHEET_SIZE := Vector2(320.0, 240.0)

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

	# Brakor garde son image officielle détaillée déjà validée sur téléphone.
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

	var atlas_texture := _atlas_region_texture(zone, profile)
	if atlas_texture != null:
		return {
			"texture": atlas_texture,
			"animated": false,
			"hframes": 1,
			"vframes": 1,
			"source": "embedded_island_atlas"
		}

	_log_missing_once(
		"%d:%s" % [zone, String(profile.get("id", "unknown"))],
		"Asset 2.5D manquant zone=%d personnage=%s" % [zone, String(profile.get("name", "personnage"))]
	)
	return {}

static func _atlas_region_texture(zone: int, profile: Dictionary) -> AtlasTexture:
	var cache_key := "region:%d:%s" % [zone, String(profile.get("id", "unknown"))]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as AtlasTexture
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

	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = scaled_region
	atlas.filter_clip = true
	_texture_cache[cache_key] = atlas
	return atlas

static func _island_atlas_texture(zone: int) -> Texture2D:
	var key := "sheet:%d" % zone
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D

	# Les six atlas historiques restent dans compact/. Les nouveaux assets
	# peuvent être déposés en morceaux dans chunks/ sans modifier le moteur.
	var candidates := [
		"%s/island_%d.b64" % [COMPACT_ROOT, zone],
		"%s/island_%d_0.b64" % [CHUNK_ROOT, zone]
	]
	var path := ""
	for candidate in candidates:
		if FileAccess.file_exists(String(candidate)):
			path = String(candidate)
			break
	if path.is_empty():
		_log_missing_once(key, "Atlas 2.5D absent pour l’île %d : %s" % [zone, ", ".join(candidates)])
		return null

	var encoded := FileAccess.get_file_as_string(path).strip_edges()
	var texture := _decode_webp(encoded, "atlas 2.5D île %d" % zone)
	if texture != null:
		_texture_cache[key] = texture
		print("CHK_25D_ATLAS_READY zone=%d path=%s" % [zone, path])
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
	return ImageTexture.create_from_image(image)

static func _log_missing_once(key: String, message: String) -> void:
	if _missing_logged.has(key):
		return
	_missing_logged[key] = true
	push_warning(message)
