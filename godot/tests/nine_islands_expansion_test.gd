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
			_check(asset.get("texture") as Texture2D != null, "visuel chargé : " + String(profile["name"]))

	var world := GameWorldV4.new()
	root.add_child(world)
	var save := SaveSystem.default_data()
	world.configure(save)
	_check(world.visuals is WorldVisualsV4, "rendu 3D V4 actif")
	_check(world.visuals.get_node_or_null("OcéanContinuNeufÎles") != null, "océan 3D continu construit")
	for zone in range(9):
		var sea_dock := world.get_dock_position(zone, true)
		var land_dock := world.get_dock_position(zone, false)
		_check(is_equal_approx(sea_dock.y, PlayerController.BOAT_WATERLINE), "île %d : quai maritime accessible au bateau" % (zone + 1))
		_check(sea_dock.distance_to(land_dock) > 1.0, "île %d : embarquement et débarquement séparés" % (zone + 1))
	_check(world.get_dock_position(8, false).y > 40.0, "île 9 : débarquement sur le royaume céleste")
	_check(world.get_dock_position(8, true).y < 1.0, "île 9 : arrivée manuelle par l’océan")

	world.queue_free()
	Enemy25DAssetBank.clear_active_zone()
	await process_frame
	if failures == 0:
		print("CHK_NINE_ISLANDS_READY")
	else:
		push_error("%d vérification(s) neuf îles ont échoué" % failures)
	quit(failures)
