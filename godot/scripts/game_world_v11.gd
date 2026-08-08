class_name GameWorldV11
extends GameWorldV6

signal final_relic_found(relic_name: String)
signal final_region_state_changed(active: bool)

const FINAL_DOCK_DIRECTION := Vector3(-0.82, 0.0, -0.57)
const FINAL_DOCK_WATER_OFFSET := 39.0
const FINAL_DOCK_LAND_OFFSET := -18.0

var open_world_director: OpenWorldRegionDirectorV11
var final_landmass: FinalKingdomLandmassV11
var final_region_active := false
var final_relic_collected := false
var final_departure_guard := false

func configure(data: Dictionary) -> void:
	super.configure(data)
	final_relic_collected = bool(data.get("final_relic_found", false))
	final_region_active = _is_on_final_region(player.global_position) and not player.boat_mode

	final_landmass = FinalKingdomLandmassV11.new()
	add_child(final_landmass)
	final_landmass.build()

	open_world_director = OpenWorldRegionDirectorV11.new()
	open_world_director.name = "MondeOuvertOnzeRoyaumesV11"
	add_child(open_world_director)
	open_world_director.configure(self, player, visuals)
	open_world_director.set_core_zone(current_zone)
	open_world_director.final_relic_collected.connect(_on_final_relic_collected)
	if final_relic_collected:
		open_world_director.mark_final_relic_collected()
	if final_region_active:
		open_world_director.force_region_for_test(RegionCatalogV11.FINAL_REGION_INDEX)

	set_meta("open_world_foundation_v11", true)
	set_meta("eleven_kingdoms_v11", true)
	set_meta("final_kingdom_dockable_v11", true)
	set_meta("final_landmass_collision_v11", true)
	set_meta("final_relic_persistent_v11", true)
	set_meta("final_dock_hud_v11", true)
	print("CHK_WORLD_V11_READY regions=%d final_dock=true relic_saved=%s" % [RegionCatalogV11.REGION_COUNT, str(final_relic_collected)])

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	final_region_active = false
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(open_world_director):
		open_world_director.set_core_zone(current_zone)
	final_region_state_changed.emit(false)

func toggle_boat() -> void:
	if not is_instance_valid(player):
		return
	if player.boat_mode:
		var final_water_dock := get_final_dock_position(true)
		if not final_departure_guard and player.global_position.distance_to(final_water_dock) <= 36.0:
			_enter_final_region_from_boat()
			return
	else:
		if final_region_active or _is_on_final_region(player.global_position):
			var final_land_dock := get_final_dock_position(false)
			if player.global_position.distance_to(final_land_dock) > 21.0:
				VoiceFR.speak("Rejoins le Pont du Retour Impossible pour reprendre la mer.")
				return
			_leave_final_region_by_boat()
			return
	super.toggle_boat()

func _update_navigation() -> void:
	if not is_instance_valid(player):
		return
	var final_water_dock := get_final_dock_position(true)
	var final_land_dock := get_final_dock_position(false)
	var final_center := Vector3(RegionCatalogV11.FINAL_REGION["center"])
	var final_center_distance := Vector2(player.global_position.x - final_center.x, player.global_position.z - final_center.z).length()
	if final_departure_guard and final_center_distance > float(RegionCatalogV11.FINAL_REGION["radius"]) + 260.0:
		final_departure_guard = false

	if player.boat_mode and not final_departure_guard:
		var dock_distance := player.global_position.distance_to(final_water_dock)
		if final_center_distance <= float(RegionCatalogV11.FINAL_REGION["radius"]) + 350.0:
			var action_available := dock_distance <= 36.0
			var text := "ROYAUME TROUBLÉ • BRUME DORÉE • QUAI %d m" % roundi(dock_distance)
			if action_available:
				text = "ROYAUME TROUBLÉ • ACCOSTAGE POSSIBLE"
			navigation_changed.emit(text, player.navigation_bearing(final_water_dock), dock_distance)
			_emit_boat_action_v11("ACCOSTER", action_available)
			return
	elif not player.boat_mode and (final_region_active or _is_on_final_region(player.global_position)):
		var dock_distance := player.global_position.distance_to(final_land_dock)
		var action_available := dock_distance <= 21.0
		var text := "PONT DU RETOUR IMPOSSIBLE • %d m" % roundi(dock_distance)
		if action_available:
			text = "PONT DU RETOUR IMPOSSIBLE • EMBARQUEMENT POSSIBLE"
		navigation_changed.emit(text, player.navigation_bearing(final_land_dock), dock_distance)
		_emit_boat_action_v11("EMBARQUER", action_available)
		return

	super._update_navigation()

