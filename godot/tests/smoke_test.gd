extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC  " + message)

func _run() -> void:
	var data := SaveSystem.default_data()
	var world := GameWorld.new()
	root.add_child(world)
	world.configure(data)
	await process_frame
	await physics_frame

	var player := world.get_player()
	_check(is_instance_valid(player), "le joueur est créé")
	_check(get_nodes_in_group("enemies").size() == 8, "la première vague contient huit ennemis")
	_check(player.hero_id == "cheikh", "Cheikh est le héros initial")
	_check(is_equal_approx(player.health, player.max_health), "le héros commence avec sa vie complète")
	_check(player.camera_pivot.top_level, "la caméra troisième personne suit le héros avec inertie")
	_check(player.camera.position.x > 0.4, "la caméra est placée au-dessus de l’épaule")
	_check(player.camera_arm.get_hit_length() > 3.2, "la caméra ne percute pas la capsule du héros")

	var sprite := player.get_node_or_null("Visuel_cheikh/RigVisuel/CharacterArt") as Sprite3D
	_check(sprite != null, "la planche de Cheikh est chargée")
	if sprite != null:
		_check(sprite.hframes == 4, "les quatre poses de Cheikh sont disponibles")
		_check(sprite.texture != null and sprite.texture.get_width() == 1776, "la texture de dos HD est importée sans déformation")
		_check(not sprite.visible, "la copie 3D qui créait un héros géant à gauche est masquée")

	var yaw_before := player.camera_target_yaw
	player.set_camera_stick(Vector2(1.0, 0.0))
	for _frame in range(8):
		await physics_frame
	player.set_camera_stick(Vector2.ZERO)
	_check(player.camera_target_yaw < yaw_before, "le stick CAMÉRA 360° tourne réellement la vue")

	player.camera_target_yaw = player.rotation.y + PI
	player.camera_manual_timer = 2.0
	for _frame in range(40):
		await physics_frame
	_check(player.camera_front_view, "la caméra peut passer devant pour montrer le visage")

	var start_position := player.global_position
	player.set_move_input(Vector2(1.0, 0.0))
	for _frame in range(12):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(start_position) > 0.25, "le joystick déplace réellement le héros")
	_check(Vector2(player.velocity.x, player.velocity.z).length() < player._movement_speed() * 1.2, "l’accélération du héros reste maîtrisée")

	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy := enemies[0] as EnemyAI
		enemy.global_position = player.global_position + Vector3(0.0, 0.0, -2.2)
		var enemy_health := enemy.health
		player.attack()
		_check(enemy.health < enemy_health, "l’attaque tactile touche une cible proche")
		_check(player.get_node_or_null("TraînéeAttaque") != null, "l’attaque produit une traînée d’impact visible")
		var energy_before := player.energy
		player.skill()
		_check(player.energy < energy_before, "le pouvoir consomme de l’énergie")
	else:
		_check(false, "un ennemi est disponible pour tester le combat")

	player.switch_hero()
	await process_frame
	_check(player.hero_id == "yvane", "le changement de héros passe à Yvane")
	_check(player.get_node_or_null("Visuel_yvane/RigVisuel/CharacterArt") != null, "la planche HD de Yvane est chargée")
	player.switch_hero()
	await process_frame
	_check(player.hero_id == "nelvyn", "le changement de héros passe à Nelvyn")
	_check(player.get_node_or_null("Visuel_nelvyn/RigVisuel/CharacterArt") != null, "la planche HD de Nelvyn est chargée")

	_check(float(GameWorld.ZONES[0]["radius"]) >= 100.0, "la première île est nettement agrandie")
	_check(Vector3(GameWorld.ZONES[0]["center"]).distance_to(Vector3(GameWorld.ZONES[1]["center"])) > 300.0, "les îles forment un véritable archipel")
	_check(world.visuals.destination_markers.size() == 6, "les six îles possèdent une balise de destination")
	_check(world.get_unlocked_zones() == [0], "seule l’île de départ est débloquée au commencement")

	world.set_destination(1)
	player.global_position = world.get_dock_position(0, false)
	world.toggle_boat()
	await physics_frame
	_check(player.boat_mode, "le héros embarque depuis le quai")
	_check(player.boat_visual != null and player.boat_visual.visible, "le bateau jouable est visible")
	var boat_start := player.global_position
	player.set_move_input(Vector2(0.0, -1.0))
	for _frame in range(36):
		await physics_frame
	player.set_move_input(Vector2.ZERO)
	_check(player.global_position.distance_to(boat_start) > 0.5, "le joueur navigue lui-même avec le joystick")
	_check(player.boat_speed > 0.0, "le bateau possède accélération et inertie")
	player.global_position = world.get_dock_position(1, true)
	world.toggle_boat()
	await process_frame
	await physics_frame
	_check(not player.boat_mode, "le bateau peut accoster manuellement")
	_check(world.current_zone == 1, "l’accostage active la nouvelle île")
	_check(world.get_unlocked_zones().has(1), "la Jungle sauvage est débloquée uniquement après l’accostage")
	_check(get_nodes_in_group("enemies").size() == 8, "une nouvelle vague attend sur l’île découverte")

	player.set_difficulty("decouverte")
	player.health = 8.0
	player.invulnerability = 0.0
	player.receive_damage(999.0)
	_check(is_equal_approx(player.health, 1.0), "en Découverte le héros prend des dégâts sans mourir")
	player.heal(9999.0)
	player.set_difficulty("difficile")
	var hard_health := player.health
	player.invulnerability = 0.0
	player.receive_damage(12.0)
	_check(hard_health - player.health > 12.0, "en Difficile les dégâts sont fortement augmentés")
	player.heal(9999.0)
	player.set_difficulty("intermediaire")
	_check(player.can_be_defeated, "en Intermédiaire la mort reste possible")

	_check(EnemyFactory.BOSSES.size() == 6, "chaque île possède son propre boss")
	var boss_designs: Dictionary = {}
	for profile in EnemyFactory.BOSSES:
		boss_designs[String(profile["design"])] = true
	_check(boss_designs.size() == 6, "les six boss ont six designs distincts")
	var brakor := EnemyFactory.create_enemy(EnemyFactory.BOSSES[0], player)
	root.add_child(brakor)
	_check(brakor.get_node_or_null("BlindageBrakor") != null, "Brakor possède son blindage et son ancre")
	var vorga := EnemyFactory.create_enemy(EnemyFactory.BOSSES[5], player)
	root.add_child(vorga)
	_check(vorga.get_node_or_null("OrbeOrage") != null, "Vorga possède ses orbes et sabres d’orage")
	brakor.queue_free()
	vorga.queue_free()

	var menu := MenuUI.new()
	root.add_child(menu)
	menu.build()
	await process_frame
	_check(is_instance_valid(menu.main_menu), "le menu principal est construit")
	_check(is_instance_valid(menu.difficulty_screen), "l’écran des trois difficultés est présent")
	_check(menu.map_buttons.size() == 6, "la carte indique les six destinations")
	var reference := menu.main_menu.get_node_or_null("MenuRéférence")
	_check(reference != null, "le menu fidèle à l’image de référence est présent")
	if reference != null:
		_check(reference.get_child_count() >= 15, "les zones tactiles du menu sont installées")
		var selected_zone := [-1]
		menu.zone_selected.connect(func(index: int): selected_zone[0] = index)
		var fortress_button := reference.get_child(14) as Button
		fortress_button.emit_signal("pressed")
		_check(selected_zone[0] == 5, "la Forteresse de la tempête devient une destination de navigation")

	var game_ui := GameUI.new()
	root.add_child(game_ui)
	await process_frame
	game_ui.update_hero_pose("cheikh", 2, false)
	_check(is_instance_valid(game_ui.hero_view), "le héros 2.5D est affiché dans le cadre troisième personne")
	_check(game_ui.hero_view.texture is AtlasTexture, "la pose animée du héros est découpée dans la planche HD")
	if game_ui.hero_view.texture is AtlasTexture:
		var atlas := game_ui.hero_view.texture as AtlasTexture
		_check(is_equal_approx(atlas.region.position.x, 888.0), "la pose d’attaque est synchronisée dans le HUD")
	game_ui.update_hero_pose("cheikh", 0, true)
	var front_atlas := game_ui.hero_view.texture as AtlasTexture
	_check(front_atlas.atlas.resource_path.ends_with("cheikh_poses.webp"), "la vue avant s’affiche quand la caméra regarde le visage")
	_check(game_ui.hud.get_node_or_null("StickCaméra360") != null, "le stick caméra séparé est installé à gauche")
	_check(is_instance_valid(game_ui.boat_button), "le bouton contextuel EMBARQUER / ACCOSTER est présent")

	world.queue_free()
	menu.queue_free()
	game_ui.queue_free()
	await process_frame

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main._start_new_game("decouverte")
	await process_frame
	_check(main.world.difficulty == "decouverte" and not main.player.can_be_defeated, "le choix Découverte démarre une vraie nouvelle partie")
	var zone_before_map: int = main.world.current_zone
	main._travel_to_zone(5)
	_check(main.world.current_zone == zone_before_map, "la carte ne téléporte plus directement le joueur")
	_check(main.world.destination_zone == 5, "la carte transforme l’île choisie en destination de navigation")
	main.queue_free()
	await process_frame

	if failures == 0:
		print("SMOKE TEST RÉUSSI")
	else:
		push_error("%d vérification(s) ont échoué" % failures)
	quit(failures)
