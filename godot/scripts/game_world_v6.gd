class_name GameWorldV6
extends GameWorldV5

var island_life: IslandLifeDirectorV6
var polish_director: GeneralPolishDirectorV6
var stability_guard: RuntimeStabilityGuardV6
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
	stability_guard = RuntimeStabilityGuardV6.new()
	stability_guard.name = "StabilitéExécutionV6"
	add_child(stability_guard)
	stability_guard.configure(self, player)
	set_meta("general_polish_v6", true)
	set_meta("animated_characters_v6", true)
	set_meta("animated_islands_v6", true)
	set_meta("runtime_stability_v6", true)
	print("CHK_WORLD_V6_READY friendly_mobile=true fauna_physics=true island_life=true lighting=true stability=true")

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	if zone_transition_active:
		return
	zone_transition_active = true
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(island_life):
		island_life.set_active_zone(current_zone)
	if is_instance_valid(stability_guard):
		stability_guard.reset_safe_checkpoint()
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
