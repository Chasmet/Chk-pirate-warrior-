extends "res://scripts/main_v5.gd"

func _build_world() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = GameWorldV9.new()
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
	(world as GameWorldV9).crew_status_changed.connect(_on_crew_status_changed)
	world.configure(save_data)
	player = world.get_player()
