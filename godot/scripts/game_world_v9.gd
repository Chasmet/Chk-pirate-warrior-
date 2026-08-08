class_name GameWorldV9
extends GameWorldV6

var open_world_director: OpenWorldRegionDirectorV9

func configure(data: Dictionary) -> void:
	super.configure(data)
	open_world_director = OpenWorldRegionDirectorV9.new()
	open_world_director.name = "MondeOuvertDixRégionsV9"
	add_child(open_world_director)
	open_world_director.configure(self, player, visuals)
	open_world_director.set_core_zone(current_zone)
	set_meta("open_world_foundation_v9", true)
	set_meta("ten_authored_regions_v9", true)
	set_meta("two_hundred_npcs_v9", true)
	set_meta("android_streaming_v9", true)
	print("CHK_WORLD_V9_READY authored_regions=%d npc_population=%d" % [RegionCatalogV9.REGION_COUNT, RegionCatalogV9.TOTAL_NPCS])

func _activate_zone(index: int, announce: bool, from_boat: bool) -> void:
	super._activate_zone(index, announce, from_boat)
	if is_instance_valid(open_world_director):
		open_world_director.set_core_zone(current_zone)
