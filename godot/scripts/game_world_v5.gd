class_name GameWorldV5
extends GameWorldV4

signal crew_status_changed(text: String)

const ISLAND_SCALE_V5 := 1.24
const ARCHIPELAGO_CENTERS_V7 := [
	Vector3(0, 0, 0),
	Vector3(720, 0, -420),
	Vector3(1580, 0, -160),
	Vector3(700, 0, 720),
	Vector3(1580, 0, 820),
	Vector3(2460, 0, 260),
	Vector3(3300, 0, -560),
	Vector3(4140, 0, 540),
	Vector3(5050, 48, -220)
]
const WORLD_MIN_V7 := Vector2(-650.0, -1500.0)
const WORLD_MAX_V7 := Vector2(5700.0, 1600.0)

var zones_v5: Array = []
var crew_director: CrewEncounterDirectorV5
var ambient_fleet: AmbientFleetV5

func configure(data: Dictionary) -> void:
	save_data = data
	zones_v5 = _expanded_zones_v5()
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
	visuals.build(zones_v5, unlocked_zones)
	visuals.weather_changed.connect(func(label: String): weather_changed.emit(label))
	visuals.set_destination(destination_zone)

	_build_player()
	crew_director = CrewEncounterDirectorV5.new()
	crew_director.name = "RencontresÉquipagesV5"
	add_child(crew_director)
	crew_director.configure(player, zones_v5, save_data)
	crew_director.crew_status_changed.connect(func(text: String): crew_status_changed.emit(text))

	ambient_fleet = AmbientFleetV5.new()
	ambient_fleet.name = "FlotteAmbianteV5"
	visuals.add_child(ambient_fleet)
	ambient_fleet.configure(zones_v5)

	_activate_zone(current_zone, false, false)
	_restore_exact_snapshot()
	difficulty_changed.emit(difficulty)
	unlocked_zones_changed.emit(unlocked_zones.duplicate())
	set_meta("v5_final_quality", true)
	set_meta("nine_island_world", true)
	set_meta("grand_archipelago_v7", true)
	print("CHK_WORLD_V7_ARCHIPELAGO_READY zones=%d ocean_width=6350 island_scale=%.2f" % [ZONES_V4.size(), ISLAND_SCALE_V5])

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(crew_director):
		crew_director.set_active_zone(current_zone)

func _keep_player_in_world() -> void:
	if not is_instance_valid(player):
		return
	if player.boat_mode:
		var bounded_x := clampf(player.global_position.x, WORLD_MIN_V7.x, WORLD_MAX_V7.x)
		var bounded_z := clampf(player.global_position.z, WORLD_MIN_V7.y, WORLD_MAX_V7.y)
		if not is_equal_approx(bounded_x, player.global_position.x) or not is_equal_approx(bounded_z, player.global_position.z):
			player.global_position.x = bounded_x
			player.global_position.z = bounded_z
			player.boat_speed *= 0.35
		return
	var zone: Dictionary = zones_v5[current_zone]
	var center: Vector3 = zone["center"]
	var minimum_y := float(zone.get("elevation", 0.0)) - (18.0 if current_zone == 8 else 4.0)
	if player.global_position.y < minimum_y:
		player.teleport_to_world_position(Vector3(zone["spawn"]))
		player.receive_damage(10.0)
		VoiceFR.speak("Attention. Retour sur l’île.")
		return
	var offset := player.global_position - center
	offset.y = 0.0
	var island_limit := float(zone["radius"]) - 3.0
	if offset.length() > island_limit:
		var corrected := center + offset.normalized() * island_limit
		corrected.y = player.global_position.y
		player.global_position = corrected
		var outward := offset.normalized()
		var flat_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
		if flat_velocity.dot(outward) > 0.0:
			flat_velocity -= outward * flat_velocity.dot(outward)
			player.velocity.x = flat_velocity.x
			player.velocity.z = flat_velocity.z

func get_dock_position(zone_index: int, water_side: bool) -> Vector3:
	var zone: Dictionary = zones_v5[clampi(zone_index, 0, zones_v5.size() - 1)]
	var center: Vector3 = zone["center"]
	var direction: Vector3 = Vector3(zone["dock_dir"]).normalized()
	var distance := float(zone["radius"]) + (34.0 if water_side else -15.0)
	var result := Vector3(center.x, 0.0, center.z) + direction * distance
	result.y = PlayerController.BOAT_WATERLINE if water_side else float(zone.get("elevation", center.y)) + 2.05
	return result

