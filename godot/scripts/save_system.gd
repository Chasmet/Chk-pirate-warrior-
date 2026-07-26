class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://chk_pirate_v2_save.json"

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
		"crew_relations": {"aurore":"neutral", "ecarlate":"neutral"},
		"has_exact_position": false,
		"exact_position": [0.0, 8.0, 0.0],
		"exact_rotation_y": 0.0,
		"exact_camera_yaw": 0.0,
		"exact_boat_mode": false,
		"exact_boat_heading": 0.0,
		"exact_boat_speed": 0.0
	}

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_data()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var merged := default_data()
		for key in parsed.keys():
			merged[key] = parsed[key]
		# Migration transparente des anciennes sauvegardes V2 à V4.
		if not merged.get("crew_relations") is Dictionary:
			merged["crew_relations"] = {"aurore":"neutral", "ecarlate":"neutral"}
		return merged
	return default_data()

static func save_data(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
