class_name CrewEncounterDirectorV6
extends CrewEncounterDirectorV5

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
		var member := MobileCrewMemberV6.new()
		add_child(member)
		member.configure_crew(profile, player, attitude, 50000 + active_zone * 1000 + crew_index * 100 + slot)
		member.set_follow_slot(_formation_slot(crew_index, slot))
		var angle := base_angle + float(slot) * 0.30
		var distance := island_radius * (0.28 + float(slot % 3) * 0.055)
		var spawn := center + Vector3(cos(angle) * distance, elevation + 7.0, sin(angle) * distance)
		member.set_home(spawn)
		player.register_enemy(member)
		members.append(member)
	set_meta("mobile_crews_v6", true)

func _formation_slot(crew_index: int, slot: int) -> Vector3:
	var row := int(slot / 3)
	var column := slot % 3
	var side := -1.0 if crew_index == 0 else 1.0
	var lateral := (float(column) - 1.0) * 2.15 + side * 1.25
	var behind := 3.8 + float(row) * 2.25 + float(crew_index) * 0.55
	return Vector3(lateral, 0.0, behind)
