class_name Enemy25DCatalog
extends RefCounted

const SHEET_SIZE := Vector2i(1024, 725)
const BOSS_REGION := Rect2(35, 108, 330, 414)
const COMMANDANT_REGIONS := [
	Rect2(382, 104, 202, 260),
	Rect2(574, 104, 202, 260),
	Rect2(766, 104, 242, 260)
]
const NAKAMA_REGIONS := [
	Rect2(382, 346, 202, 195),
	Rect2(574, 346, 202, 195),
	Rect2(766, 346, 242, 195)
]
const ANIMAL_REGIONS := [
	Rect2(12, 535, 250, 184),
	Rect2(252, 535, 250, 184),
	Rect2(492, 535, 250, 184),
	Rect2(732, 535, 280, 184)
]

const ISLANDS := [
	{
		"key":"port", "accent":"b38342", "boss":"Brakor, Gardien du Port",
		"commandants":["Tireur des Quais", "Maître Croc", "Ingénieur des Amarres"],
		"nakama":["Voleur Agile", "Porte-Chaîne", "Guetteur du Phare"],
		"animals":["Crabe Blindé", "Chien des Quais", "Rat des Cales", "Lézard des Jetées"]
	},
	{
		"key":"jungle", "accent":"3f8a46", "boss":"Reine Naja, Maîtresse de la Canopée",
		"commandants":["Chasseur Jaguar", "Chamane des Lianes", "Garde Totem"],
		"nakama":["Singe Voleur", "Pisteur Camouflé", "Lanceur de Dards"],
		"animals":["Sanglier des Fougères", "Serpent des Racines", "Singe Hurleur", "Crocodile de Mangrove"]
	},
	{
		"key":"neige", "accent":"75c6e6", "boss":"Seigneur Givror, Tyran du Blizzard",
		"commandants":["Sentinelle Givrée", "Arbalétrier du Blizzard", "Berserker des Glaces"],
		"nakama":["Éclaireur Polaire", "Alchimiste du Givre", "Pillard des Neiges"],
		"animals":["Loup du Blizzard", "Sanglier des Glaces", "Lézard Polaire", "Serpent de Givre"]
	},
	{
		"key":"desert", "accent":"c69a52", "boss":"Madame Scorpia, Reine des Dunes",
		"commandants":["Lancier Sirocco", "Canonnière des Dunes", "Cavalier des Sables"],
		"nakama":["Voleur des Oasis", "Guetteur des Ruines", "Saboteur du Vent"],
		"animals":["Lézard des Dunes", "Serpent des Sables", "Loup du Désert", "Sanglier d’Oasis"]
	},
	{
		"key":"volcan", "accent":"ff5a24", "boss":"Général Volkan, Seigneur des Braises",
		"commandants":["Marteau Magma", "Pyro-Artilleur", "Garde des Cendres"],
		"nakama":["Sabreur Braise", "Porteur de Scories", "Pisteur de Lave"],
		"animals":["Lézard de Lave", "Crabe de Scories", "Loup des Cendres", "Sanglier Volcanique"]
	},
	{
		"key":"tempete", "accent":"60c8ff", "boss":"Amiral Vorga, Maître des Orages",
		"commandants":["Harponneur de Foudre", "Exécuteur des Remparts", "Navigatrice Tempête"],
		"nakama":["Mousse Orageux", "Saboteur des Haubans", "Éclaireur Électro"],
		"animals":["Crabe des Falaises", "Lézard des Remparts", "Serpent Marinier", "Loup d’Orage"]
	}
]

static var _sheet_cache: Dictionary = {}

static func boss_for_zone(zone: int) -> Dictionary:
	var z := clampi(zone, 0, ISLANDS.size() - 1)
	var island: Dictionary = ISLANDS[z]
	return _make_profile(z, "boss", 0, String(island["boss"]), BOSS_REGION)

static func commandant_for_zone(zone: int, index: int) -> Dictionary:
	var z := clampi(zone, 0, ISLANDS.size() - 1)
	var i := clampi(index, 0, 2)
	var island: Dictionary = ISLANDS[z]
	var names: Array = island["commandants"]
	return _make_profile(z, "commandant", i, String(names[i]), COMMANDANT_REGIONS[i])

static func nakama_for_zone(zone: int, index: int) -> Dictionary:
	var z := clampi(zone, 0, ISLANDS.size() - 1)
	var i := clampi(index, 0, 2)
	var island: Dictionary = ISLANDS[z]
	var names: Array = island["nakama"]
	return _make_profile(z, "nakama", i, String(names[i]), NAKAMA_REGIONS[i])

static func animal_for_zone(zone: int, index: int) -> Dictionary:
	var z := clampi(zone, 0, ISLANDS.size() - 1)
	var i := clampi(index, 0, 3)
	var island: Dictionary = ISLANDS[z]
	var names: Array = island["animals"]
	return _make_profile(z, "animal", i, String(names[i]), ANIMAL_REGIONS[i])

