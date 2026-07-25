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
	# ÉTAPE 1 — héros principaux 2D réalistes dans le monde 3D.
	for hero_id in ["cheikh", "yvane", "nelvyn"]:
		var hero := HeroFactory.create_hero(hero_id, true)
		root.add_child(hero)
		var sprite := hero.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
		_check(hero.get_meta("visual_pipeline", "") == "2d_realistic_in_3d", "%s utilise le pipeline 2D réaliste / monde 3D" % hero_id)
		_check(sprite != null and sprite.texture != null, "%s possède un sprite réaliste importé" % hero_id)
		if sprite != null:
			_check(sprite.hframes == 4, "%s possède quatre poses terrestres" % hero_id)
			_check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "%s reste vertical avec la caméra 360°" % hero_id)
		HeroFactory.set_navigation_visual(hero, true)
		if sprite != null:
			_check(sprite.hframes == 1 and "steering" in sprite.texture.resource_path, "%s possède une pose dédiée au gouvernail" % hero_id)
		HeroFactory.set_navigation_visual(hero, false)
		hero.queue_free()

	var data := SaveSystem.default_data()
	var world := GameWorld.new()
	root.add_child(world)
	world.configure(data)
	await process_frame
	await physics_frame
	var player := world.get_player()
	_check(is_instance_valid(player), "le joueur est créé dans un monde 3D")
	_check(GameWorld.ZONES.size() == 6, "les six îles sont présentes")
	_check(EnemyFactory.ENEMIES.size() >= 8, "la galerie d’ennemis est chargée")
	_check(EnemyFactory.BOSSES.size() == 6, "chaque île possède un boss")

	# Déplacement et caméra troisième personne.
	var start := player.global_position
	player.set_move_input(Vector2(0.8, -1.0))
	for _frame in range(30):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(start) > 0.30, "le héros 2D se déplace réellement dans le relief 3D")
	_check(player.camera_arm.get_hit_length() > 3.0, "la caméra troisième personne conserve sa distance")

	# Navigation : personnage visible, bateau pilotable et pose de conduite.
	player.teleport_to_world_position(world.get_dock_position(0, false))
	world.toggle_boat()
	await physics_frame
	_check(player.boat_mode, "le héros embarque")
	_check(player.boat_visual != null and player.boat_visual.visible, "Le Bélier des Vents est visible")
	var pilot := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	_check(pilot != null and "steering" in pilot.texture.resource_path, "le pilote 2D réaliste est visible à la barre")
	var boat_start := player.global_position
	player.set_move_input(Vector2(-0.65, -1.0))
	for _frame in range(45):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(boat_start) > 0.60, "le bateau avance et tourne avec le joystick")
	_check(absf(player.boat_turn_rate) > 0.1, "le gouvernail répond au pilotage")

	# ÉTAPE 2 — contenu, météo, interface et progression.
	_check(world.visuals.destination_markers.size() == 6, "les six destinations marines sont signalées")
	world.visuals.set_zone_weather(5)
	_check(world.visuals.current_weather == "tempête", "la météo dynamique de la forteresse fonctionne")
	var menu := MenuUI.new()
	root.add_child(menu)
	menu.build()
	await process_frame
	_check(menu.map_buttons.size() == 6, "la carte du monde contient les six îles")
	_check(is_instance_valid(menu.hero_screen), "l’écran Cheikh / Yvane / Nelvyn est présent")

	# ÉTAPE 3 — sauvegarde et scène finale exportable.
	var save := SaveSystem.default_data()
	_check(save.has("hero_id") and save.has("unlocked_zones"), "la sauvegarde conserve le héros et la progression")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "la scène principale finale est chargeable")

	world.queue_free()
	menu.queue_free()
	await process_frame
	if failures == 0:
		print("PIPELINE FINAL RÉUSSI")
	else:
		push_error("%d vérification(s) finale(s) ont échoué" % failures)
	quit(failures)
