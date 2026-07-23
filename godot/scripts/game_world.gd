class_name GameWorld
extends Node3D

signal zone_changed(zone_index: int, zone_name: String)
signal mission_changed(text: String)
signal weather_changed(label: String)
signal boss_defeated(boss_id: String)
signal player_ready(player: PlayerController)

const ZONES := [
	{"name":"Port des Naufragés","spawn":Vector3(0,2,0)},
	{"name":"Jungle sauvage","spawn":Vector3(170,2,0)},
	{"name":"Royaume des neiges","spawn":Vector3(340,2,0)},
	{"name":"Désert des corsaires","spawn":Vector3(510,2,0)},
	{"name":"Île volcanique","spawn":Vector3(680,2,0)},
	{"name":"Forteresse de la tempête","spawn":Vector3(850,2,0)}
]

var save_data: Dictionary = {}
var player: PlayerController
var hero_animator: QuinetHeroAnimator
var visuals: WorldVisuals
var current_zone := 0
var zone_kills := 0
var zone_boss_spawned := false
var defeated_bosses: Array = []
var rng := RandomNumberGenerator.new()

func configure(data: Dictionary) -> void:
	save_data = data
	current_zone = clampi(int(save_data.get("zone", 0)), 0, ZONES.size() - 1)
	defeated_bosses = save_data.get("bosses", [])
	rng.seed = 19820415
	visuals = WorldVisuals.new()
	add_child(visuals)
	visuals.build()
	visuals.weather_changed.connect(func(label: String): weather_changed.emit(label))
	_build_player()
	travel_to_zone(current_zone, false)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		visuals.update_world(delta, player.global_position)

func travel_to_zone(index: int, announce: bool = true) -> void:
	current_zone = clampi(index, 0, ZONES.size() - 1)
	zone_kills = 0
	zone_boss_spawned = false
	_clear_enemies()
	if is_instance_valid(player):
		player.global_position = ZONES[current_zone]["spawn"]
		player.velocity = Vector3.ZERO
	_spawn_wave()
	visuals.set_zone_weather(current_zone)
	zone_changed.emit(current_zone, String(ZONES[current_zone]["name"]))
	mission_changed.emit("Élimine 8 ennemis pour faire apparaître le capitaine.")
	if announce:
		VoiceFR.speak("Cap sur " + String(ZONES[current_zone]["name"]) + ".")

func get_player() -> PlayerController:
	return player

func get_zone_name() -> String:
	return String(ZONES[current_zone]["name"])

func _build_player() -> void:
	player = PlayerController.new()
	player.name = "ÉquipageQuinet"
	add_child(player)
	player.configure(save_data)
	hero_animator = QuinetHeroAnimator.new()
	hero_animator.name = "AnimationHéros"
	player.add_child(hero_animator)
	hero_animator.bind(player)
	player.enemy_defeated.connect(_on_enemy_defeated)
	player.player_defeated.connect(_on_player_defeated)
	player_ready.emit(player)

func _spawn_wave() -> void:
	if not is_instance_valid(player):
		return
	var center: Vector3 = ZONES[current_zone]["spawn"]
	for i in range(10):
		var profile := EnemyFactory.profile_for_index(current_zone * 2 + i)
		var enemy := EnemyFactory.create_enemy(profile, player)
		add_child(enemy)
		var angle := TAU * float(i) / 10.0 + rng.randf_range(-0.22, 0.22)
		var radius := rng.randf_range(14.0, 43.0)
		enemy.global_position = center + Vector3(cos(angle) * radius, 2.0, sin(angle) * radius)
		player.register_enemy(enemy)

func _spawn_boss() -> void:
	if zone_boss_spawned or not is_instance_valid(player):
		return
	zone_boss_spawned = true
	var boss_index := mini(current_zone, EnemyFactory.BOSSES.size() - 1)
	var profile := EnemyFactory.boss_for_zone(boss_index)
	var boss := EnemyFactory.create_enemy(profile, player)
	add_child(boss)
	boss.global_position = Vector3(ZONES[current_zone]["spawn"]) + Vector3(0, 2.0, -28.0)
	player.register_enemy(boss)
	mission_changed.emit("BOSS : " + String(profile["name"]))
	VoiceFR.speak("Attention. " + String(profile["name"]) + " entre dans l'arène.")

func _on_enemy_defeated(profile: Dictionary) -> void:
	if bool(profile.get("boss", false)):
		var boss_id := String(profile.get("id", "boss"))
		if not defeated_bosses.has(boss_id):
			defeated_bosses.append(boss_id)
			save_data["bosses"] = defeated_bosses
		mission_changed.emit("Région libérée. Explore ou choisis une autre île.")
		boss_defeated.emit(boss_id)
		VoiceFR.speak("Victoire. La région est libérée.")
		return
	zone_kills += 1
	mission_changed.emit("Ennemis vaincus : " + str(zone_kills) + " sur 8")
	if zone_kills >= 8:
		_spawn_boss()

func _on_player_defeated() -> void:
	mission_changed.emit("Équipage à terre. Retour au point de départ.")
	await get_tree().create_timer(2.0).timeout
	player.heal(9999.0)
	travel_to_zone(current_zone, false)

func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node):
			node.queue_free()
