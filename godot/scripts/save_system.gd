class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://chk_pirate_v2_save.json"
const BACKUP_PATH := "user://chk_pirate_v2_save.backup.json"
const TEMP_PATH := "user://chk_pirate_v2_save.tmp.json"
const MAX_ZONE_INDEX := 8

static func default_data() -> Dictionary:
	return {
		"save_version": 5,
		"hero": "cheikh",
		"zone": 0,
		"destination_zone": 1,
		"unlocked_zones": [0],
		"difficulty": "intermediaire",
		"level": 1,
		"xp": 0,
		"coins": 250,
		"training": {"force": 0, "vitesse": 0, "energie": 0},
		"bosses": [],
		"voice": true,
		"quality": "élevée",
		"crew_relations": {"strawhat":"neutral", "redhair":"neutral"},
		"has_exact_position": false,
		"exact_position": [0.0, 8.0, 0.0],
		"exact_rotation_y": 0.0,
		"exact_camera_yaw": 0.0,
		"exact_boat_mode": false,
		"exact_boat_heading": 0.0,
		"exact_boat_speed": 0.0
	}

static func load_data() -> Dictionary:
	var primary := _load_dictionary(SAVE_PATH)
	if not primary.is_empty():
		return sanitize_data(primary)
	var backup := _load_dictionary(BACKUP_PATH)
	if not backup.is_empty():
		push_warning("Sauvegarde principale illisible : restauration de la copie de secours")
		var restored := sanitize_data(backup)
		save_data(restored)
		return restored
	return default_data()

static func sanitize_data(raw: Dictionary) -> Dictionary:
	var result := default_data()
	for key in raw.keys():
		result[key] = raw[key]

	var hero := String(result.get("hero", "cheikh"))
	result["hero"] = hero if hero in ["cheikh", "yvane", "nelvyn"] else "cheikh"
	result["zone"] = clampi(int(result.get("zone", 0)), 0, MAX_ZONE_INDEX)
	result["destination_zone"] = clampi(int(result.get("destination_zone", 1)), 0, MAX_ZONE_INDEX)
	var difficulty := String(result.get("difficulty", "intermediaire"))
	result["difficulty"] = difficulty if difficulty in ["decouverte", "intermediaire", "difficile"] else "intermediaire"
	result["level"] = clampi(int(result.get("level", 1)), 1, 999)
	result["xp"] = maxi(0, int(result.get("xp", 0)))
	result["coins"] = maxi(0, int(result.get("coins", 250)))
	result["save_version"] = 5

	var training: Dictionary = result.get("training", {}) if result.get("training", {}) is Dictionary else {}
	result["training"] = {
		"force": clampi(int(training.get("force", 0)), 0, 100),
		"vitesse": clampi(int(training.get("vitesse", 0)), 0, 100),
		"energie": clampi(int(training.get("energie", 0)), 0, 100)
	}

	var unlocked: Array = [0]
	var raw_unlocked: Variant = result.get("unlocked_zones", [0])
	if raw_unlocked is Array:
		for item in raw_unlocked as Array:
			var zone_index := clampi(int(item), 0, MAX_ZONE_INDEX)
			if not unlocked.has(zone_index):
				unlocked.append(zone_index)
	if not unlocked.has(int(result["zone"])):
		unlocked.append(int(result["zone"]))
	unlocked.sort()
	result["unlocked_zones"] = unlocked

	var relations: Dictionary = result.get("crew_relations", {}) if result.get("crew_relations", {}) is Dictionary else {}
	if relations.has("aurore") and not relations.has("strawhat"):
		relations["strawhat"] = relations["aurore"]
	if relations.has("ecarlate") and not relations.has("redhair"):
		relations["redhair"] = relations["ecarlate"]
	relations.erase("aurore")
	relations.erase("ecarlate")
	for faction in ["strawhat", "redhair"]:
		var attitude := String(relations.get(faction, "neutral"))
		relations[faction] = attitude if attitude in ["allied", "neutral", "hostile"] else "neutral"
	result["crew_relations"] = relations

	var exact_valid := bool(result.get("has_exact_position", false))
	var raw_position: Variant = result.get("exact_position", [])
	if raw_position is Array and (raw_position as Array).size() >= 3:
		var values := raw_position as Array
		var px := float(values[0])
		var py := float(values[1])
		var pz := float(values[2])
		exact_valid = exact_valid and is_finite(px) and is_finite(py) and is_finite(pz)
		exact_valid = exact_valid and absf(px) <= 2750.0 and py >= -24.0 and py <= 320.0 and absf(pz) <= 1400.0
		result["exact_position"] = [px, py, pz] if exact_valid else [0.0, 8.0, 0.0]
	else:
		exact_valid = false
		result["exact_position"] = [0.0, 8.0, 0.0]
	result["has_exact_position"] = exact_valid
	for angle_key in ["exact_rotation_y", "exact_camera_yaw", "exact_boat_heading"]:
		var angle := float(result.get(angle_key, 0.0))
		result[angle_key] = wrapf(angle, -PI, PI) if is_finite(angle) else 0.0
	var saved_boat_speed := float(result.get("exact_boat_speed", 0.0))
	result["exact_boat_speed"] = clampf(saved_boat_speed, -8.0, 23.0) if is_finite(saved_boat_speed) else 0.0
	return result

static func save_data(data: Dictionary) -> bool:
	var safe_data := sanitize_data(data)
	var serialized := JSON.stringify(safe_data, "\t")
	if serialized.is_empty():
		return false
	var temporary := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temporary == null:
		push_warning("Impossible de créer la sauvegarde temporaire")
		return false
	temporary.store_string(serialized)
	temporary.flush()
	temporary.close()

	var temp_absolute := ProjectSettings.globalize_path(TEMP_PATH)
	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var backup_absolute := ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(save_absolute, backup_absolute)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(save_absolute)
	var rename_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if rename_error != OK:
		push_warning("Échec de finalisation de la sauvegarde : code %d" % rename_error)
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.copy_absolute(backup_absolute, save_absolute)
		return false
	return true

static func _load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	return parsed as Dictionary if parsed is Dictionary else {}
