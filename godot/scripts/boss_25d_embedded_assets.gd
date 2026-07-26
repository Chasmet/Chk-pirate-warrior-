class_name Boss25DEmbeddedAssets
extends RefCounted

# Première intégration réelle : Brakor, boss du Port des Naufragés.
# L'image est issue de la planche officielle fournie par le créateur et reste
# embarquée dans le dépôt. Aucun téléchargement réseau n'est nécessaire.
const BRAKOR_DATA = preload("res://assets/boss25d/data/island_0_boss_data.gd")

static var _cache: Dictionary = {}

static func texture_for_zone(zone: int) -> Texture2D:
	if zone != 0:
		return null
	if _cache.has(zone):
		return _cache[zone] as Texture2D
	var bytes := Marshalls.base64_to_raw(String(BRAKOR_DATA.DATA))
	if bytes.is_empty():
		push_error("Données 2.5D de Brakor absentes")
		return null
	var image := Image.new()
	var error := image.load_webp_from_buffer(bytes)
	if error != OK or image.is_empty():
		push_error("Décodage WEBP de Brakor impossible : %d" % error)
		return null
	var texture := ImageTexture.create_from_image(image)
	if texture == null:
		push_error("Création de la texture de Brakor impossible")
		return null
	_cache[zone] = texture
	return texture

static func clear_cache() -> void:
	_cache.clear()
