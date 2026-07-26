extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC  " + message)

func _find_collision(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node as CollisionShape3D
	for child in node.get_children():
		var found := _find_collision(child)
		if found != null:
			return found
	return null

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var target := Node3D.new()
	target.name = "CibleV3"
	root.add_child(target)

	# Les 42 profils importants disposent désormais d’un rendu 2.5D embarqué.
	for zone in range(Enemy25DCatalog.ISLANDS.size()):
		Enemy25DAssetBank.activate_zone(zone)
		var profiles: Array[Dictionary] = [Enemy25DCatalog.boss_for_zone(zone)]
		profiles.append_array(Enemy25DCatalog.commandants_for_zone(zone))
		profiles.append_array(Enemy25DCatalog.nakama_for_all_commandants(zone))
		_check(profiles.size() == 7, "île %d : 1 boss + 3 commandants + 3 nakamas" % zone)
		for profile in profiles:
			var asset := Enemy25DAssetBank.asset_for_profile(profile)
			var texture := asset.get("texture") as Texture2D
			_check(texture != null, "asset 2.5D disponible : " + String(profile["name"]))

	Enemy25DAssetBank.activate_zone(0)
	var port_profiles: Array[Dictionary] = [Enemy25DCatalog.boss_for_zone(0)]
	port_profiles.append_array(Enemy25DCatalog.commandants_for_zone(0))
	port_profiles.append_array(Enemy25DCatalog.nakama_for_all_commandants(0))
	for profile in port_profiles:
		profile["difficulty"] = "intermediaire"
		profile["zone"] = 0
		var enemy := EnemyFactory.create_enemy(profile, target)
		root.add_child(enemy)
		var collision_before := _find_collision(enemy)
		var health_before := enemy.max_health
		var damage_before := enemy.attack_damage
		var applied := Enemy25DVisual.apply(enemy, profile)
		var sprite := enemy.get_node_or_null("Visual25D/Character25D") as Sprite3D
		_check(applied, "rendu appliqué dans le monde 3D : " + String(profile["name"]))
		_check(collision_before != null and _find_collision(enemy) == collision_before, "collision conservée : " + String(profile["name"]))
		_check(is_equal_approx(enemy.max_health, health_before) and is_equal_approx(enemy.attack_damage, damage_before), "gameplay conservé : " + String(profile["name"]))
		_check(sprite != null and sprite.texture != null, "Sprite3D réel : " + String(profile["name"]))
		if sprite != null:
			_check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y and not sprite.no_depth_test, "caméra 360° et profondeur 3D : " + String(profile["name"]))
		enemy.queue_free()

	var animal_profile := Enemy25DCatalog.animal_for_zone(0, 0)
	animal_profile["difficulty"] = "intermediaire"
	animal_profile["zone"] = 0
	var animal := EnemyFactory.create_enemy(animal_profile, target)
	root.add_child(animal)
	_check(not Enemy25DVisual.apply(animal, animal_profile), "la faune reste en 3D")
	_check(animal.get_node_or_null("Visual25D") == null, "aucun visuel important appliqué à la faune")
	animal.queue_free()

	Enemy25DAssetBank.activate_zone(0)
	Enemy25DAssetBank.asset_for_profile(Enemy25DCatalog.commandant_for_zone(0, 0))
	_check(Enemy25DAssetBank.cached_texture_count() > 0, "cache du Port chargé")
	Enemy25DAssetBank.activate_zone(1)
	_check(Enemy25DAssetBank.cached_texture_count() == 0, "textures du Port libérées au changement d’île")
	Enemy25DAssetBank.asset_for_profile(Enemy25DCatalog.boss_for_zone(1))
	_check(Enemy25DAssetBank.active_zone() == 1 and Enemy25DAssetBank.cached_texture_count() > 0, "cache de la Jungle chargé seul")

	var save := SaveSystem.default_data()
	var player := PlayerController.new()
	root.add_child(player)
	player.configure(save)
	player.enter_boat(Vector3(0, PlayerController.BOAT_WATERLINE, 0), Vector3(0, PlayerController.BOAT_WATERLINE, -40))
	var pilot := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	_check(player.boat_mode and player.boat_visual.visible, "bateau pilotable visible en troisième personne")
	_check(pilot != null and pilot.visible and pilot.texture != null and "steering" in pilot.texture.resource_path, "héros 2.5D visible au gouvernail")
	player.queue_free()

	target.queue_free()
	Enemy25DAssetBank.clear_active_zone()
	await process_frame
	if failures == 0:
		print("V3 ROSTER 2.5D ET BATEAU RÉUSSI")
	else:
		push_error("%d vérification(s) V3 ont échoué" % failures)
	quit(failures)
