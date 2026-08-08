extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC V8  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := SaveSystem.default_data()
	save["hero"] = "yvane"
	save["zone"] = 5
	save["destination_zone"] = 6
	save["unlocked_zones"] = [0, 1, 2, 3, 4, 5]
	var world := GameWorldV6.new()
	root.add_child(world)
	world.configure(save)
	await process_frame
	await physics_frame

	var player := world.get_player()
	_check(player is PlayerControllerV8, "le monde V8 utilise le contrôleur de jouabilité stabilisé")
	_check(bool(world.get_meta("stable_boat_gameplay_v8", false)), "la jouabilité bateau V8 est active")
	_check(world.performance_director is RuntimePerformanceDirectorV8, "le directeur de performance Android est présent")
	_check(bool(world.performance_director.get_meta("runtime_performance_v8", false)), "le budget adaptatif est initialisé")
	_check(world.performance_director.active_zone_root_count() <= 3, "seuls les secteurs utiles restent actifs")
	_check(world.visuals.get_node_or_null("Zone_5") != null and world.visuals.get_node("Zone_5").visible, "la Forteresse reste affichée")
	_check(world.visuals.get_node_or_null("Zone_6") != null and world.visuals.get_node("Zone_6").visible, "l’Île des Gâteaux reste visible comme destination")
	_check(world.visuals.get_node_or_null("Zone_0") != null and not world.visuals.get_node("Zone_0").visible, "une île éloignée est mise en sommeil sans être supprimée")

	var fort_dock := world.get_dock_position(5, true)
	var cake_dock := world.get_dock_position(6, true)
	player.enter_boat(fort_dock, cake_dock)
	player.set_move_input(Vector2(0.48, -1.0))
	for _frame in range(48):
		await physics_frame
	player.set_move_input(Vector2.ZERO)

	_check(player.boat_mode, "le bateau reste pilotable")
	_check(player.boat_speed > 1.5, "l’accélération tactile produit une vitesse stable")
	_check(player.global_position.is_finite() and player.velocity.is_finite(), "la navigation conserve des valeurs physiques valides")
	_check(absf(player.boat_steering_input_v8) <= 1.0 and absf(player.boat_throttle_input_v8) <= 1.0, "les commandes filtrées restent bornées")
	_check(is_instance_valid(player.hero_visual) and player.hero_visual.visible, "le héros choisi reste visible au gouvernail")
	_check(player.hero_visual.position.distance_to(PlayerControllerV8.BOAT_HELM_POSITION_V8) < 0.06, "le pilote ne subit plus deux positions concurrentes")
	var sprite := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	_check(sprite != null and sprite.visible, "le sprite du pilote est affiché")
	if sprite != null:
		_check(sprite.hframes == 3, "la planche de pilotage à trois poses est utilisée")
		_check(sprite.texture != null and sprite.texture.resource_path == String(HeroFactory.HEROES["yvane"]["steering_sprite"]), "le pilote correspond bien au héros Yvane choisi")
		_check(sprite.render_priority >= 10, "le pilote reste lisible depuis la caméra bateau")

	world.performance_director.run_update_for_test()
	await process_frame
	_check(world.performance_director.active_zone_root_count() <= 3, "le culling reste stable pendant la navigation")
	_check(String(world.performance_director.quality_name()) in ["haute", "équilibrée", "économie"], "le niveau de qualité adaptatif reste valide")

	var camera_guard := root.get_node_or_null("ThirdPersonCameraGuard")
	var boat_director := root.get_node_or_null("BoatPresentationDirector")
	_check(camera_guard != null and bool(camera_guard.get_meta("physics_camera_authority_v8", false)), "la caméra utilise une seule autorité au pas physique")
	_check(boat_director != null and bool(boat_director.get_meta("single_pilot_authority_v8", false)), "la présentation du bateau ne déplace plus le héros en concurrence")

	world.queue_free()
	await process_frame
	if failures == 0:
		print("CHK_V8_GAMEPLAY_STABILITY_READY")
		print("CHK_V8_SELECTED_HERO_AT_HELM_READY")
		print("CHK_V8_ANDROID_PERFORMANCE_READY")
	else:
		push_error("%d vérification(s) V8 ont échoué" % failures)
	quit(failures)
