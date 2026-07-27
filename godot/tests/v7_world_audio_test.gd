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
	var save := SaveSystem.default_data()
	var world := GameWorldV6.new()
	root.add_child(world)
	world.configure(save)
	await process_frame
	await physics_frame

	_check(world.zones_v5.size() == 9, "toutes les zones existantes sont conservées")
	var minimum_gap := INF
	for first in range(world.zones_v5.size()):
		for second in range(first + 1, world.zones_v5.size()):
			var a := Vector3(world.zones_v5[first]["center"])
			var b := Vector3(world.zones_v5[second]["center"])
			minimum_gap = minf(minimum_gap, Vector2(a.x - b.x, a.z - b.z).length())
	_check(minimum_gap >= 800.0, "les îles sont séparées d’au moins 800 mètres")
	_check(Vector3(world.zones_v5[8]["center"]).x >= 5000.0, "le grand archipel dépasse cinq kilomètres")
	_check(bool(world.get_meta("grand_archipelago_v7", false)), "grand archipel V7 actif")
	_check(world.visuals is WorldVisualsV5 and bool(world.visuals.get_meta("large_ocean_v7", false)), "océan agrandi actif")
	_check(world.lighting_director is AdaptiveLightingDirectorV7, "directeur d’éclairage adaptatif présent")
	_check(bool(world.lighting_director.get_meta("adaptive_lighting_v7", false)), "éclairage V7 initialisé")
	_check(world.lighting_director.lanterns.size() == 4, "pool de lumières mobiles limité")

	var audio_paths := [
		"res://assets/audio_v7/music_exploration.wav",
		"res://assets/audio_v7/music_combat.wav",
		"res://assets/audio_v7/music_boss.wav",
		"res://assets/audio_v7/ambience_ocean.wav",
		"res://assets/audio_v7/ambience_storm.wav",
		"res://assets/audio_v7/ambience_boat.wav",
		"res://assets/audio_v7/sfx_attack.wav",
		"res://assets/audio_v7/sfx_thunder.wav"
	]
	for path in audio_paths:
		_check(ResourceLoader.exists(path), "asset audio importé : " + path.get_file())
	var audio_director := root.get_node_or_null("AdaptiveAudioDirectorV7")
	_check(audio_director is AdaptiveAudioDirectorV7, "autoload audio adaptatif actif")
	if audio_director is AdaptiveAudioDirectorV7:
		(audio_director as AdaptiveAudioDirectorV7)._process(0.4)
		_check((audio_director as AdaptiveAudioDirectorV7).music_players.size() == 2, "fondu musical à deux lecteurs")
		_check((audio_director as AdaptiveAudioDirectorV7).sfx_players.size() == 5, "pool d’effets sonores réutilisable")

	world.queue_free()
	await process_frame
	if failures == 0:
		print("CHK_V7_GRAND_ARCHIPEL_AUDIO_READY")
	quit(failures)
