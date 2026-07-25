extends SceneTree

var failures := 0
var minimum_land_distance := 2.15
var maximum_land_distance := 4.75

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC CAMÉRA  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _camera_distance_to_hero(player: PlayerController) -> float:
	var profile: Dictionary = HeroFactory.HEROES.get(player.hero_id, HeroFactory.HEROES["cheikh"])
	var center := player.global_position + Vector3.UP * float(profile["height"]) * 0.55
	return player.camera.global_position.distance_to(center)

func _land_camera_is_above_surface(player: PlayerController) -> bool:
	var minimum_y := maxf(player.global_position.y + 0.55, PlayerController.BOAT_WATERLINE + 1.55)
	return player.camera.global_position.y >= minimum_y

func _run() -> void:
	var data := SaveSystem.default_data()
	var world := GameWorld.new()
	root.add_child(world)
	world.configure(data)
	await process_frame
	for _frame in range(120):
		await physics_frame

	var player := world.get_player()
	_check(is_instance_valid(player), "le joueur est présent")
	if not is_instance_valid(player):
		quit(1)
		return

	player.invulnerability = 999.0
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	# Test au repos puis pendant une orbite complète et un déplacement.
	var minimum_seen := 999.0
	var maximum_seen := 0.0
	var surface_failures := 0
	for quarter in range(4):
		player.set_camera_stick(Vector2(1.0, 0.0))
		player.set_move_input(Vector2(0.25 if quarter % 2 == 0 else -0.25, -0.85))
		for _frame in range(55):
			await physics_frame
			var distance := _camera_distance_to_hero(player)
			minimum_seen = minf(minimum_seen, distance)
			maximum_seen = maxf(maximum_seen, distance)
			if not _land_camera_is_above_surface(player):
				surface_failures += 1
	player.set_camera_stick(Vector2.ZERO)
	player.set_move_input(Vector2.ZERO)

	_check(surface_failures == 0, "la caméra ne descend jamais dans l'océan ou sous l'île")
	_check(minimum_seen >= minimum_land_distance, "la caméra ne rentre pas dans le héros")
	_check(maximum_seen <= maximum_land_distance, "la caméra reste en troisième personne rapprochée")

	# Les trois héros doivent conserver exactement le même cadrage stable.
	for expected in ["yvane", "nelvyn", "cheikh"]:
		player.switch_hero()
		for _frame in range(45):
			await physics_frame
		var hero_distance := _camera_distance_to_hero(player)
		_check(player.hero_id == expected, "le changement passe à %s" % expected)
		_check(hero_distance >= minimum_land_distance and hero_distance <= maximum_land_distance, "%s reste correctement cadré" % expected)
		_check(_land_camera_is_above_surface(player), "%s ne provoque pas de passage sous le décor" % expected)

	# Vérification spécifique du bateau et de la ligne d'eau.
	player.teleport_to_world_position(world.get_dock_position(0, false))
	world.toggle_boat()
	for _frame in range(90):
		await physics_frame
	_check(player.boat_mode, "le joueur embarque pour le test caméra bateau")
	var boat_distance := player.camera.global_position.distance_to(player.global_position)
	_check(player.camera.global_position.y >= PlayerController.BOAT_WATERLINE + 3.0, "la caméra du bateau reste au-dessus de l'océan")
	_check(boat_distance >= 7.0 and boat_distance <= 14.0, "le bateau reste entièrement visible sans vue excessivement lointaine")

	world.queue_free()
	await process_frame
	if failures == 0:
		print("CAMERA REGRESSION TEST RÉUSSI")
	else:
		push_error("%d régression(s) caméra détectée(s)" % failures)
	quit(failures)
