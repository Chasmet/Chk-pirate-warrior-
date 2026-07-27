class_name GameWorldV6
extends GameWorldV5

var island_life: IslandLifeDirectorV6
var polish_director: GeneralPolishDirectorV6
var stability_guard: RuntimeStabilityGuardV6
var lighting_director: AdaptiveLightingDirectorV7
var performance_director: RuntimePerformanceDirectorV8
var zone_transition_active := false

func configure(data: Dictionary) -> void:
	super.configure(data)
	_configure_player_physics_v6()
	_replace_crew_director_v6()
	island_life = IslandLifeDirectorV6.new()
	island_life.name = "VieAniméeDesÎlesV6"
	visuals.add_child(island_life)
	island_life.configure(zones_v5)
	island_life.set_active_zone(current_zone)
	polish_director = GeneralPolishDirectorV6Fixed.new()
	polish_director.name = "AméliorationGénéraleV6"
	add_child(polish_director)
	polish_director.configure(self, player, visuals as WorldVisualsV5)
	lighting_director = AdaptiveLightingDirectorV7.new()
	lighting_director.name = "ÉclairageAdaptatifV7"
	add_child(lighting_director)
	lighting_director.configure(self, player, visuals as WorldVisualsV5, zones_v5)
	stability_guard = RuntimeStabilityGuardV6.new()
	stability_guard.name = "StabilitéExécutionV6"
	add_child(stability_guard)
	stability_guard.configure(self, player)
	performance_director = RuntimePerformanceDirectorV8.new()
	performance_director.name = "PerformanceAndroidV8"
	add_child(performance_director)
	performance_director.configure(self, player, visuals as WorldVisualsV5)
	player.boat_mode_changed.connect(func(_active: bool):
		if is_instance_valid(performance_director):
			performance_director.refresh_focus(true)
	)
	set_meta("general_polish_v6", true)
	set_meta("animated_characters_v6", true)
	set_meta("animated_islands_v6", true)
	set_meta("runtime_stability_v6", true)
	set_meta("adaptive_lighting_v7", true)
	set_meta("grand_archipelago_v7", true)
	set_meta("runtime_performance_v8", true)
	set_meta("stable_boat_gameplay_v8", true)
	print("CHK_WORLD_V8_READY distant_islands=true adaptive_lighting=true stable_boat=true performance=true")

func _build_player() -> void:
	player = PlayerControllerV8.new()
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

func set_destination(index: int) -> void:
	super.set_destination(index)
	if is_instance_valid(performance_director):
		performance_director.refresh_focus(true)

func toggle_boat() -> void:
	super.toggle_boat()
	if is_instance_valid(performance_director):
		performance_director.refresh_focus(true)

func _dock_at_zone(zone_index: int) -> void:
	super._dock_at_zone(zone_index)
	if is_instance_valid(performance_director):
		performance_director.refresh_focus(true)

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	if zone_transition_active:
		return
	zone_transition_active = true
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(island_life):
		island_life.set_active_zone(current_zone)
	if is_instance_valid(lighting_director):
		lighting_director.set_active_zone(current_zone)
	if is_instance_valid(stability_guard):
		stability_guard.reset_safe_checkpoint()
	if is_instance_valid(performance_director):
		performance_director.refresh_focus(true)
	zone_transition_active = false

func _configure_player_physics_v6() -> void:
	if not is_instance_valid(player):
		return
	if not player.is_in_group("player_actor"):
		player.add_to_group("player_actor")
	player.floor_snap_length = 0.82
	player.floor_max_angle = deg_to_rad(54.0)
	player.floor_stop_on_slope = true
	player.floor_constant_speed = true
	player.floor_block_on_wall = true
	player.safe_margin = 0.055
	player.max_slides = 7
	player.wall_min_slide_angle = deg_to_rad(18.0)
	player.set_meta("physics_v6", true)
	player.set_meta("gameplay_v8", true)

func _replace_crew_director_v6() -> void:
	if is_instance_valid(crew_director):
		if crew_director.get_parent() != null:
			crew_director.get_parent().remove_child(crew_director)
		crew_director.queue_free()
	crew_director = CrewEncounterDirectorV6.new()
	crew_director.name = "RencontresÉquipagesMobilesV6"
	add_child(crew_director)
	crew_director.configure(player, zones_v5, save_data)
	crew_director.crew_status_changed.connect(func(text: String): crew_status_changed.emit(text))
	crew_director.set_active_zone(current_zone)
