class_name GameWorld
extends Node3D

signal zone_changed(zone_index: int, zone_name: String)
signal mission_changed(text: String)
signal weather_changed(label: String)
signal navigation_changed(text: String, bearing: float, distance: float)
signal boat_action_changed(label: String, available: bool, on_boat: bool)
signal unlocked_zones_changed(zones: Array)
signal difficulty_changed(difficulty: String)
signal boss_defeated(boss_id: String)
signal player_ready(player: PlayerController)

const ZONES := [
	{"name":"Port des Naufragés","center":Vector3(0,0,0),"spawn":Vector3(0,8,0),"radius":108.0,"dock_dir":Vector3(0.96,0,0.28)},
	{"name":"Jungle sauvage","center":Vector3(315,0,-175),"spawn":Vector3(315,8,-175),"radius":116.0,"dock_dir":Vector3(-0.88,0,0.47)},
	{"name":"Royaume des neiges","center":Vector3(655,0,-72),"spawn":Vector3(655,8,-72),"radius":104.0,"dock_dir":Vector3(-0.99,0,-0.08)},
	{"name":"Désert des corsaires","center":Vector3(275,0,260),"spawn":Vector3(275,8,260),"radius":122.0,"dock_dir":Vector3(-0.62,0,-0.78)},
	{"name":"Île volcanique","center":Vector3(625,0,295),"spawn":Vector3(625,8,295),"radius":102.0,"dock_dir":Vector3(-0.87,0,-0.49)},
	{"name":"Forteresse de la tempête","center":Vector3(955,0,105),"spawn":Vector3(955,8,105),"radius":132.0,"dock_dir":Vector3(-0.99,0,0.06)}
]

var save_data: Dictionary = {}
var player: PlayerController
var hero_animator: QuinetHeroAnimator
var visuals: WorldVisuals
var current_zone := 0
var destination_zone := 1
var unlocked_zones: Array = [0]
var difficulty := "intermediaire"
var zone_kills := 0
var zone_boss_spawned := false
var defeated_bosses: Array = []
var current_mission := ""
var rng := RandomNumberGenerator.new()
var navigation_timer := 0.0
var last_boat_label := ""
var last_boat_available := false
var last_boat_mode := false

func configure(data: Dictionary) -> void:
	save_data = data
	current_zone = clampi(int(save_data.get("zone", 0)), 0, ZONES.size() - 1)
	difficulty = _normalized_difficulty(String(save_data.get("difficulty", "intermediaire")))
	unlocked_zones = _normalized_unlocked(save_data.get("unlocked_zones", [0]))
	if not unlocked_zones.has(current_zone):
		unlocked_zones.append(current_zone)
	destination_zone = clampi(int(save_data.get("destination_zone", _next_destination(current_zone))), 0, ZONES.size() - 1)
	defeated_bosses = save_data.get("bosses", [])
	rng.seed = 19820415
	visuals = WorldVisuals.new()
	add_child(visuals)
	visuals.build(ZONES, unlocked_zones)
	visuals.weather_changed.connect(func(label: String): weather_changed.emit(label))
	visuals.set_destination(destination_zone)
	_build_player()
	_activate_zone(current_zone, false, false)
	difficulty_changed.emit(difficulty)
	unlocked_zones_changed.emit(unlocked_zones.duplicate())

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_keep_player_in_world()
	visuals.update_world(delta, player.global_position)
	navigation_timer -= delta
	if navigation_timer <= 0.0:
		navigation_timer = 0.12
		_update_navigation()

