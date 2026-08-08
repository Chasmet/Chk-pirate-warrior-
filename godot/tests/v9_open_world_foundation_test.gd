extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC V9  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog_errors := RegionCatalogV9.validate()
	_check(catalog_errors.is_empty(), "le catalogue des régions est cohérent : " + "; ".join(catalog_errors))
	_check(RegionCatalogV9.REGIONS.size() == 10, "dix régions sont définies")
	_check(RegionCatalogV9.TOTAL_NPCS == 200, "deux cents profils de PNJ sont disponibles")
	var poi_total := 0
	var unique_names := {}
	for region_index in range(RegionCatalogV9.REGIONS.size()):
		var region: Dictionary = RegionCatalogV9.REGIONS[region_index]
		poi_total += (region["pois"] as Array).size()
		_check(float(region["radius"]) >= 320.0, "la région %s possède une grande emprise" % String(region["name"]))
		for npc_index in range(RegionCatalogV9.NPCS_PER_REGION):
			var profile := RegionCatalogV9.npc_profile(region_index, npc_index)
			unique_names[String(profile["name"])] = true
			_check(not String(profile["job"]).is_empty(), "le PNJ %s possède un métier" % String(profile["name"]))
	_check(poi_total == 80, "quatre-vingts points d’intérêt sont implantés manuellement")
	_check(unique_names.size() == 200, "les deux cents PNJ possèdent une identité distincte")

	var save := SaveSystem.default_data()
	save["hero"] = "cheikh"
	save["zone"] = 1
	save["destination_zone"] = 2
	save["unlocked_zones"] = [0, 1]
	var world := GameWorldV9.new()
	root.add_child(world)
	world.configure(save)
	await process_frame
	await physics_frame

	_check(bool(world.get_meta("open_world_foundation_v9", false)), "la fondation monde ouvert V9 est active")
	_check(world.open_world_director is OpenWorldRegionDirectorV9, "le directeur régional V9 est intégré au monde existant")
	var director := world.open_world_director
	_check(director.region_count() == 10, "le directeur charge les dix régions")
	_check(director.active_npc_count() == 20, "vingt PNJ complets sont actifs dans la région proche")
	_check(director.simulated_npc_count() == 180, "cent quatre-vingts PNJ restent simulés à distance")
	_check(director.visible_region_root_count() <= 3, "le streaming ne garde jamais plus de trois racines régionales visibles")
	_check(director.current_region_name() == "Grande forêt", "la deuxième île V8 est reliée à la Grande forêt V9")

	director.force_region_for_test(5)
	director.run_update_for_test()
	await process_frame
	_check(director.current_region_name() == "Marais brumeux", "le nouveau marais peut devenir la région active")
	_check(director.active_npc_count() == 20, "le marais charge ses vingt habitants")
	_check(director.simulated_npc_count() == 180, "les autres habitants continuent leur simulation distante")
	var marsh_root := director.get_node_or_null("RégionV9_05_marais_brumeux")
	_check(marsh_root != null and marsh_root.visible, "la racine physique du marais est visible")
	if marsh_root != null:
		var marsh_pads := 0
		for child in marsh_root.get_children():
			if String(child.name).begins_with("ÎlotMarais_"):
				marsh_pads += 1
		_check(marsh_pads == 9, "neuf îlots physiques composent le marais")

	var routine_ready := true
	for citizen in director.active_citizens:
		if not is_instance_valid(citizen) or not bool(citizen.get_meta("daily_routine_v9", false)):
			routine_ready = false
			break
	_check(routine_ready, "chaque habitant actif possède une routine quotidienne")
	if not director.active_citizens.is_empty():
		var first := director.active_citizens[0]
		first.set_world_context(23.25, "soleil")
		_check(first.current_state == "sommeil", "les PNJ rentrent dormir la nuit")
		first.set_world_context(10.0, "tempête")
		_check(first.current_state == "abri", "les PNJ se mettent à l’abri pendant une tempête")

	director.force_region_for_test(9)
	director.run_update_for_test()
	await process_frame
	_check(director.current_region_name() == "Montagnes enneigées", "la dixième région est accessible au système de streaming")
	_check(director.visible_region_root_count() <= 3, "le budget de racines visibles reste respecté après un changement rapide")

	world.queue_free()
	await process_frame
	if failures == 0:
		print("CHK_V9_OPEN_WORLD_FOUNDATION_READY")
		print("CHK_V9_TEN_AUTHORED_REGIONS_READY")
		print("CHK_V9_200_NPCS_SIMULATION_READY")
		print("CHK_V9_ANDROID_STREAMING_READY")
	else:
		push_error("%d vérification(s) V9 ont échoué" % failures)
	quit(failures)
