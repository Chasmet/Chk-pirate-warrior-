extends Node

var save_data: Dictionary
var world: GameWorld
var ui: GameUI
var player: PlayerController
var autosave_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_force_phone_landscape()
	save_data = SaveSystem.load_data()
	VoiceFR.initialize(bool(save_data.get("voice", true)))
	_build_world()
	_build_ui()
	_enter_menu()
	VoiceFR.speak("Bienvenue dans CHK Pirate Warrior. L'Archipel des Quinet.")

func _force_phone_landscape() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().content_scale_size = Vector2i(1920, 864)
	get_viewport().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_viewport().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	autosave_timer += delta
	if autosave_timer >= 12.0:
		autosave_timer = 0.0
		_save_progress()

func _build_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = GameWorld.new()
	world.name = "Monde3D"
	add_child(world)
	world.player_ready.connect(_on_player_ready)
	world.zone_changed.connect(_on_zone_changed)
	world.mission_changed.connect(_on_mission_changed)
	world.weather_changed.connect(_on_weather_changed)
	world.navigation_changed.connect(_on_navigation_changed)
	world.boat_action_changed.connect(_on_boat_action_changed)
	world.unlocked_zones_changed.connect(_on_unlocked_zones_changed)
	world.difficulty_changed.connect(_on_difficulty_changed)
	world.boss_defeated.connect(_on_boss_defeated)
	world.configure(save_data)
	player = world.get_player()

func _build_ui() -> void:
	ui = GameUI.new()
	ui.name = "InterfaceFrançaise"
	add_child(ui)
	ui.play_requested.connect(_start_game)
	ui.difficulty_selected.connect(_start_new_game)
	ui.hero_selected.connect(_select_hero)
	ui.zone_selected.connect(_travel_to_zone)
	ui.training_requested.connect(_train)
	ui.attack_requested.connect(func():
		if is_instance_valid(player): player.attack()
	)
	ui.skill_requested.connect(func():
		if is_instance_valid(player): player.skill()
	)
	ui.aura_requested.connect(func():
		if is_instance_valid(player): player.activate_aura()
	)
	ui.dodge_requested.connect(func():
		if is_instance_valid(player): player.dodge()
	)
	ui.switch_requested.connect(func():
		if is_instance_valid(player): player.switch_hero()
	)
	ui.move_changed.connect(func(value: Vector2):
		if is_instance_valid(player): player.set_move_input(value)
	)
	ui.camera_dragged.connect(func(relative: Vector2):
		if is_instance_valid(player): player.add_camera_drag(relative)
	)
	ui.camera_stick_changed.connect(func(value: Vector2):
		if is_instance_valid(player): player.set_camera_stick(value)
	)
	ui.boat_requested.connect(func():
		if is_instance_valid(world): world.toggle_boat()
	)
	ui.pause_requested.connect(_pause_game)
	ui.resume_requested.connect(_resume_game)
	ui.quit_to_menu_requested.connect(_quit_to_menu)
	ui.voice_toggled.connect(_toggle_voice)
	ui.set_voice_enabled(bool(save_data.get("voice", true)))
	_sync_ui()

func _connect_player() -> void:
	if not is_instance_valid(player):
		return
	player.stats_changed.connect(_on_stats_changed)
	player.hero_changed.connect(_on_hero_changed)
	player.hero_pose_changed.connect(_on_hero_pose_changed)
	player.hero_view_changed.connect(_on_hero_view_changed)
	player.boat_mode_changed.connect(_on_player_boat_mode_changed)
	player.player_defeated.connect(_on_player_defeated)

func _enter_menu() -> void:
	get_tree().paused = false
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	ui.show_main_menu()

func _start_game(new_game: bool) -> void:
	if new_game:
		_start_new_game(String(save_data.get("difficulty", "intermediaire")))
		return
	_activate_gameplay()

func _start_new_game(difficulty: String) -> void:
	save_data = SaveSystem.default_data()
	save_data["difficulty"] = difficulty
	VoiceFR.enabled = bool(save_data.get("voice", true))
	_build_world()
	_activate_gameplay()

func _activate_gameplay() -> void:
	world.visible = true
	world.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	ui.show_hud()
	_sync_ui()
	print("CHK_GAMEPLAY_READY hero=%s" % player.hero_id)
	VoiceFR.speak("L'aventure commence. Protège ta famille et libère l'archipel.")

func _pause_game() -> void:
	if not world.visible:
		return
	_save_progress()
	get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false
	ui.show_hud()

func _quit_to_menu() -> void:
	get_tree().paused = false
	_save_progress()
	_enter_menu()