func _keep_player_in_world() -> void:
	if player.boat_mode:
		var bounded_x := clampf(player.global_position.x, -210.0, 1130.0)
		var bounded_z := clampf(player.global_position.z, -455.0, 520.0)
		if not is_equal_approx(bounded_x, player.global_position.x) or not is_equal_approx(bounded_z, player.global_position.z):
			player.global_position.x = bounded_x
			player.global_position.z = bounded_z
			player.boat_speed *= 0.35
		return
	var center: Vector3 = ZONES[current_zone]["center"]
	if player.global_position.y < -4.0:
		player.global_position = Vector3(ZONES[current_zone]["spawn"])
		player.velocity = Vector3.ZERO
		player.receive_damage(10.0)
		VoiceFR.speak("Attention à l’océan. Retour sur l’île.")
		return
	var offset := player.global_position - center
	offset.y = 0.0
	var island_limit := float(ZONES[current_zone]["radius"]) - 3.0
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
	destination_zone = clampi(index, 0, ZONES.size() - 1)
	save_data["destination_zone"] = destination_zone
	if is_instance_valid(visuals):
		visuals.set_destination(destination_zone)
	var status := "déjà découverte" if unlocked_zones.has(destination_zone) else "à découvrir"
	_set_mission("Destination : %s (%s). Rejoins le quai et prends la barre." % [String(ZONES[destination_zone]["name"]), status])
	VoiceFR.speak("Cap indiqué vers " + String(ZONES[destination_zone]["name"]) + ".")
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
	player.enter_boat(water_dock, target_dock)
	_set_mission("EN MER • Navigue toi-même jusqu’à %s." % String(ZONES[destination_zone]["name"]))
	VoiceFR.speak("À la barre. Navigue jusqu’à " + String(ZONES[destination_zone]["name"]) + ".")
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
		VoiceFR.speak("Nouvelle île découverte. " + String(ZONES[zone_index]["name"]) + " est débloquée.")
		destination_zone = _next_destination(zone_index)
		save_data["destination_zone"] = destination_zone
		visuals.set_destination(destination_zone)
	_update_navigation()

func travel_to_zone(index: int, announce: bool = true) -> void:
	# Conservé pour les tests et la reprise d’une sauvegarde. L’interface de
	# jeu n’appelle plus ce raccourci : le joueur voyage réellement en bateau.
	var resolved := clampi(index, 0, ZONES.size() - 1)
	if is_instance_valid(player) and player.boat_mode:
		player.exit_boat(Vector3(ZONES[resolved]["spawn"]))
	elif is_instance_valid(player):
		player.global_position = Vector3(ZONES[resolved]["spawn"])
		player.velocity = Vector3.ZERO
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
	_set_mission("VALIDATION • PILOTAGE TROISIÈME PERSONNE")
	_update_navigation()
	print("CHK_BOAT_PREVIEW_READY hero=%s destination=%d" % [player.hero_id, destination_zone])

func get_player() -> PlayerController:
	return player

func get_zone_name() -> String:
	return String(ZONES[current_zone]["name"])

func get_mission_text() -> String:
	return current_mission

func get_unlocked_zones() -> Array:
	return unlocked_zones.duplicate()

func get_dock_position(zone_index: int, water_side: bool) -> Vector3:
	var zone: Dictionary = ZONES[clampi(zone_index, 0, ZONES.size() - 1)]
	var center: Vector3 = zone["center"]
	var direction: Vector3 = Vector3(zone["dock_dir"]).normalized()
	var distance := float(zone["radius"]) + (18.0 if water_side else -13.0)
	var result := center + direction * distance
	result.y = 1.05 if water_side else 2.05
	return result

func _build_player() -> void:
	player = PlayerController.new()
	player.name = "ÉquipageQuinet"
	add_child(player)
	player.configure(save_data)
	player.set_difficulty(difficulty)
	hero_animator = QuinetHeroAnimator.new()
	hero_animator.name = "AnimationHéros"
	player.add_child(hero_animator)
	hero_animator.bind(player)
	player.enemy_defeated.connect(_on_enemy_defeated)
	player.player_defeated.connect(_on_player_defeated)
	player.boat_mode_changed.connect(func(_active: bool): _update_navigation())
	player_ready.emit(player)

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	current_zone = clampi(index, 0, ZONES.size() - 1)
	save_data["zone"] = current_zone
	zone_kills = 0
	zone_boss_spawned = false
	_clear_enemies()
	if is_instance_valid(player) and not from_boat:
		player.global_position = Vector3(ZONES[current_zone]["spawn"])
		player.velocity = Vector3.ZERO
	_spawn_wave()
	visuals.set_zone_weather(current_zone)
	zone_changed.emit(current_zone, String(ZONES[current_zone]["name"]))
	var boss_id := String(EnemyFactory.boss_for_zone(current_zone).get("id", ""))
	if defeated_bosses.has(boss_id):
		_set_mission("Région libérée • Explore, combats ou repars vers le quai.")
	else:
		_set_mission("Élimine 8 ennemis pour faire apparaître le boss de l’île.")
	if announce:
		VoiceFR.speak("Bienvenue sur " + String(ZONES[current_zone]["name"]) + ".")

