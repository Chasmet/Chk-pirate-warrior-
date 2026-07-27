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
	for crew_index in range(2):
		var profiles := Crew25DCatalogV5.members(crew_index)
		_check(profiles.size() == 10, "équipage %d : dix membres 2.5D" % (crew_index + 1))
		_check(_atlas_available(String(profiles[0]["atlas"])), "atlas haute qualité disponible")
		var powers: Dictionary = {}
		for profile in profiles:
			var power := String(profile.get("power", ""))
			_check(not power.is_empty(), "%s possède un pouvoir signature" % String(profile.get("name", "pirate")))
			powers[power] = true
		_check(powers.size() == profiles.size(), "dix pouvoirs distincts")
		var texture := Crew25DAssetFactoryV5.texture_for(profiles[0])
		_check(texture != null and texture.get_width() == Crew25DAssetFactoryV5.OUTPUT_SIZE * Crew25DAssetFactoryV5.FRAME_COUNT, "planche animée quatre poses")

	_check(String(Enemy25DCatalog.ISLANDS[6]["boss"]) == "Big Mom, Reine de Totto Land", "Big Mom boss île 7")
	_check(String(Enemy25DCatalog.ISLANDS[7]["boss"]) == "Kaido, Seigneur des Cent Bêtes", "Kaido boss île 8")
	_check(String(Enemy25DCatalog.ISLANDS[8]["boss"]) == "Imu Sama, Souverain du Trône Vide", "Imu Sama boss île 9")
	for zone_index in range(6, 9):
		Enemy25DAssetBank.activate_zone(zone_index)
		var profiles: Array[Dictionary] = [Enemy25DCatalog.boss_for_zone(zone_index)]
		profiles.append_array(Enemy25DCatalog.commandants_for_zone(zone_index))
		profiles.append_array(Enemy25DCatalog.nakama_for_all_commandants(zone_index))
		_check(profiles.size() == 7, "île %d : sept personnages importants" % (zone_index + 1))
		for profile in profiles:
			var asset := Enemy25DAssetBank.asset_for_profile(profile)
			var faction_texture := asset.get("texture") as Texture2D
			_check(String(asset.get("source", "")) == "hq_isolated_faction_asset", "%s utilise l’asset HQ" % String(profile.get("name", "personnage")))
			_check(faction_texture != null and faction_texture.get_width() == Enemy25DAssetBank.CHARACTER_OUTPUT_SIZE, "texture individuelle carrée")
		Enemy25DAssetBank.clear_active_zone()

	var defaults := SaveSystem.default_data()
	_check(int(defaults.get("save_version", 0)) == 5, "format sauvegarde V5 conservé")
	_check(defaults.has("exact_position") and defaults.has("crew_relations"), "position et relations persistées")

	var save := SaveSystem.default_data()
	save["zone"] = 0
	save["has_exact_position"] = true
	save["exact_position"] = [12.0, 8.0, -9.0]
	save["exact_rotation_y"] = 0.72
	var world := GameWorldV6.new()
	root.add_child(world)
	world.configure(save)
	await process_frame
	await physics_frame
	var player := world.get_player()
	var hero_animator := world.hero_animator as QuinetHeroAnimator
	_check(hero_animator != null, "contrôleur d’animation héros présent")
	var required_animation_states := PackedStringArray([
		"intro", "idle", "walk", "run", "jump", "attack", "power", "special",
		"dodge", "hurt", "knockback", "land", "defeat", "victory", "boat"
	])
	var supported_animation_states := hero_animator.supported_states() if hero_animator != null else PackedStringArray()
	for animation_state in required_animation_states:
		_check(supported_animation_states.has(animation_state), "animation héros disponible : " + animation_state)
	if hero_animator != null:
		hero_animator._process(0.016)
		_check(bool(player.hero_visual.get_meta("animation_pipeline_v6", false)), "machine d’animation V6 active dans le monde")
		player.attack()
		hero_animator._process(0.016)
		_check(hero_animator.current_state_name() == "attack", "attaque reliée à l’animation")
		player.dodge_cooldown = 0.0
		player.dodge_time = 0.0
		player.dodge()
		hero_animator._process(0.016)
		_check(hero_animator.current_state_name() == "dodge", "esquive reliée à l’animation")

	_check(bool(world.get_meta("v5_final_quality", false)), "base V5 conservée")
	_check(bool(world.get_meta("general_polish_v6", false)), "amélioration générale V6 active")
	_check(world.zones_v5.size() == 9, "neuf îles conservées")
	_check(player.is_in_group("player_actor") and bool(player.get_meta("physics_v6", false)), "physique joueur renforcée")
	_check(player.floor_snap_length >= 0.80 and player.max_slides >= 7, "collisions et pentes améliorées")
	_check(world.visuals is WorldVisualsV5, "météo et soleil V5 conservés")
	_check(world.polish_director != null and world.polish_director.fill_light != null, "éclairage de remplissage V6")
	_check(world.visuals.get_node_or_null("SoleilV5") != null, "soleil visuel présent")
	_check(world.visuals.get_node_or_null("NuagesDynamiquesV5") != null, "nuages dynamiques présents")
	_check(world.island_life != null and world.island_life.active_animated_count() >= 10, "île active enrichie avec animations")
	_check(world.ambient_fleet != null and world.ambient_fleet.ships.size() >= 12, "flotte ambiante conservée")
	_check(world.crew_director is CrewEncounterDirectorV6, "directeur d’équipages mobiles V6")
	_check(world.crew_director.members.size() == 12, "douze personnages itinérants actifs")
	_check(get_nodes_in_group("ambient_animals").size() >= 70, "faune 3D enrichie")
	var animal := get_nodes_in_group("ambient_animals")[0] if not get_nodes_in_group("ambient_animals").is_empty() else null
	_check(animal is QuinetAmbientAnimal and bool(animal.get_meta("animated_physics", false)), "faune avec physique et animation")

	var mobile_count := 0
	for member in world.crew_director.members:
		if is_instance_valid(member) and member is MobileCrewMemberV6:
			mobile_count += 1
	_check(mobile_count == 12, "tous les gentils et neutres utilisent la mobilité V6")
	var friendly := world.crew_director.members[0] as MobileCrewMemberV6
	friendly.set_attitude("allied")
	var start_position := friendly.global_position
	player.global_position += Vector3(9.0, 0.0, 0.0)
	for frame in range(32):
		await physics_frame
	_check(friendly.global_position.distance_to(start_position) > 0.12, "un personnage allié se déplace réellement dans la carte")
	_check(bool(friendly.get_meta("mobile_friendly_v6", false)), "mobilité alliée identifiée")

	world.queue_free()
	Crew25DAssetFactoryV5.clear_cache()
	Enemy25DAssetBank.clear_active_zone()
	await process_frame
	if failures == 0:
		print("CHK_V5_FINAL_QUALITY_READY")
		print("CHK_V6_GENERAL_POLISH_READY")
		print("CHK_HERO_ANIMATION_V6_READY")
	else:
		push_error("%d vérification(s) ont échoué" % failures)
	quit(failures)

func _atlas_available(path: String) -> bool:
	if FileAccess.file_exists(path):
		return true
	var asset_name := path.get_file().trim_suffix("_atlas.webp.b64")
	return FileAccess.file_exists("res://assets/faction25d/chunks/%s_0.b64" % asset_name)
