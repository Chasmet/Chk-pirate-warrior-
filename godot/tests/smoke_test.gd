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
	var world := GameWorld.new()
	root.add_child(world)
	world.configure(SaveSystem.default_data())
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
	_check(sprite != null, "le personnage troisième personne de Cheikh est visible")
	if sprite != null:
		_check(sprite.hframes == 4, "les quatre poses de Cheikh sont disponibles")
		_check(sprite.texture != null and sprite.texture.get_width() == 1776, "la texture de dos HD est importée sans déformation")

	var yaw_before := player.camera_target_yaw
	player.add_camera_drag(Vector2(80.0, -20.0))
	_check(player.camera_target_yaw < yaw_before, "le glissement à droite contrôle librement la caméra")

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

	world.travel_to_zone(2, false)
	await process_frame
	_check(world.current_zone == 2, "la carte voyage vers le Royaume des neiges")
	_check(get_nodes_in_group("enemies").size() == 8, "une nouvelle vague apparaît après le voyage")
	player.global_position = Vector3(GameWorld.ZONES[2]["spawn"]) + Vector3(90.0, 0.0, 0.0)
	await process_frame
	var island_center: Vector3 = GameWorld.ZONES[2]["spawn"]
	var island_offset := player.global_position - island_center
	island_offset.y = 0.0
	_check(island_offset.length() <= 57.1, "le héros ne peut plus tomber hors de l’île")

	var menu := MenuUI.new()
	root.add_child(menu)
	menu.build()
	await process_frame
	_check(is_instance_valid(menu.main_menu), "le menu principal est construit")
	var reference := menu.main_menu.get_node_or_null("MenuRéférence")
	_check(reference != null, "le menu fidèle à l’image de référence est présent")
	if reference != null:
		_check(reference.get_child_count() >= 15, "les zones tactiles du menu sont installées")
		var selected_zone := [-1]
		menu.zone_selected.connect(func(index: int): selected_zone[0] = index)
		var fortress_button := reference.get_child(14) as Button
		fortress_button.emit_signal("pressed")
		_check(selected_zone[0] == 5, "la Forteresse de la tempête ouvre la sixième région")

	world.queue_free()
	menu.queue_free()
	await process_frame
	if failures == 0:
		print("SMOKE TEST RÉUSSI")
	else:
		push_error("%d vérification(s) ont échoué" % failures)
	quit(failures)
