class_name Enemy25DAssetBank
extends RefCounted

# Banque mémoire strictement limitée à l’île active. Les sept personnages
# importants (boss, 3 commandants, 3 nakamas) partagent un atlas embarqué ;
# les 42 textures ne sont donc jamais chargées simultanément.
const ISLAND_ATLAS_DATA := [
	preload("res://scripts/roster_data/island_0_port_data.gd"),
	preload("res://scripts/roster_data/island_1_jungle_data.gd"),
	preload("res://scripts/roster_data/island_2_snow_data.gd"),
	preload("res://scripts/roster_data/island_3_desert_data.gd"),
	preload("res://scripts/roster_data/island_4_volcano_data.gd"),
	preload("res://scripts/roster_data/island_5_storm_data.gd")
]

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
			"source": "embedded_official_island_atlas"
		}

	_log_missing_once("%d:%s" % [zone, String(profile.get("id", "unknown"))], "Asset 2.5D manquant zone=%d personnage=%s" % [zone, String(profile.get("name", "personnage"))])
	return {}

static func _atlas_region_texture(zone: int, profile: Dictionary) -> AtlasTexture:
	var cache_key := "region:%d:%s" % [zone, String(profile.get("id", "unknown"))]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as AtlasTexture
	var sheet := _island_atlas_texture(zone)
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(profile.get("atlas_region", Enemy25DCatalog.BOSS_REGION))
	atlas.filter_clip = true
	_texture_cache[cache_key] = atlas
	return atlas

static func _island_atlas_texture(zone: int) -> Texture2D:
	var key := "sheet:%d" % zone
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D
	if zone < 0 or zone >= ISLAND_ATLAS_DATA.size():
		return null
	var source = ISLAND_ATLAS_DATA[zone]
	var texture := _decode_webp(String(source.WEBP_BASE64), "atlas île %d" % zone)
	if texture != null:
		_texture_cache[key] = texture
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
