extends "res://scripts/main_v4.gd"

func _build_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = GameWorldV6.new()
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
	(world as GameWorldV6).crew_status_changed.connect(_on_crew_status_changed)
	world.configure(save_data)
	player = world.get_player()

func _build_ui() -> void:
	ui = GameUIV5.new()
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
	(ui as GameUIV5).manual_save_requested.connect(_manual_save_exact)
	ui.set_voice_enabled(bool(save_data.get("voice", true)))
	_sync_ui()

func _process(_delta: float) -> void:
	# La V5 conserve un emplacement manuel unique. Aucun autosave périodique ne
	# vient écraser le point choisi par le joueur. Pause, fermeture et passage
	# en arrière-plan sauvegardent néanmoins l’état courant pour la sécurité.
	pass

func _manual_save_exact() -> void:
	if not is_instance_valid(player) or not is_instance_valid(world) or not world.visible:
		return
	_save_progress()
	if ui is GameUIV5:
		(ui as GameUIV5).show_save_feedback(player.global_position, player.boat_mode)
	Input.vibrate_handheld(45)
	VoiceFR.speak("Sauvegarde terminée à cet endroit.")
	print("CHK_V5_MANUAL_SAVE position=%s boat=%s" % [str(player.global_position), str(player.boat_mode)])

func _save_progress() -> void:
	if is_instance_valid(player) and is_instance_valid(world):
		save_data = player.get_save_snapshot(world.current_zone)
		save_data["bosses"] = world.defeated_bosses
		save_data["unlocked_zones"] = world.get_unlocked_zones()
		save_data["destination_zone"] = world.destination_zone
		save_data["difficulty"] = world.difficulty
		if world.visible:
			save_data["save_version"] = 5
			save_data["has_exact_position"] = true
			save_data["exact_position"] = [player.global_position.x, player.global_position.y, player.global_position.z]
			save_data["exact_rotation_y"] = player.rotation.y
			save_data["exact_camera_yaw"] = player.camera_yaw
			save_data["exact_boat_mode"] = player.boat_mode
			save_data["exact_boat_heading"] = player.boat_heading
			save_data["exact_boat_speed"] = player.boat_speed
	SaveSystem.save_data(save_data)

func _on_crew_status_changed(text: String) -> void:
	if ui is GameUIV5:
		(ui as GameUIV5).update_crew_status(text)
