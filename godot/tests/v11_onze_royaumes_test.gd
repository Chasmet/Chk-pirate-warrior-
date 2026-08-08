extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC V11  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog_errors := RegionCatalogV11.validate()
	_check(catalog_errors.is_empty(), "le catalogue V11 est cohérent : " + "; ".join(catalog_errors))
	_check(RegionCatalogV11.all_regions().size() == 11, "onze royaumes sont déclarés")
	_check(RegionCatalogV11.TOTAL_NPCS == 200, "les dix régions vivantes conservent 200 habitants simulés")
	_check(RegionCatalogV11.npc_count_for_region(RegionCatalogV11.FINAL_REGION_INDEX) == 0, "le Royaume Troublé reste sans habitants")
	_check((RegionCatalogV11.FINAL_REGION["fauna"] as Array).is_empty(), "le Royaume Troublé reste sans faune")
	_check((RegionCatalogV11.FINAL_REGION["pois"] as Array).size() >= 10, "la région finale possède dix lieux remarquables")
	_check(not String(RegionCatalogV11.FINAL_REGION["rare_item"]).is_empty(), "un objet rare conclut l'aventure")

	var save := SaveSystem.default_data()
	save["hero"] = "cheikh"
	save["zone"] = 1
	save["destination_zone"] = 2
	save["unlocked_zones"] = [0, 1]
	var world := GameWorldV11.new()
	root.add_child(world)
	world.configure(save)
	await process_frame
	await physics_frame

	_check(bool(world.get_meta("open_world_foundation_v11", false)), "le monde V11 est actif")
	_check(bool(world.get_meta("final_kingdom_dockable_v11", false)), "le Royaume Troublé possède une logique d'accostage")
	_check(world.open_world_director is OpenWorldRegionDirectorV11, "le directeur V11 remplace la fondation V9")
	_check(world.final_landmass is FinalKingdomLandmassV11, "un terrain physique dédié est construit pour l'île finale")
	_check(bool(world.final_landmass.get_meta("playable_final_landmass_v11", false)), "le terrain final est marqué jouable")

	var director := world.open_world_director
	_check(director.region_count() == 11, "le streaming charge onze régions")
	_check(director.active_npc_count() == 20, "vingt habitants sont actifs dans une région vivante proche")
	_check(director.simulated_npc_count() == 180, "les autres habitants restent simulés à distance")
	_check(director.visible_region_root_count() <= 3, "le budget Android de trois racines visibles est conservé")
	if not director.active_citizens.is_empty():
		var citizen := director.active_citizens[0]
		_check(citizen is AmbientCitizenV11, "les habitants utilisent le rendu humain V11")
		_check(bool(citizen.get_meta("humanoid_visual_v11", false)), "la capsule monobloc V9 est remplacée par un corps articulé")

	director.force_region_for_test(RegionCatalogV11.FINAL_REGION_INDEX)
	director.run_update_for_test()
	await process_frame
	_check(director.current_region_name() == "Royaume Troublé", "le onzième royaume peut devenir la région active")
	_check(director.active_npc_count() == 0, "aucun PNJ n'est généré dans le royaume abandonné")
	_check(director.simulated_npc_count() == 200, "les 200 habitants du reste du monde continuent leur simulation")
	_check(director.visible_region_root_count() <= 3, "le streaming reste borné dans la région finale")
	var final_root := director.get_node_or_null("RégionV9_10_royaume_trouble")
	_check(final_root != null, "la racine visuelle du Royaume Troublé existe")

	var water_dock := world.get_final_dock_position(true)
	var land_dock := world.get_final_dock_position(false)
	_check(water_dock.distance_to(land_dock) > 40.0, "le quai possède une zone mer et une zone terre distinctes")
	_check(world._is_on_final_region(RegionCatalogV11.final_relic_position()), "la relique est bien placée sur l'île jouable")

	world.player.teleport_to_world_position(RegionCatalogV11.final_relic_position())
	world.final_region_active = true
	director.force_region_for_test(RegionCatalogV11.FINAL_REGION_INDEX)
	director._update_final_relic(0.1)
	_check(world.is_final_relic_collected(), "le Cœur des Souvenirs peut réellement être ramassé")
	_check(bool(world.save_data.get("final_relic_found", false)), "la collecte est ajoutée aux données de sauvegarde")

	var menu := MenuUIV11.new()
	root.add_child(menu)
	menu.build()
	await process_frame
	_check(menu.map_buttons.size() == 11, "la carte de l'interface présente onze royaumes")
	_check(menu.main_menu.get_node_or_null("BoutonCarteOnzeRoyaumes") != null, "le menu affiche le bouton Carte du monde 11 royaumes")
	_check(menu.main_menu.get_node_or_null("BandeauCHKOnzeRoyaumes") != null, "le logo CHK existant est intégré au nouveau bandeau")

	menu.queue_free()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("CHK_V11_ONZE_ROYAUMES_READY")
		print("CHK_V11_FINAL_KINGDOM_READY")
		print("CHK_V11_HUMANOID_NPCS_READY")
		print("CHK_V11_INTERFACE_LOGO_READY")
		print("CHK_V11_FINAL_RELIC_READY")
	else:
		push_error("%d vérification(s) V11 ont échoué" % failures)
	quit(failures)