func _spawn_wave() -> void:
	if not is_instance_valid(player):
		return
	var center: Vector3 = zones_v5[current_zone]["center"]
	var island_radius := float(zones_v5[current_zone]["radius"])
	for i in range(10):
		var base_profile := EnemyFactory.profile_for_index(current_zone * 3 + i)
		var profile: Dictionary = base_profile.duplicate(true)
		profile["difficulty"] = difficulty
		profile["zone"] = current_zone
		var enemy := EnemyFactory.create_enemy(profile, player)
		add_child(enemy)
		_attach_enemy_animator(enemy)
		var angle := TAU * float(i) / 10.0 + rng.randf_range(-0.22, 0.22)
		var radius := rng.randf_range(island_radius * 0.24, island_radius * 0.64)
		enemy.global_position = center + Vector3(cos(angle) * radius, float(zones_v5[current_zone].get("elevation", 0.0)) + 8.0, sin(angle) * radius)
		player.register_enemy(enemy)

func _spawn_boss() -> void:
	if zone_boss_spawned or not is_instance_valid(player):
		return
	zone_boss_spawned = true
	var profile: Dictionary = Enemy25DCatalog.boss_for_zone(current_zone).duplicate(true)
	profile["difficulty"] = difficulty
	profile["zone"] = current_zone
	var boss := EnemyFactory.create_enemy(profile, player)
	boss.add_to_group("roster_25d")
	boss.set_meta("roster_zone", current_zone)
	add_child(boss)
	Enemy25DAssetBank.activate_zone(current_zone)
	Enemy25DVisual.apply(boss, profile)
	_attach_enemy_animator(boss)
	var center: Vector3 = zones_v5[current_zone]["center"]
	boss.global_position = center + Vector3(0, float(zones_v5[current_zone].get("elevation", 0.0)) + 8.0, -float(zones_v5[current_zone]["radius"]) * 0.40)
	player.register_enemy(boss)
	_set_mission("BOSS DE L’ÎLE : " + String(profile["name"]))
	VoiceFR.speak("Attention. " + String(profile["name"]) + " entre dans l’arène.")

func _restore_exact_snapshot() -> void:
	if not bool(save_data.get("has_exact_position", false)) or not is_instance_valid(player):
		return
	var saved_position := _vector3_from_save(save_data.get("exact_position", []))
	if not _saved_position_is_valid(saved_position):
		push_warning("Sauvegarde V5 ignorée : position exacte invalide ou issue de l’ancien archipel")
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
	print("CHK_V7_EXACT_SAVE_RESTORED zone=%d boat=%s position=%s" % [current_zone, str(saved_boat_mode), str(saved_position)])

func _saved_position_is_valid(value: Vector3) -> bool:
	if not value.is_finite():
		return false
	if value.x < WORLD_MIN_V7.x or value.x > WORLD_MAX_V7.x or value.z < WORLD_MIN_V7.y or value.z > WORLD_MAX_V7.y or value.y < -20.0 or value.y > 280.0:
		return false
	if bool(save_data.get("exact_boat_mode", false)):
		return true
	var zone: Dictionary = zones_v5[current_zone]
	var center: Vector3 = zone["center"]
	var flat := Vector2(value.x - center.x, value.z - center.z)
	return flat.length() <= float(zone["radius"]) - 1.0

func _expanded_zones_v5() -> Array:
	var result: Array = []
	for index in range(ZONES_V4.size()):
		var raw_zone: Dictionary = ZONES_V4[index]
		var zone: Dictionary = raw_zone.duplicate(true)
		var center := ARCHIPELAGO_CENTERS_V7[index]
		zone["center"] = center
		zone["spawn"] = center + Vector3(0.0, 8.0, 0.0)
		if index == 8:
			zone["spawn"] = center + Vector3(0.0, 8.0, 0.0)
		zone["radius"] = float(zone["radius"]) * ISLAND_SCALE_V5
		result.append(zone)
	return result

func _vector3_from_save(value: Variant) -> Vector3:
	if value is Array and (value as Array).size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.INF
