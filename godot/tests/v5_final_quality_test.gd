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
	_check(Crew25DCatalogV5.CREWS.size() == 2, "deux équipages de référence enregistrés")
	_check(String(Crew25DCatalogV5.CREWS[0]["id"]) == "strawhat", "équipage du Chapeau de Paille enregistré")
	_check(String(Crew25DCatalogV5.CREWS[1]["id"]) == "redhair", "équipage du Roux enregistré")
	for crew_index in range(2):
		var profiles := Crew25DCatalogV5.members(crew_index)
		_check(profiles.size() == 10, "équipage %d : dix membres 2.5D" % (crew_index + 1))
		_check(FileAccess.file_exists(String(profiles[0]["atlas"])), "atlas découpé depuis la référence fourni")
		_check(float(profiles[0].get("height", 0.0)) > 0.8, "proportions physiques définies")
		var texture := Crew25DAssetFactoryV5.texture_for(profiles[0])
		_check(
			texture != null
			and texture.get_width() == 256 * Crew25DAssetFactoryV5.FRAME_COUNT
			and texture.get_height() == 256,
			"planche 2.5D quatre poses issue de la référence disponible"
		)

	var defaults := SaveSystem.default_data()
	_check(int(defaults.get("save_version", 0)) == 5, "format de sauvegarde V5")
	_check(defaults.has("exact_position") and defaults.has("crew_relations"), "position exacte et relations persistées")
	var relations := defaults["crew_relations"] as Dictionary
	_check(relations.has("strawhat") and relations.has("redhair"), "relations des équipages de référence sauvegardées")

	var ui := GameUIV5.new()
	root.add_child(ui)
	await process_frame
	_check(ui.get_node_or_null("BoutonSauvegardeExacteV5") != null or _find_named(ui, "BoutonSauvegardeExacteV5") != null, "bouton sauvegarde ajouté près de pause")
	ui.queue_free()

	var save := SaveSystem.default_data()
	save["zone"] = 0
	save["has_exact_position"] = true
	save["exact_position"] = [12.0, 8.0, -9.0]
	save["exact_rotation_y"] = 0.72
	save["exact_camera_yaw"] = 1.05
	var world := GameWorldV5.new()
	root.add_child(world)
	world.configure(save)
	var player := world.get_player()
	_check(bool(world.get_meta("v5_final_quality", false)), "monde V5 actif")
	_check(world.zones_v5.size() == 9, "neuf îles conservées")
	_check(float(world.zones_v5[0]["radius"]) > float(GameWorldV4.ZONES_V4[0]["radius"]), "îles réellement agrandies")
	_check(player.global_position.distance_to(Vector3(12.0, 8.0, -9.0)) < 0.2, "reprise à la position exacte")
	_check(is_equal_approx(player.rotation.y, 0.72), "orientation exacte restaurée")
	_check(world.visuals is WorldVisualsV5, "rendu météo et soleil V5 actif")
	_check(world.visuals.get_node_or_null("SoleilV5") != null, "soleil visuel V5 construit")
	_check(world.visuals.get_node_or_null("NuagesDynamiquesV5") != null, "nuages dynamiques construits")
	_check(world.ambient_fleet != null and world.ambient_fleet.ships.size() >= 12, "petits navires et deux grands bateaux en mer")
	_check(world.crew_director != null and world.crew_director.members.size() == 12, "deux équipages présents sur l’île active")
	_check(get_nodes_in_group("ambient_animals").size() >= 70, "faune et oiseaux 3D enrichis")
	var hero_style_members := 0
	for member in world.crew_director.members:
		if is_instance_valid(member) and String(member.get_meta("visual_pipeline", "")) == "hero_style_25d_in_3d":
			hero_style_members += 1
	_check(hero_style_members == 12, "les équipages utilisent le même pipeline 2.5D que les héros")
	var own_ships := 0
	for ship in world.ambient_fleet.ships:
		if is_instance_valid(ship) and String(ship.get_meta("crew_id", "")) in ["strawhat", "redhair"]:
			own_ships += 1
	_check(own_ships == 2, "chaque équipage de référence possède son propre bateau")

	world.queue_free()
	Crew25DAssetFactoryV5.clear_cache()
	await process_frame
	if failures == 0:
		print("CHK_V5_FINAL_QUALITY_READY")
	else:
		push_error("%d vérification(s) V5 ont échoué" % failures)
	quit(failures)

func _find_named(node: Node, target_name: String) -> Node:
	if String(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null
