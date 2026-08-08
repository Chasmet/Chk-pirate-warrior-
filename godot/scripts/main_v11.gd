extends "res://scripts/main_v5.gd"

func _build_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = GameWorldV11.new()
	world.name = "Monde3DOnzeRoyaumes"
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
	(world as GameWorldV11).crew_status_changed.connect(_on_crew_status_changed)
	(world as GameWorldV11).final_region_state_changed.connect(_on_final_region_state_changed)
	(world as GameWorldV11).final_relic_found.connect(_on_final_relic_found)
	world.configure(save_data)
	player = world.get_player()

func _build_ui() -> void:
	ui = GameUIV11.new()
	ui.name = "InterfaceFrançaiseOnzeRoyaumes"
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
	(ui as GameUIV11).manual_save_requested.connect(_manual_save_exact)
	ui.set_voice_enabled(bool(save_data.get("voice", true)))
	_sync_ui()

func _save_progress() -> void:
	super._save_progress()
	if world is GameWorldV11:
		save_data["final_relic_found"] = (world as GameWorldV11).is_final_relic_collected()
		save_data["save_version"] = 11
		SaveSystem.save_data(save_data)

func _on_final_region_state_changed(active: bool) -> void:
	if ui is GameUIV11:
		(ui as GameUIV11).show_final_region_feedback(active)

func _on_final_relic_found(relic_name: String) -> void:
	if ui is GameUIV11:
		(ui as GameUIV11).show_final_relic_feedback(relic_name)
	_save_progress()