func _select_hero(hero_id: String) -> void:
	save_data["hero"] = hero_id
	if is_instance_valid(player):
		player.set_hero(hero_id)
	_save_progress()

func _travel_to_zone(zone_index: int) -> void:
	if not world.visible:
		world.visible = true
		world.process_mode = Node.PROCESS_MODE_INHERIT
	if get_tree().paused:
		get_tree().paused = false
	world.set_destination(zone_index)
	ui.show_hud()
	_save_progress()

func _train(stat_name: String) -> void:
	if not is_instance_valid(player):
		return
	if player.train(stat_name):
		VoiceFR.speak("Entraînement de " + stat_name + " terminé.")
		_save_progress()
		ui.update_stats(player.health, player.max_health, player.energy, player.aura, player.level, player.xp, player.coins)
	else:
		VoiceFR.speak("Tu n'as pas assez de pièces pour cet entraînement.")

func _toggle_voice(active: bool) -> void:
	save_data["voice"] = active
	VoiceFR.enabled = active
	if active:
		VoiceFR.initialize(true)
		VoiceFR.speak("Voix française activée.")
	else:
		VoiceFR.stop()
	_save_progress()

func _on_player_ready(new_player: PlayerController) -> void:
	player = new_player
	_connect_player()

func _on_stats_changed(health: float, max_health: float, energy: float, aura: float, level: int, xp: int, coins: int) -> void:
	if is_instance_valid(ui):
		ui.update_stats(health, max_health, energy, aura, level, xp, coins)

func _on_hero_changed(hero_id: String, display_name: String) -> void:
	save_data["hero"] = hero_id
	if is_instance_valid(ui):
		ui.update_hero(hero_id, display_name)

func _on_hero_pose_changed(hero_id: String, frame: int) -> void:
	# Signal historique conservé pour les tests. Le signal hero_view_changed
	# ajoute l’orientation avant/arrière utilisée par la caméra 360°.
	pass

func _on_hero_view_changed(hero_id: String, frame: int, front_view: bool) -> void:
	if is_instance_valid(ui):
		ui.update_hero_pose(hero_id, frame, front_view)

func _on_player_boat_mode_changed(active: bool) -> void:
	if is_instance_valid(ui):
		ui.set_boat_mode(active)

func _on_zone_changed(zone_index: int, zone_name: String) -> void:
	save_data["zone"] = zone_index
	if is_instance_valid(ui):
		ui.update_zone(zone_name)

func _on_mission_changed(text: String) -> void:
	if is_instance_valid(ui):
		ui.update_mission(text)

func _on_weather_changed(label: String) -> void:
	if is_instance_valid(ui):
		ui.update_weather(label)

func _on_navigation_changed(text: String, bearing: float, distance: float) -> void:
	if is_instance_valid(ui):
		ui.update_navigation(text, bearing, distance)

func _on_boat_action_changed(label: String, available: bool, on_boat: bool) -> void:
	if is_instance_valid(ui):
		ui.set_boat_action(label, available, on_boat)

func _on_unlocked_zones_changed(zones: Array) -> void:
	save_data["unlocked_zones"] = zones.duplicate()
	if is_instance_valid(ui):
		ui.set_unlocked_zones(zones)

func _on_difficulty_changed(difficulty: String) -> void:
	save_data["difficulty"] = difficulty
	if is_instance_valid(ui):
		ui.update_difficulty(difficulty)

func _on_boss_defeated(_boss_id: String) -> void:
	_save_progress()

func _on_player_defeated() -> void:
	if is_instance_valid(ui):
		ui.show_game_over()
	await get_tree().create_timer(2.1).timeout
	if is_instance_valid(ui):
		ui.show_hud()

func _sync_ui() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(player):
		return
	var profile: Dictionary = HeroFactory.HEROES[player.hero_id]
	ui.update_hero(player.hero_id, String(profile["display_name"]))
	ui.update_zone(world.get_zone_name())
	ui.update_stats(player.health, player.max_health, player.energy, player.aura, player.level, player.xp, player.coins)
	ui.update_mission(world.get_mission_text())
	ui.update_difficulty(world.difficulty)
	ui.set_unlocked_zones(world.get_unlocked_zones())

func _save_progress() -> void:
	if is_instance_valid(player) and is_instance_valid(world):
		save_data = player.get_save_snapshot(world.current_zone)
		save_data["bosses"] = world.defeated_bosses
		save_data["unlocked_zones"] = world.get_unlocked_zones()
		save_data["destination_zone"] = world.destination_zone
		save_data["difficulty"] = world.difficulty
	SaveSystem.save_data(save_data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_progress()
