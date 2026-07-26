extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(GameWorldV4.ZONES_V4.size() == 9, "le monde ouvert contient neuf îles")
	_check(Enemy25DCatalog.ISLANDS.size() == 9, "le catalogue 2.5D contient neuf rosters")
	_check(String(GameWorldV4.ZONES_V4[6]["name"]) == "Île des Gâteaux", "île 7 enregistrée")
	_check(String(GameWorldV4.ZONES_V4[7]["name"]) == "Citadelle du Crâne", "île 8 enregistrée")
	_check(String(GameWorldV4.ZONES_V4[8]["name"]) == "Royaume Céleste", "île 9 enregistrée")

	for zone in range(6, 9):
		var island: Dictionary = Enemy25DCatalog.ISLANDS[zone]
		_check((island["commandants"] as Array).size() == 3, "île %d : trois commandants" % (zone + 1))
		_check((island["nakama"] as Array).size() == 3, "île %d : trois nakamas" % (zone + 1))
		var asset_path := "res://assets/roster25d/compact/island_%d.b64" % zone
		_check(FileAccess.file_exists(asset_path), "atlas 2.5D présent : " + asset_path)
		Enemy25DAssetBank.activate_zone(zone)
		var profiles: Array[Dictionary] = [Enemy25DCatalog.boss_for_zone(zone)]
		profiles.append_array(Enemy25DCatalog.commandants_for_zone(zone))
		profiles.append_array(Enemy25DCatalog.nakama_for_all_commandants(zone))
		_check(profiles.size() == 7, "île %d : roster complet de sept personnages" % (zone + 1))
		for profile in profiles:
			var asset := Enemy25DAssetBank.asset_for_profile(profile)
			var texture := asset.get("texture") as Texture2D
			_check(texture != null, "visuel chargé : " + String(profile["name"]))

	var world := GameWorldV4.new()
	root.add_child(world)
	var save := SaveSystem.default_data()
	world.configure(save)
	_check(world.visuals is WorldVisualsV4, "rendu 3D V4 actif")
	_check(world.visuals.get_node_or_null("OcéanContinuNeufÎles") != null, "océan 3D continu construit")
	_check(world.visuals.get_node_or_null("Zone_6/TerrainRelief3D") != null, "île 7 : terrain 3D construit")
	_check(world.visuals.get_node_or_null("Zone_6/GâteauRoyal") != null, "île 7 : ville-gâteau 3D construite")
	_check(world.visuals.get_node_or_null("Zone_7/CrâneForteresse") != null, "île 8 : forteresse-crâne 3D construite")
	_check(world.visuals.get_node_or_null("Zone_7/AnneauDeMagma") != null, "île 8 : magma 3D construit")
	_check(world.visuals.get_node_or_null("Zone_8/TerrasseCéleste") != null, "île 9 : palais céleste 3D construit")
	_check(world.visuals.get_node_or_null("QuaiMaritimeRoyaumeCéleste/AscenseurDEau") != null, "île 9 : accès maritime vers le ciel construit")
	for zone in range(9):
		var sea_dock := world.get_dock_position(zone, true)
		var land_dock := world.get_dock_position(zone, false)
		_check(is_equal_approx(sea_dock.y, PlayerController.BOAT_WATERLINE), "île %d : quai maritime accessible au bateau" % (zone + 1))
		_check(sea_dock.distance_to(land_dock) > 1.0, "île %d : embarquement et débarquement séparés" % (zone + 1))
	_check(world.get_dock_position(8, false).y > 40.0, "île 9 : débarquement sur le royaume céleste")
	_check(world.get_dock_position(8, true).y < 1.0, "île 9 : arrivée manuelle par l’océan")

	# Les systèmes historiques doivent aussi reconnaître les trois nouvelles îles.
	world.current_zone = 8
	var player := world.get_player()
	player.teleport_to_world_position(Vector3(1900, 5, -110))
	GameplayRepair.call("_rescue_to_zone", world)
	_check(player.global_position.y > 40.0, "secours V4 : retour sur l’île céleste et non sur l’ancienne île 6")
	var creature_kind := String(Roster25DDirector.call("_animal_creature", 7, 0))
	_check(not creature_kind.is_empty(), "la faune de l’île 8 conserve un modèle 3D")

	world.queue_free()
	Enemy25DAssetBank.clear_active_zone()
	await process_frame
	if failures == 0:
		print("CHK_NINE_ISLANDS_READY")
	else:
		push_error("%d vérification(s) neuf îles ont échoué" % failures)
	quit(failures)
