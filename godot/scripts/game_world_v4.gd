class_name GameWorldV4
extends GameWorld

# Extension réelle du monde ouvert Godot : les six îles existantes restent
# inchangées et les îles 7, 8 et 9 sont ajoutées dans le même océan 3D.
const ZONES_V4 := [
	{"name":"Port des Naufragés","center":Vector3(0,0,0),"spawn":Vector3(0,8,0),"radius":108.0,"dock_dir":Vector3(0.96,0,0.28),"elevation":0.0},
	{"name":"Jungle sauvage","center":Vector3(315,0,-175),"spawn":Vector3(315,8,-175),"radius":116.0,"dock_dir":Vector3(-0.88,0,0.47),"elevation":0.0},
	{"name":"Royaume des neiges","center":Vector3(655,0,-72),"spawn":Vector3(655,8,-72),"radius":104.0,"dock_dir":Vector3(-0.99,0,-0.08),"elevation":0.0},
	{"name":"Désert des corsaires","center":Vector3(275,0,260),"spawn":Vector3(275,8,260),"radius":122.0,"dock_dir":Vector3(-0.62,0,-0.78),"elevation":0.0},
	{"name":"Île volcanique","center":Vector3(625,0,295),"spawn":Vector3(625,8,295),"radius":102.0,"dock_dir":Vector3(-0.87,0,-0.49),"elevation":0.0},
	{"name":"Forteresse de la tempête","center":Vector3(955,0,105),"spawn":Vector3(955,8,105),"radius":132.0,"dock_dir":Vector3(-0.99,0,0.06),"elevation":0.0},
	{"name":"Île des Gâteaux","center":Vector3(1260,0,-225),"spawn":Vector3(1260,8,-225),"radius":120.0,"dock_dir":Vector3(-0.92,0,0.39),"elevation":0.0},
	{"name":"Citadelle du Crâne","center":Vector3(1560,0,180),"spawn":Vector3(1560,8,180),"radius":130.0,"dock_dir":Vector3(-0.88,0,-0.47),"elevation":0.0},
	{"name":"Royaume Céleste","center":Vector3(1900,48,-110),"spawn":Vector3(1900,56,-110),"radius":134.0,"dock_dir":Vector3(-0.96,0,0.27),"elevation":48.0}
]

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
	visuals = WorldVisualsV4.new()
	add_child(visuals)
	visuals.build(ZONES_V4, unlocked_zones)
	visuals.weather_changed.connect(func(label: String): weather_changed.emit(label))
	visuals.set_destination(destination_zone)
	_build_player()
	_activate_zone(current_zone, false, false)
	difficulty_changed.emit(difficulty)
	unlocked_zones_changed.emit(unlocked_zones.duplicate())
	set_meta("nine_island_world", true)
	print("CHK_WORLD_V4_READY zones=%d ocean_navigation=true" % ZONES_V4.size())

func _keep_player_in_world() -> void:
	if player.boat_mode:
		var bounded_x := clampf(player.global_position.x, -240.0, 2155.0)
		var bounded_z := clampf(player.global_position.z, -520.0, 590.0)
		if not is_equal_approx(bounded_x, player.global_position.x) or not is_equal_approx(bounded_z, player.global_position.z):
			player.global_position.x = bounded_x
			player.global_position.z = bounded_z
			player.boat_speed *= 0.35
		return
	var zone: Dictionary = ZONES_V4[current_zone]
	var center: Vector3 = zone["center"]
	var minimum_y := float(zone.get("elevation", 0.0)) - (16.0 if current_zone == 8 else 4.0)
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

func set_destination(index: int) -> void:
	destination_zone = clampi(index, 0, ZONES_V4.size() - 1)
	save_data["destination_zone"] = destination_zone
	if is_instance_valid(visuals):
		visuals.set_destination(destination_zone)
	var status := "déjà découverte" if unlocked_zones.has(destination_zone) else "à découvrir"
	_set_mission("Destination : %s (%s). Rejoins le quai et prends la barre." % [String(ZONES_V4[destination_zone]["name"]), status])
	VoiceFR.speak("Cap indiqué vers " + String(ZONES_V4[destination_zone]["name"]) + ".")
	_update_navigation()

