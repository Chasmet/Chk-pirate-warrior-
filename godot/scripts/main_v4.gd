extends "res://scripts/main.gd"

func _build_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = GameWorldV4.new()
	world.name = "Monde3DNeufÎles"
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
	ui = GameUIV4.new()
	ui.name = "InterfaceFrançaiseNeufÎles"
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
