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
	# ÉTAPE 1 — les trois héros officiels restent dans le monde 3D.
	for hero_id in ["cheikh", "yvane", "nelvyn"]:
		var hero := HeroFactory.create_hero(hero_id, true)
		root.add_child(hero)
		var sprite := hero.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
		_check(hero.get_meta("visual_pipeline", "") == "2d_realistic_in_3d", "%s utilise le pipeline 2.5D / monde 3D" % hero_id)
		_check(sprite != null and sprite.texture != null, "%s possède son visuel officiel" % hero_id)
		if sprite != null:
			_check(sprite.hframes == 4, "%s possède quatre poses terrestres" % hero_id)
			_check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "%s reste vertical avec la caméra 360°" % hero_id)
		HeroFactory.set_navigation_visual(hero, true)
		if sprite != null:
			_check(sprite.hframes == 1 and "steering" in sprite.texture.resource_path, "%s possède une pose dédiée au gouvernail" % hero_id)
		HeroFactory.set_navigation_visual(hero, false)
		hero.queue_free()

	var data := SaveSystem.default_data()
	var world := GameWorldV4.new()
	root.add_child(world)
	world.configure(data)
	await process_frame
	await physics_frame
	var player := world.get_player()
	_check(is_instance_valid(player), "le joueur est créé dans le monde ouvert 3D")
	_check(GameWorldV4.ZONES_V4.size() == 9, "les neuf îles sont présentes dans le même monde")
	_check(Enemy25DCatalog.ISLANDS.size() == 9, "les neuf rosters importants sont enregistrés")
	_check(String(GameWorldV4.ZONES_V4[6]["name"]) == "Île des Gâteaux", "l’île 7 est l’Île des Gâteaux")
	_check(String(GameWorldV4.ZONES_V4[7]["name"]) == "Citadelle du Crâne", "l’île 8 est la forteresse-crâne entourée de magma")
	_check(String(GameWorldV4.ZONES_V4[8]["name"]) == "Royaume Céleste", "l’île 9 est le royaume dans le ciel")

	# Déplacement et caméra troisième personne.
	var start := player.global_position
	player.set_move_input(Vector2(0.8, -1.0))
	for _frame in range(30):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(start) > 0.30, "le héros se déplace réellement dans le relief 3D")
	_check(player.camera_arm.get_hit_length() > 3.0, "la caméra troisième personne conserve sa distance")

	# Navigation libre vers les nouvelles îles.
	world.set_destination(8)
	player.teleport_to_world_position(world.get_dock_position(0, false))
	world.toggle_boat()
	await physics_frame
	_check(player.boat_mode, "le héros embarque pour naviguer lui-même")
	_check(player.boat_visual != null and player.boat_visual.visible, "le bateau est visible dans l’océan continu")
	var pilot := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	_check(pilot != null and "steering" in pilot.texture.resource_path, "le pilote reste visible à la barre")
	_check(world.destination_zone == 8, "le cap peut viser le quai maritime de l’île 9")
	var boat_start := player.global_position
	player.set_move_input(Vector2(-0.65, -1.0))
	for _frame in range(45):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(boat_start) > 0.60, "le bateau avance et tourne avec le joystick")
	_check(absf(player.boat_turn_rate) > 0.1, "le gouvernail répond au pilotage")

	# Décors 3D, météo, carte et progression.
	_check(world.visuals.destination_markers.size() == 9, "les neuf destinations marines sont signalées")
	_check(world.visuals.get_node_or_null("Zone_6") != null, "le décor 3D de l’île des Gâteaux est construit")
	_check(world.visuals.get_node_or_null("Zone_7") != null, "le décor 3D de la Citadelle du Crâne est construit")
	_check(world.visuals.get_node_or_null("Zone_8") != null, "le décor 3D du Royaume Céleste est construit")
	world.visuals.set_zone_weather(7)
	_check(world.visuals.current_weather == "cendres", "les cendres et le magma de l’île 8 influencent l’environnement")
	var menu := MenuUIV4.new()
	root.add_child(menu)
	menu.build()
	await process_frame
	_check(menu.map_buttons.size() == 9, "la carte du monde contient les neuf îles")
	_check(is_instance_valid(menu.hero_screen), "l’écran Cheikh / Yvane / Nelvyn est présent")

	var save := SaveSystem.default_data()
	_check(save.has("hero") and save.has("zone") and save.has("unlocked_zones"), "la sauvegarde conserve le héros et la progression")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "la scène principale V4 est chargeable")

	world.queue_free()
	menu.queue_free()
	await process_frame
	if failures == 0:
		print("PIPELINE FINAL RÉUSSI")
	else:
		push_error("%d vérification(s) finale(s) ont échoué" % failures)
	quit(failures)
