class_name RegionCatalogV11
extends RefCounted

const REGION_COUNT := 11
const NPCS_PER_LIVING_REGION := RegionCatalogV9.NPCS_PER_REGION
const TOTAL_NPCS := RegionCatalogV9.TOTAL_NPCS
const FINAL_REGION_INDEX := 10

const FINAL_REGION := {
	"id":"royaume_trouble",
	"name":"Royaume Troublé",
	"subtitle":"Souvenirs oubliés, brume dorée et fin de l’aventure",
	"center":Vector3(5320.0, 2.0, 1040.0),
	"radius":365.0,
	"elevation":2.0,
	"color":"4a3d31",
	"accent":"f3c85b",
	"weather":["brume dorée", "silence", "lueurs de mémoire"],
	"jobs":[],
	"fauna":[],
	"final_region":true,
	"rare_item":"Cœur des Souvenirs",
	"pois":[
		{"name":"Porte des Souvenirs", "kind":"porte_flottante", "offset":Vector3(-188, 12, -104)},
		{"name":"Palais des Heures Perdues", "kind":"palais", "offset":Vector3(36, 10, -126)},
		{"name":"Horloge du Dernier Jour", "kind":"horloge", "offset":Vector3(182, 18, -42)},
		{"name":"Bibliothèque Oubliée", "kind":"bibliotheque", "offset":Vector3(-126, 6, 112)},
		{"name":"Galerie des Miroirs Brisés", "kind":"miroir", "offset":Vector3(126, 8, 116)},
		{"name":"Place des Noms Effacés", "kind":"place", "offset":Vector3(0, 3, 18)},
		{"name":"Fragments de Mémoire", "kind":"fragment_memoire", "offset":Vector3(-18, 14, 196)},
		{"name":"Tour Sans Aiguilles", "kind":"tour", "offset":Vector3(214, 30, 168)},
		{"name":"Pont du Retour Impossible", "kind":"pont", "offset":Vector3(-224, 6, 32)},
		{"name":"Sanctuaire du Cœur", "kind":"sanctuaire", "offset":Vector3(18, 7, 72)}
	]
}

static func all_regions() -> Array:
	var result := RegionCatalogV9.all_regions()
	result.append(FINAL_REGION.duplicate(true))
	return result

static func region(index: int) -> Dictionary:
	var regions := all_regions()
	return (regions[clampi(index, 0, regions.size() - 1)] as Dictionary).duplicate(true)

static func npc_count_for_region(region_index: int) -> int:
	return 0 if region_index == FINAL_REGION_INDEX else NPCS_PER_LIVING_REGION

static func npc_profile(region_index: int, npc_index: int) -> Dictionary:
	if region_index == FINAL_REGION_INDEX:
		return {}
	return RegionCatalogV9.npc_profile(region_index, npc_index)

static func is_final_region(region_index: int) -> bool:
	return region_index == FINAL_REGION_INDEX

static func final_relic_position() -> Vector3:
	var center := Vector3(FINAL_REGION["center"])
	var sanctuary: Dictionary = FINAL_REGION["pois"][9]
	var offset := Vector3(sanctuary["offset"])
	return Vector3(center.x + offset.x, float(FINAL_REGION["elevation"]) + 2.6, center.z + offset.z)

static func validate() -> Array[String]:
	var errors := RegionCatalogV9.validate()
	var regions := all_regions()
	if regions.size() != REGION_COUNT:
		errors.append("V11 doit contenir exactement onze régions.")
	if not bool(FINAL_REGION.get("final_region", false)):
		errors.append("Le Royaume Troublé doit être marqué comme région finale.")
	if not (FINAL_REGION.get("jobs", []) as Array).is_empty() or not (FINAL_REGION.get("fauna", []) as Array).is_empty():
		errors.append("Le Royaume Troublé doit rester abandonné, sans habitants ni animaux.")
	if (FINAL_REGION.get("pois", []) as Array).size() < 10:
		errors.append("Le Royaume Troublé doit posséder au moins dix lieux conçus manuellement.")
	if String(FINAL_REGION.get("rare_item", "")).is_empty():
		errors.append("La région finale doit contenir un objet rare.")
	return errors