func _emit_boat_action_v11(label: String, available: bool) -> void:
	if label != last_boat_label or available != last_boat_available or player.boat_mode != last_boat_mode:
		last_boat_label = label
		last_boat_available = available
		last_boat_mode = player.boat_mode
		boat_action_changed.emit(label, available, player.boat_mode)

func _enter_final_region_from_boat() -> void:
	_clear_enemies()
	player.exit_boat(get_final_dock_position(false))
	final_region_active = true
	final_departure_guard = false
	if is_instance_valid(open_world_director):
		open_world_director.force_region_for_test(RegionCatalogV11.FINAL_REGION_INDEX)
	_set_mission("ROYAUME TROUBLÉ • Traverse la brume dorée et retrouve le Cœur des Souvenirs.")
	VoiceFR.speak("Royaume Troublé. Aucun habitant. Aucun animal. Retrouve le Cœur des Souvenirs.")
	final_region_state_changed.emit(true)
	_update_navigation()
	print("CHK_V11_FINAL_REGION_DOCKED position=%s" % str(player.global_position))

func _leave_final_region_by_boat() -> void:
	var target := get_dock_position(destination_zone, true)
	player.set_sea_conditions(visuals.weather_for_zone(current_zone))
	final_departure_guard = true
	player.enter_boat(get_final_dock_position(true), target)
	final_region_active = false
	if is_instance_valid(open_world_director):
		open_world_director.clear_test_region_override()
	_set_mission("EN MER • Retour vers %s." % String(zones_v5[destination_zone]["name"]))
	VoiceFR.speak("Retour en mer. Cap vers " + String(zones_v5[destination_zone]["name"]) + ".")
	final_region_state_changed.emit(false)
	_update_navigation()

func get_final_dock_position(water_side: bool) -> Vector3:
	var data: Dictionary = RegionCatalogV11.FINAL_REGION
	var center := Vector3(data["center"])
	var radius := float(data["radius"])
	var direction := FINAL_DOCK_DIRECTION.normalized()
	var distance := radius + (FINAL_DOCK_WATER_OFFSET if water_side else FINAL_DOCK_LAND_OFFSET)
	var result := Vector3(center.x, 0.0, center.z) + direction * distance
	result.y = PlayerController.BOAT_WATERLINE if water_side else float(data.get("elevation", 2.0)) + 2.05
	return result

func _keep_player_in_world() -> void:
	if not is_instance_valid(player):
		return
	if not player.boat_mode and (final_region_active or _is_on_final_region(player.global_position)):
		final_region_active = true
		_keep_player_on_final_region()
		return
	super._keep_player_in_world()

func _keep_player_on_final_region() -> void:
	var data: Dictionary = RegionCatalogV11.FINAL_REGION
	var center := Vector3(data["center"])
	if player.global_position.y < float(data.get("elevation", 2.0)) - 8.0:
		player.teleport_to_world_position(get_final_dock_position(false))
		player.receive_damage(5.0)
		VoiceFR.speak("La brume te ramène au sanctuaire.")
		return
	var offset := player.global_position - center
	offset.y = 0.0
	var island_limit := float(data["radius"]) - 6.0
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

func _saved_position_is_valid(value: Vector3) -> bool:
	if not value.is_finite():
		return false
	if bool(save_data.get("exact_boat_mode", false)):
		return super._saved_position_is_valid(value)
	if _is_on_final_region(value):
		return true
	return super._saved_position_is_valid(value)

func _is_on_final_region(position: Vector3) -> bool:
	var data: Dictionary = RegionCatalogV11.FINAL_REGION
	var center := Vector3(data["center"])
	var flat := Vector2(position.x - center.x, position.z - center.z)
	return flat.length() <= float(data["radius"]) - 1.0

func _on_final_relic_collected(relic_name: String) -> void:
	if final_relic_collected:
		return
	final_relic_collected = true
	save_data["final_relic_found"] = true
	_set_mission("AVENTURE TERMINÉE • %s obtenu • Tu peux continuer à explorer librement." % relic_name)
	final_relic_found.emit(relic_name)
	print("CHK_V11_FINAL_RELIC_PERSISTED name=%s" % relic_name)

func is_final_relic_collected() -> bool:
	return final_relic_collected
