extends "res://scripts/studio_game_director.gd"

# Finition adaptée au monde V4. Les six silhouettes existantes restent
# inchangées. Les trois nouvelles îles reçoivent la passe côtière sans
# dupliquer leurs monuments 3D spécifiques.
func _apply_world_pass(game_world: GameWorld) -> void:
	if not is_instance_valid(game_world.visuals):
		return
	var zone_definitions: Array = GameWorldV4.ZONES_V4 if game_world is GameWorldV4 else GameWorld.ZONES
	for zone_index in range(zone_definitions.size()):
		var zone_root := game_world.visuals.get_node_or_null("Zone_%d" % zone_index) as Node3D
		if zone_root == null or zone_root.has_node("FinitionStudio"):
			continue
		var finish := Node3D.new()
		finish.name = "FinitionStudio"
		zone_root.add_child(finish)
		var radius := float(zone_definitions[zone_index]["radius"])
		if zone_index < 6:
			_build_zone_silhouette(finish, zone_index, radius)
		else:
			_build_coast_rocks(finish, zone_index, radius, _zone_palette(zone_index))
	print("CHK_STUDIO_WORLD_READY zones=%d" % zone_definitions.size())

func _zone_palette(zone_index: int) -> Dictionary:
	match zone_index:
		6:
			return {"rock": Color("a96780"), "building": Color("e4a3bd")}
		7:
			return {"rock": Color("241d20"), "building": Color("4c2928")}
		8:
			return {"rock": Color("729bb4"), "building": Color("e4f1f8")}
		_:
			return super._zone_palette(zone_index)