func toggle_boat() -> void:
	if not is_instance_valid(player):
		return
	if player.boat_mode:
		var dock_index := _nearest_dock(player.global_position, 31.0)
		if dock_index < 0:
			VoiceFR.speak("Approche-toi d’un quai pour accoster.")
			return
		_dock_at_zone(dock_index)
		return
	var land_dock := get_dock_position(current_zone, false)
	if player.global_position.distance_to(land_dock) > 19.0:
		VoiceFR.speak("Rejoins le quai pour embarquer.")
		return
	if destination_zone == current_zone:
		destination_zone = _next_destination(current_zone)
		visuals.set_destination(destination_zone)
	var water_dock := get_dock_position(current_zone, true)
	var target_dock := get_dock_position(destination_zone, true)
	_clear_enemies()
	player.set_sea_conditions(visuals.weather_for_zone(current_zone))
	player.enter_boat(water_dock, target_dock)
	_set_mission("EN MER • Navigue toi-même jusqu’à %s." % String(ZONES_V4[destination_zone]["name"]))
	VoiceFR.speak("À la barre. Navigue jusqu’à " + String(ZONES_V4[destination_zone]["name"]) + ".")
	_update_navigation()

func _dock_at_zone(zone_index: int) -> void:
	var newly_unlocked := not unlocked_zones.has(zone_index)
	if newly_unlocked:
		unlocked_zones.append(zone_index)
		unlocked_zones.sort()
		save_data["unlocked_zones"] = unlocked_zones.duplicate()
		unlocked_zones_changed.emit(unlocked_zones.duplicate())
		visuals.set_unlocked_zones(unlocked_zones)
	player.exit_boat(get_dock_position(zone_index, false))
	_activate_zone(zone_index, true, true)
	if newly_unlocked:
		VoiceFR.speak("Nouvelle île découverte. " + String(ZONES_V4[zone_index]["name"]) + " est débloquée.")
		destination_zone = _next_destination(zone_index)
		save_data["destination_zone"] = destination_zone
		visuals.set_destination(destination_zone)
	_update_navigation()

func travel_to_zone(index: int, announce: bool = true) -> void:
	# Raccourci réservé aux tests et à la reprise de sauvegarde. Le joueur
	# rejoint normalement chaque nouvelle île en pilotant lui-même le bateau.
	var resolved := clampi(index, 0, ZONES_V4.size() - 1)
	if is_instance_valid(player) and player.boat_mode:
		player.exit_boat(Vector3(ZONES_V4[resolved]["spawn"]))
	elif is_instance_valid(player):
		player.teleport_to_world_position(Vector3(ZONES_V4[resolved]["spawn"]))
	_activate_zone(resolved, announce, false)

func debug_start_boat_preview() -> void:
	if not OS.is_debug_build() or not is_instance_valid(player):
		return
	destination_zone = _next_destination(current_zone)
	save_data["destination_zone"] = destination_zone
	if is_instance_valid(visuals):
		visuals.set_destination(destination_zone)
	_clear_enemies()
	player.enter_boat(get_dock_position(current_zone, true), get_dock_position(destination_zone, true))
	_set_mission("VALIDATION • PILOTAGE TROISIÈME PERSONNE • 9 ÎLES")
	_update_navigation()
	print("CHK_BOAT_PREVIEW_V4_READY hero=%s destination=%d" % [player.hero_id, destination_zone])

func get_zone_name() -> String:
	return String(ZONES_V4[current_zone]["name"])

func get_dock_position(zone_index: int, water_side: bool) -> Vector3:
	var zone: Dictionary = ZONES_V4[clampi(zone_index, 0, ZONES_V4.size() - 1)]
	var center: Vector3 = zone["center"]
	var direction: Vector3 = Vector3(zone["dock_dir"]).normalized()
	var distance := float(zone["radius"]) + (32.0 if water_side else -13.0)
	var result := Vector3(center.x, 0.0, center.z) + direction * distance
	result.y = PlayerController.BOAT_WATERLINE if water_side else float(zone.get("elevation", center.y)) + 2.05
	return result

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	current_zone = clampi(index, 0, ZONES_V4.size() - 1)
	save_data["zone"] = current_zone
	zone_kills = 0
	zone_boss_spawned = false
	_clear_enemies()
	if is_instance_valid(player) and not from_boat:
		player.teleport_to_world_position(Vector3(ZONES_V4[current_zone]["spawn"]))
	_spawn_wave()
	visuals.set_zone_weather(current_zone)
	active_weather_zone = current_zone
	if is_instance_valid(player):
		player.set_sea_conditions(visuals.weather_for_zone(current_zone))
	zone_changed.emit(current_zone, String(ZONES_V4[current_zone]["name"]))
	var boss_id := String(Enemy25DCatalog.boss_for_zone(current_zone).get("id", ""))
	if defeated_bosses.has(boss_id):
		_set_mission("Région libérée • Explore, combats ou repars vers le quai.")
	else:
		_set_mission("Élimine 8 ennemis pour faire apparaître le boss de l’île.")
	if announce:
		VoiceFR.speak("Bienvenue sur " + String(ZONES_V4[current_zone]["name"]) + ".")

