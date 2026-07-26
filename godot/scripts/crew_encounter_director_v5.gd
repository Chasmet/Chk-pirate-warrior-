class_name CrewEncounterDirectorV5
extends Node3D

signal crew_status_changed(text: String)

var player: PlayerController
var zones: Array = []
var save_data: Dictionary = {}
var active_zone := 0
var members: Array[RoamingCrewMemberV5] = []
var crew_attitudes := ["neutral", "neutral"]
var relation_timer := 0.0
var visit_counter := 0
var rng := RandomNumberGenerator.new()

func configure(target_player: PlayerController, zone_definitions: Array, data: Dictionary) -> void:
	player = target_player
	zones = zone_definitions
	save_data = data
	rng.seed = 15041982
	if not save_data.has("crew_relations"):
		save_data["crew_relations"] = {"aurore":"neutral", "ecarlate":"neutral"}
	set_process(true)

func set_active_zone(zone_index: int) -> void:
	if zones.is_empty() or not is_instance_valid(player):
		return
	active_zone = clampi(zone_index, 0, zones.size() - 1)
	visit_counter += 1
	_clear_members()
	for crew_index in range(Crew25DCatalogV5.CREWS.size()):
		crew_attitudes[crew_index] = _choose_attitude(crew_index)
		_spawn_crew(crew_index, crew_attitudes[crew_index])
	relation_timer = 70.0 + float(active_zone % 3) * 12.0
	_emit_status()

func _process(delta: float) -> void:
	if members.is_empty() or not is_instance_valid(player):
		return
	relation_timer -= delta
	if relation_timer > 0.0:
		return
	relation_timer = 82.0
	var crew_index := (active_zone + visit_counter + int(Time.get_ticks_msec() / 1000)) % 2
	var current := String(crew_attitudes[crew_index])
	var next := "allied" if current == "neutral" and rng.randf() > 0.44 else "hostile" if current == "allied" and rng.randf() > 0.72 else "neutral"
	crew_attitudes[crew_index] = next
	var crew_id := String(Crew25DCatalogV5.CREWS[crew_index]["id"])
	(save_data["crew_relations"] as Dictionary)[crew_id] = next
	for member in members:
		if is_instance_valid(member) and String(member.get_meta("crew_id", "")) == crew_id:
			member.set_attitude(next)
	_emit_status()

func _spawn_crew(crew_index: int, attitude: String) -> void:
	var zone: Dictionary = zones[active_zone]
	var center: Vector3 = zone["center"]
	var island_radius := float(zone["radius"])
	var elevation := float(zone.get("elevation", center.y))
	var profiles := Crew25DCatalogV5.members(crew_index)
	var start_index := (active_zone * 3 + crew_index * 5 + visit_counter) % profiles.size()
	var spawn_count := 6
	var base_angle := -1.1 if crew_index == 0 else 1.9
	for slot in range(spawn_count):
		var profile: Dictionary = profiles[(start_index + slot) % profiles.size()]
		var member := RoamingCrewMemberV5.new()
		add_child(member)
		member.configure_crew(profile, player, attitude, 50000 + active_zone * 1000 + crew_index * 100 + slot)
		var angle := base_angle + float(slot) * 0.30
		var distance := island_radius * (0.28 + float(slot % 3) * 0.055)
		var spawn := center + Vector3(cos(angle) * distance, elevation + 7.0, sin(angle) * distance)
		member.set_home(spawn)
		player.register_enemy(member)
		members.append(member)

func _choose_attitude(crew_index: int) -> String:
	var crew_id := String(Crew25DCatalogV5.CREWS[crew_index]["id"])
	var stored := String((save_data.get("crew_relations", {}) as Dictionary).get(crew_id, "neutral"))
	var roll_seed := active_zone * 17 + visit_counter * 7 + crew_index * 31
	rng.seed = 15041982 + roll_seed
	var roll := rng.randf()
	var result := stored
	if roll < 0.24:
		result = "hostile"
	elif roll < 0.58:
		result = "neutral"
	else:
		result = "allied"
	(save_data["crew_relations"] as Dictionary)[crew_id] = result
	return result

func _emit_status() -> void:
	var labels: Array[String] = []
	for crew_index in range(2):
		var crew_name := String(Crew25DCatalogV5.CREWS[crew_index]["name"])
		var state := String(crew_attitudes[crew_index])
		var display := "ALLIÉ" if state == "allied" else "HOSTILE" if state == "hostile" else "NEUTRE"
		labels.append("%s : %s" % [crew_name, display])
	var text := "RENCONTRES LIBRES • " + "  |  ".join(labels)
	crew_status_changed.emit(text)
	print("CHK_V5_CREW_STATUS zone=%d %s" % [active_zone, text])

func _clear_members() -> void:
	for member in members:
		if is_instance_valid(member):
			member.queue_free()
	members.clear()
	Crew25DAssetFactoryV5.clear_cache()