static func commandants_for_zone(zone: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(3):
		result.append(commandant_for_zone(zone, index))
	return result

static func nakama_for_all_commandants(zone: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(3):
		result.append(nakama_for_zone(zone, index))
	return result

static func animals_for_zone(zone: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(4):
		result.append(animal_for_zone(zone, index))
	return result

static func sheet_texture(zone: int) -> Texture2D:
	var z := clampi(zone, 0, ISLANDS.size() - 1)
	if _sheet_cache.has(z):
		return _sheet_cache[z] as Texture2D
	var encoded := _base64_for_zone(z)
	if encoded.is_empty():
		push_error("Planche 2.5D absente pour l'île %d" % z)
		return null
	var image := Image.new()
	var error := image.load_webp_from_buffer(Marshalls.base64_to_raw(encoded))
	if error != OK or image.is_empty():
		push_error("Décodage WebP 2.5D impossible pour l'île %d (erreur %d)" % [z, error])
		return null
	var texture := ImageTexture.create_from_image(image)
	_sheet_cache[z] = texture
	return texture

static func atlas_texture(profile: Dictionary) -> AtlasTexture:
	var sheet := sheet_texture(int(profile.get("atlas_zone", 0)))
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(profile.get("atlas_region", BOSS_REGION))
	atlas.filter_clip = true
	return atlas

static func clear_texture_cache() -> void:
	_sheet_cache.clear()

static func _make_profile(zone: int, rank: String, index: int, display_name: String, region: Rect2) -> Dictionary:
	var island: Dictionary = ISLANDS[zone]
	var zone_factor := 1.0 + float(zone) * 0.18
	var health := 110.0 * zone_factor
	var speed := 3.2 + float(zone) * 0.08
	var damage := 10.0 * zone_factor
	var attack_range := 1.8
	var xp := 38 + zone * 9
	var coins := 18 + zone * 5
	var collision_scale := 1.0
	var pixel_size := 0.0080
	var sprite_y := 1.02
	var visual_layers := 2
	var boss := false
	match rank:
		"boss":
			health = (980.0 + float(zone) * 230.0) * zone_factor
			speed = 2.85 + float(zone) * 0.10
			damage = 25.0 + float(zone) * 3.5
			attack_range = 2.8 + float(zone) * 0.08
			xp = 480 + zone * 155
			coins = 250 + zone * 95
			collision_scale = 1.62
			pixel_size = 0.0071
			sprite_y = 1.48
			visual_layers = 3
			boss = true
		"commandant":
			health = (270.0 + float(index) * 45.0) * zone_factor
			speed = 3.1 + float(index) * 0.22
			damage = (15.0 + float(index) * 1.8) * zone_factor
			attack_range = 2.1 + float(index) * 0.22
			xp = 105 + zone * 25 + index * 12
			coins = 52 + zone * 11 + index * 6
			collision_scale = 1.16
			pixel_size = 0.0082
			sprite_y = 1.10
		"nakama":
			health = (150.0 + float(index) * 24.0) * zone_factor
			speed = 3.8 + float(index) * 0.20
			damage = (10.0 + float(index) * 1.4) * zone_factor
			attack_range = 1.7 + float(index) * 0.18
			xp = 64 + zone * 16 + index * 8
			coins = 30 + zone * 8 + index * 4
			collision_scale = 0.96
			pixel_size = 0.0080
			sprite_y = 0.94
		"animal":
			health = (105.0 + float(index) * 16.0) * zone_factor
			speed = 3.2 + float(index) * 0.30
			damage = (8.0 + float(index)) * zone_factor
			attack_range = 1.45
			xp = 42 + zone * 11 + index * 5
			coins = 18 + zone * 5 + index * 2
			collision_scale = 0.78
			pixel_size = 0.0071
			sprite_y = 0.58
	var safe_id := display_name.to_lower().replace(" ", "_").replace("'", "").replace("’", "").replace("-", "_")
	return {
		"id":"z%d_%s_%d_%s" % [zone, rank, index, safe_id],
		"name":display_name,
		"color":Color(String(island["accent"])),
		"accent":Color(String(island["accent"])).lightened(0.24),
		"health":health,
		"speed":speed,
		"damage":damage,
		"range":attack_range,
		"xp":xp,
		"coins":coins,
		"boss":boss,
		"rank":rank,
		"commander_index":index if rank == "commandant" or rank == "nakama" else -1,
		"visual_25d":true,
		"atlas_zone":zone,
		"atlas_region":region,
		"pixel_size":pixel_size,
		"sprite_y":sprite_y,
		"visual_layers":visual_layers,
		"scale":collision_scale,
		"weapon":"25d_%s" % rank
	}

static func _base64_for_zone(zone: int) -> String:
	match zone:
		0: return Island0PortData.WEBP_BASE64
		1: return Island1JungleData.WEBP_BASE64
		2: return Island2SnowData.WEBP_BASE64
		3: return Island3DesertData.WEBP_BASE64
		4: return Island4VolcanoData.WEBP_BASE64
		5: return Island5StormData.WEBP_BASE64
	return ""