func _spawn_wave() -> void:
	if not is_instance_valid(player):
		return
	var center: Vector3 = ZONES_V4[current_zone]["center"]
	var island_radius := float(ZONES_V4[current_zone]["radius"])
	for i in range(8):
		var base_profile := EnemyFactory.profile_for_index(current_zone * 3 + i)
		var profile: Dictionary = base_profile.duplicate(true)
		profile["difficulty"] = difficulty
		profile["zone"] = current_zone
		var enemy := EnemyFactory.create_enemy(profile, player)
		add_child(enemy)
		_attach_enemy_animator(enemy)
		var angle := TAU * float(i) / 8.0 + rng.randf_range(-0.24, 0.24)
		var radius := rng.randf_range(island_radius * 0.24, island_radius * 0.58)
		enemy.global_position = center + Vector3(cos(angle) * radius, 8.0, sin(angle) * radius)
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
	var center: Vector3 = ZONES_V4[current_zone]["center"]
	boss.global_position = center + Vector3(0, 8.0, -float(ZONES_V4[current_zone]["radius"]) * 0.38)
	player.register_enemy(boss)
	_set_mission("BOSS DE L’ÎLE : " + String(profile["name"]))
	VoiceFR.speak("Attention. " + String(profile["name"]) + " entre dans l’arène.")

func _update_navigation() -> void:
	if not is_instance_valid(player):
		return
	var text := ""
	var target := Vector3.ZERO
	var distance := 0.0
	var action_label := "EMBARQUER"
	var action_available := false
	if player.boat_mode:
		var nearby_dock := _nearest_dock(player.global_position, 31.0)
		if nearby_dock >= 0:
			target = get_dock_position(nearby_dock, true)
			distance = player.global_position.distance_to(target)
			text = "QUAI DE %s • ACCOSTAGE POSSIBLE" % String(ZONES_V4[nearby_dock]["name"]).to_upper()
			action_label = "ACCOSTER"
			action_available = true
		else:
			target = get_dock_position(destination_zone, true)
			distance = player.global_position.distance_to(target)
			var lock_text := "NOUVELLE ÎLE" if not unlocked_zones.has(destination_zone) else "ÎLE DÉBLOQUÉE"
			text = "%s • %s • %d m" % [String(ZONES_V4[destination_zone]["name"]).to_upper(), lock_text, roundi(distance)]
			action_label = "ACCOSTER"
	else:
		target = get_dock_position(current_zone, false)
		distance = player.global_position.distance_to(target)
		if distance <= 19.0:
			text = "QUAI • EMBARQUE POUR %s" % String(ZONES_V4[destination_zone]["name"]).to_upper()
			action_available = true
		else:
			text = "REJOINS LE QUAI • %d m • DESTINATION %s" % [roundi(distance), String(ZONES_V4[destination_zone]["name"]).to_upper()]
	var bearing := player.navigation_bearing(target)
	navigation_changed.emit(text, bearing, distance)
	if action_label != last_boat_label or action_available != last_boat_available or player.boat_mode != last_boat_mode:
		last_boat_label = action_label
		last_boat_available = action_available
		last_boat_mode = player.boat_mode
		boat_action_changed.emit(action_label, action_available, player.boat_mode)

func _update_sailing_weather() -> void:
	if not is_instance_valid(player) or not player.boat_mode:
		return
	var start := get_dock_position(current_zone, true)
	var finish := get_dock_position(destination_zone, true)
	var distance_from_start := player.global_position.distance_to(start)
	var distance_to_finish := player.global_position.distance_to(finish)
	var progress := distance_from_start / maxf(distance_from_start + distance_to_finish, 1.0)
	var weather_zone := current_zone if progress < 0.55 else destination_zone
	if weather_zone == active_weather_zone:
		return
	active_weather_zone = weather_zone
	visuals.set_zone_weather(weather_zone)
	player.set_sea_conditions(visuals.weather_for_zone(weather_zone))

func _nearest_dock(position: Vector3, maximum_distance: float) -> int:
	var result := -1
	var nearest := maximum_distance
	for index in range(ZONES_V4.size()):
		var distance := position.distance_to(get_dock_position(index, true))
		if distance < nearest:
			nearest = distance
			result = index
	return result

func _next_destination(from_zone: int) -> int:
	for step in range(1, ZONES_V4.size() + 1):
		var candidate := posmod(from_zone + step, ZONES_V4.size())
		if not unlocked_zones.has(candidate):
			return candidate
	return posmod(from_zone + 1, ZONES_V4.size())

func _normalized_unlocked(value: Variant) -> Array:
	var result: Array = [0]
	if value is Array:
		for item in value:
			var index := clampi(int(item), 0, ZONES_V4.size() - 1)
			if not result.has(index):
				result.append(index)
	result.sort()
	return result
