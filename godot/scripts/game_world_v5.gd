class_name GameWorldV5
extends GameWorldV4

signal crew_status_changed(text: String)

var crew_director: CrewEncounterDirectorV5
var ambient_fleet: AmbientFleetV5

func configure(data: Dictionary) -> void:
	save_data = data
	current_zone = clampi(int(save_data.get("zone", 0)), 0, ZONES_V4.size() - 1)
	difficulty = _normalized_difficulty(String(save_data.get("difficulty", "intermediaire")))
	unlocked_zones = _normalized_unlocked(save_data.get("unlocked_zones", [0]))
	if not unlocked_zones.has(current_zone):
		unlocked_zones.append(current_zone)
	destination_zone = clampi(int(save_data.get("destination_zone", _next_destination(current_zone))), 0, ZONES_V4.size() - 1)
	defeated_bosses = save_data.get("bosses", [])
	rng.seed = 19820415

	visuals = WorldVisualsV5.new()
	add_child(visuals)
	visuals.build(ZONES_V4, unlocked_zones)
	visuals.weather_changed.connect(func(label: String): weather_changed.emit(label))
	visuals.set_destination(destination_zone)

	_build_player()
	crew_director = CrewEncounterDirectorV5.new()
	crew_director.name = "RencontresÉquipagesV5"
	add_child(crew_director)
	crew_director.configure(player, ZONES_V4, save_data)
	crew_director.crew_status_changed.connect(func(text: String): crew_status_changed.emit(text))

	ambient_fleet = AmbientFleetV5.new()
	ambient_fleet.name = "FlotteAmbianteV5"
	visuals.add_child(ambient_fleet)
	ambient_fleet.configure(ZONES_V4)

	_activate_zone(current_zone, false, false)
	_restore_exact_snapshot()
	difficulty_changed.emit(difficulty)
	unlocked_zones_changed.emit(unlocked_zones.duplicate())
	set_meta("v5_final_quality", true)
	set_meta("nine_island_world", true)
	print("CHK_WORLD_V5_READY zones=%d exact_save=true crews=true fleet=true" % ZONES_V4.size())

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(crew_director):
		crew_director.set_active_zone(current_zone)

func _restore_exact_snapshot() -> void:
	if not bool(save_data.get("has_exact_position", false)) or not is_instance_valid(player):
		return
	var saved_position := _vector3_from_save(save_data.get("exact_position", []))
	if not _saved_position_is_valid(saved_position):
		push_warning("Sauvegarde V5 ignorée : position exacte invalide")
		return
	var saved_rotation := float(save_data.get("exact_rotation_y", 0.0))
	var saved_boat_mode := bool(save_data.get("exact_boat_mode", false))
	if saved_boat_mode:
		_clear_enemies()
		player.set_sea_conditions(visuals.weather_for_zone(current_zone))
		player.enter_boat(saved_position, get_dock_position(destination_zone, true))
		player.boat_heading = float(save_data.get("exact_boat_heading", saved_rotation))
		player.boat_speed = clampf(float(save_data.get("exact_boat_speed", 0.0)), -7.0, PlayerController.BOAT_MAX_SPEED)
		player.rotation.y = player.boat_heading
	else:
		player.teleport_to_world_position(saved_position)
		player.rotation.y = saved_rotation
		player.camera_target_yaw = float(save_data.get("exact_camera_yaw", saved_rotation))
		player.camera_yaw = player.camera_target_yaw
	print("CHK_V5_EXACT_SAVE_RESTORED zone=%d boat=%s position=%s" % [current_zone, str(saved_boat_mode), str(saved_position)])

func _saved_position_is_valid(value: Vector3) -> bool:
	if not value.is_finite():
		return false
	if absf(value.x) > 2600.0 or absf(value.z) > 1200.0 or value.y < -20.0 or value.y > 260.0:
		return false
	if bool(save_data.get("exact_boat_mode", false)):
		return true
	var zone: Dictionary = ZONES_V4[current_zone]
	var center: Vector3 = zone["center"]
	var flat := Vector2(value.x - center.x, value.z - center.z)
	return flat.length() <= float(zone["radius"]) - 1.0

func _vector3_from_save(value: Variant) -> Vector3:
	if value is Array and (value as Array).size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.INF