func _spawn_wave() -> void:
	if not is_instance_valid(player):
		return
	var center: Vector3 = ZONES[current_zone]["center"]
	var island_radius := float(ZONES[current_zone]["radius"])
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
	var profile: Dictionary = EnemyFactory.boss_for_zone(current_zone).duplicate(true)
	profile["difficulty"] = difficulty
	profile["zone"] = current_zone
	var boss := EnemyFactory.create_enemy(profile, player)
	add_child(boss)
	_attach_enemy_animator(boss)
	var center: Vector3 = ZONES[current_zone]["center"]
	boss.global_position = center + Vector3(0, 8.0, -float(ZONES[current_zone]["radius"]) * 0.38)
	player.register_enemy(boss)
	_set_mission("BOSS DE L’ÎLE : " + String(profile["name"]))
	VoiceFR.speak("Attention. " + String(profile["name"]) + " entre dans l’arène.")

func _attach_enemy_animator(enemy: EnemyAI) -> void:
	var animator := QuinetEnemyAnimator.new()
	animator.name = "AnimationEnnemi"
	enemy.add_child(animator)
	animator.bind(enemy)

func _on_enemy_defeated(profile: Dictionary) -> void:
	if bool(profile.get("boss", false)):
		var boss_id := String(profile.get("id", "boss"))
		if not defeated_bosses.has(boss_id):
			defeated_bosses.append(boss_id)
			save_data["bosses"] = defeated_bosses
			_set_mission("Île libérée • Rejoins le quai pour poursuivre l’exploration.")
			boss_defeated.emit(boss_id)
			VoiceFR.speak("Victoire. Le boss de l’île est vaincu.")
		return
	zone_kills += 1
	_set_mission("Ennemis vaincus : " + str(zone_kills) + " sur 8")
	if zone_kills >= 8:
		_spawn_boss()

func _on_player_defeated() -> void:
	_set_mission("Équipage à terre. Retour au camp de l’île.")
	await get_tree().create_timer(2.0).timeout
	player.heal(9999.0)
	travel_to_zone(current_zone, false)

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
			text = "QUAI DE %s • ACCOSTAGE POSSIBLE" % String(ZONES[nearby_dock]["name"]).to_upper()
			action_label = "ACCOSTER"
			action_available = true
		else:
			target = get_dock_position(destination_zone, true)
			distance = player.global_position.distance_to(target)
			var lock_text := "NOUVELLE ÎLE" if not unlocked_zones.has(destination_zone) else "ÎLE DÉBLOQUÉE"
			text = "%s • %s • %d m" % [String(ZONES[destination_zone]["name"]).to_upper(), lock_text, roundi(distance)]
			action_label = "ACCOSTER"
	else:
		target = get_dock_position(current_zone, false)
		distance = player.global_position.distance_to(target)
		if distance <= 19.0:
			text = "QUAI • EMBARQUE POUR %s" % String(ZONES[destination_zone]["name"]).to_upper()
			action_available = true
		else:
			text = "REJOINS LE QUAI • %d m • DESTINATION %s" % [roundi(distance), String(ZONES[destination_zone]["name"]).to_upper()]
	var bearing := player.navigation_bearing(target)
	navigation_changed.emit(text, bearing, distance)
	if action_label != last_boat_label or action_available != last_boat_available or player.boat_mode != last_boat_mode:
		last_boat_label = action_label
		last_boat_available = action_available
		last_boat_mode = player.boat_mode
		boat_action_changed.emit(action_label, action_available, player.boat_mode)

func _nearest_dock(position: Vector3, maximum_distance: float) -> int:
	var result := -1
	var nearest := maximum_distance
	for index in range(ZONES.size()):
		var distance := position.distance_to(get_dock_position(index, true))
		if distance < nearest:
			nearest = distance
			result = index
	return result

func _next_destination(from_zone: int) -> int:
	for step in range(1, ZONES.size() + 1):
		var candidate := posmod(from_zone + step, ZONES.size())
		if not unlocked_zones.has(candidate):
			return candidate
	return posmod(from_zone + 1, ZONES.size())

func _normalized_unlocked(value: Variant) -> Array:
	var result: Array = [0]
	if value is Array:
		for item in value:
			var index := clampi(int(item), 0, ZONES.size() - 1)
			if not result.has(index):
				result.append(index)
	result.sort()
	return result

func _normalized_difficulty(value: String) -> String:
	return value if ["decouverte", "intermediaire", "difficile"].has(value) else "intermediaire"

func _set_mission(text: String) -> void:
	current_mission = text
	mission_changed.emit(text)

func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node):
			node.queue_free()
