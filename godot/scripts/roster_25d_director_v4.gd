extends "res://scripts/roster_25d_director.gd"

# Variante neuf îles : elle conserve le même chargement mémoire par île,
# mais utilise les coordonnées du monde étendu pour les zones 7, 8 et 9.
func _spawn_commandant_pairs(zone_index: int) -> void:
	var zone: Dictionary = GameWorldV4.ZONES_V4[clampi(zone_index, 0, GameWorldV4.ZONES_V4.size() - 1)]
	var center: Vector3 = zone["center"]
	var radius := float(zone["radius"])
	for index in range(3):
		var angle := 0.55 + TAU * float(index) / 3.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-direction.z, 0.0, direction.x)
		var pair_center := center + direction * radius * 0.42
		var commandant := _spawn_profile(Enemy25DCatalog.commandant_for_zone(zone_index, index), pair_center + tangent * 2.5)
		var nakama := _spawn_profile(Enemy25DCatalog.nakama_for_zone(zone_index, index), pair_center - tangent * 3.0)
		if is_instance_valid(commandant) and is_instance_valid(nakama):
			commandant.set_meta("nakama_instance_id", nakama.get_instance_id())
			nakama.set_meta("commandant_instance_id", commandant.get_instance_id())

func _spawn_animals(zone_index: int) -> void:
	var zone: Dictionary = GameWorldV4.ZONES_V4[clampi(zone_index, 0, GameWorldV4.ZONES_V4.size() - 1)]
	var center: Vector3 = zone["center"]
	var radius := float(zone["radius"])
	for index in range(4):
		var angle := 1.12 + TAU * float(index) / 4.0
		var distance := radius * (0.27 if index % 2 == 0 else 0.54)
		var position := center + Vector3(cos(angle), 0.0, sin(angle)) * distance
		_spawn_profile(Enemy25DCatalog.animal_for_zone(zone_index, index), position)

func _apply_pending_boss_visual() -> void:
	if not is_instance_valid(world):
		return
	for node in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var boss := node as EnemyAI
		if boss.has_meta("visual_pipeline"):
			continue
		var zone_index := clampi(int(boss.profile.get("zone", world.current_zone)), 0, GameWorldV4.ZONES_V4.size() - 1)
		var profile := Enemy25DCatalog.boss_for_zone(zone_index)
		profile["difficulty"] = world.difficulty
		profile["zone"] = zone_index
		profile["id"] = String(boss.profile.get("id", profile["id"]))
		_upgrade_existing_boss(boss, profile)
