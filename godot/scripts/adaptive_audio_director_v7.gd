class_name AdaptiveAudioDirectorV7
extends Node

const AUDIO_ROOT := "res://assets/audio_v7/"
const MUSIC_PATHS := {
	"exploration": AUDIO_ROOT + "music_exploration.wav",
	"combat": AUDIO_ROOT + "music_combat.wav",
	"boss": AUDIO_ROOT + "music_boss.wav",
	"victory": AUDIO_ROOT + "music_victory.wav"
}
const AMBIENCE_PATHS := {
	"ocean": AUDIO_ROOT + "ambience_ocean.wav",
	"storm": AUDIO_ROOT + "ambience_storm.wav",
	"island_day": AUDIO_ROOT + "ambience_island_day.wav",
	"island_night": AUDIO_ROOT + "ambience_island_night.wav",
	"boat": AUDIO_ROOT + "ambience_boat.wav",
	"deep_ocean": AUDIO_ROOT + "ambience_deep_ocean.wav",
	"port": AUDIO_ROOT + "ambience_port.wav",
	"jungle": AUDIO_ROOT + "ambience_jungle.wav",
	"snow": AUDIO_ROOT + "ambience_snow.wav",
	"desert": AUDIO_ROOT + "ambience_desert.wav",
	"volcano": AUDIO_ROOT + "ambience_volcano.wav",
	"fortress": AUDIO_ROOT + "ambience_fortress.wav"
}
const ZONE_AMBIENCES := ["port", "jungle", "snow", "desert", "volcano", "fortress"]
const SFX_PATHS := {
	"attack": AUDIO_ROOT + "sfx_attack.wav",
	"skill": AUDIO_ROOT + "sfx_skill.wav",
	"dodge": AUDIO_ROOT + "sfx_dodge.wav",
	"hurt": AUDIO_ROOT + "sfx_hurt.wav",
	"dock": AUDIO_ROOT + "sfx_dock.wav",
	"thunder": AUDIO_ROOT + "sfx_thunder.wav"
}

var world: Node
var player: PlayerController
var music_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var active_music_index := 0
var current_music := ""
var current_ambience := ""
var target_music_volume := -10.0
var target_ambience_volume := -16.0
var state_probe_timer := 0.0
var thunder_timer := 12.0
var previous_health := -1.0
var previous_combo := 0
var previous_skill_cooldown := 0.0
var previous_dodge_time := 0.0
var previous_boat_mode := false
var previous_zone := -1
var cached_sfx: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1250
	rng.seed = 19820415
	_build_players()
	set_process(true)
	print("CHK_AUDIO_V7_READY adaptive=true island_ambiences=6 lazy_streaming=true")

func _build_players() -> void:
	for index in range(2):
		var music := AudioStreamPlayer.new()
		music.name = "MusiqueV7_%d" % index
		music.volume_db = -80.0
		music.finished.connect(func(): _restart_player_if_current(music))
		add_child(music)
		music_players.append(music)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbianceV7"
	ambience_player.volume_db = -80.0
	ambience_player.finished.connect(func(): _restart_player_if_current(ambience_player))
	add_child(ambience_player)
	for index in range(5):
		var sfx := AudioStreamPlayer.new()
		sfx.name = "EffetV7_%d" % index
		sfx.volume_db = -5.0
		add_child(sfx)
		sfx_players.append(sfx)

func _process(delta: float) -> void:
	_resolve_runtime_nodes()
	_update_fades(delta)
	state_probe_timer -= delta
	if state_probe_timer <= 0.0:
		state_probe_timer = 0.32
		_probe_state()
	if is_instance_valid(world) and is_instance_valid(player):
		_update_event_sfx()
		_update_thunder(delta)

func _resolve_runtime_nodes() -> void:
	if is_instance_valid(player) and is_instance_valid(world):
		return
	player = _find_player_recursive(get_tree().root)
	world = player.get_parent() if is_instance_valid(player) else null
	if is_instance_valid(player):
		previous_health = player.health
		previous_combo = player.combo_step
		previous_skill_cooldown = player.skill_cooldown
		previous_dodge_time = player.dodge_time
		previous_boat_mode = player.boat_mode

func _probe_state() -> void:
	if not is_instance_valid(player) or not is_instance_valid(world):
		return
	var zone_value: Variant = world.get("current_zone")
	var zone := clampi(int(zone_value) if zone_value != null else 0, 0, 8)
	var weather := _current_weather()
	var boss_active := _boss_near_player(95.0)
	var combat_active := boss_active or _enemy_near_player(22.0)
	var desired_music := "boss" if boss_active else "combat" if combat_active else "exploration"
	var desired_ambience := ""
	if player.boat_mode:
		desired_ambience = "deep_ocean" if absf(player.boat_speed) > PlayerController.BOAT_MAX_SPEED * 0.68 else "boat"
	elif weather == "tempête":
		desired_ambience = "storm"
	else:
		var daylight := _daylight_ratio()
		if daylight < 0.18:
			desired_ambience = "island_night"
		elif zone < ZONE_AMBIENCES.size():
			desired_ambience = String(ZONE_AMBIENCES[zone])
		else:
			desired_ambience = "island_day"
	if desired_music != current_music:
		_switch_music(desired_music)
	if desired_ambience != current_ambience:
		_switch_ambience(desired_ambience)
	if zone != previous_zone:
		previous_zone = zone
		play_sfx("dock", 0.70)

func _switch_music(key: String) -> void:
	var path := String(MUSIC_PATHS.get(key, ""))
	var stream := _load_stream(path)
	if stream == null:
		return
	var old_index := active_music_index
	active_music_index = 1 - active_music_index
	var next := music_players[active_music_index]
	next.stop()
	next.stream = stream
	next.volume_db = -80.0
	next.play()
	current_music = key
	var old := music_players[old_index]
	if old.playing:
		old.set_meta("fade_out_v7", true)
	next.set_meta("fade_out_v7", false)

func _switch_ambience(key: String) -> void:
	var path := String(AMBIENCE_PATHS.get(key, ""))
	var stream := _load_stream(path)
	if stream == null:
		return
	ambience_player.stop()
	ambience_player.stream = stream
	ambience_player.volume_db = -80.0
	ambience_player.play()
	current_ambience = key

func _update_fades(delta: float) -> void:
	for index in range(music_players.size()):
		var music := music_players[index]
		var target := target_music_volume if index == active_music_index else -80.0
		music.volume_db = move_toward(music.volume_db, target, delta * 22.0)
		if index != active_music_index and music.volume_db <= -72.0 and music.playing:
			music.stop()
			music.stream = null
	if is_instance_valid(ambience_player):
		ambience_player.volume_db = move_toward(ambience_player.volume_db, target_ambience_volume, delta * 16.0)

func _update_event_sfx() -> void:
	if player.combo_step != previous_combo and player.combo_step > 0:
		play_sfx("attack", 0.82 + float(player.combo_step) * 0.08)
	previous_combo = player.combo_step
	if player.skill_cooldown > previous_skill_cooldown + 0.75:
		play_sfx("skill", 1.0)
	previous_skill_cooldown = player.skill_cooldown
	if player.dodge_time > previous_dodge_time + 0.12:
		play_sfx("dodge", 0.88)
	previous_dodge_time = player.dodge_time
	if previous_health >= 0.0 and player.health < previous_health - 0.1:
		play_sfx("hurt", 0.92)
	previous_health = player.health
	if player.boat_mode != previous_boat_mode:
		play_sfx("dock", 0.95)
	previous_boat_mode = player.boat_mode

func _update_thunder(delta: float) -> void:
	if _current_weather() != "tempête":
		thunder_timer = minf(thunder_timer, 7.0)
		return
	thunder_timer -= delta
	if thunder_timer <= 0.0:
		play_sfx("thunder", 0.82)
		thunder_timer = rng.randf_range(9.0, 18.0)

func play_sfx(key: String, intensity: float = 1.0) -> void:
	var stream := cached_sfx.get(key) as AudioStream
	if stream == null:
		stream = _load_stream(String(SFX_PATHS.get(key, "")))
		if stream == null:
			return
		cached_sfx[key] = stream
	var target := _available_sfx_player()
	if target == null:
		return
	target.stream = stream
	target.pitch_scale = clampf(0.96 + rng.randf_range(-0.035, 0.035), 0.90, 1.08)
	target.volume_db = -7.0 + linear_to_db(clampf(intensity, 0.25, 1.4))
	target.play()

func _available_sfx_player() -> AudioStreamPlayer:
	for sfx in sfx_players:
		if not sfx.playing:
			return sfx
	return sfx_players[0] if not sfx_players.is_empty() else null

func _load_stream(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return loaded as AudioStream

func _restart_player_if_current(audio_player: AudioStreamPlayer) -> void:
	if is_instance_valid(audio_player) and audio_player.stream != null:
		audio_player.play()

func _current_weather() -> String:
	if not is_instance_valid(world):
		return "soleil"
	var visuals = world.get("visuals")
	if is_instance_valid(visuals):
		var value = visuals.get("current_weather")
		if value != null:
			return String(value)
	return "soleil"

func _daylight_ratio() -> float:
	if not is_instance_valid(world):
		return 1.0
	var visuals = world.get("visuals")
	if is_instance_valid(visuals):
		var value = visuals.get("day_time")
		if value != null:
			return clampf((sin(float(value) * TAU) + 0.12) / 1.12, 0.0, 1.0)
	return 1.0

func _enemy_near_player(radius: float) -> bool:
	var radius_squared := radius * radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyAI and is_instance_valid(node):
			var enemy := node as EnemyAI
			if enemy.health > 0.0 and enemy.global_position.distance_squared_to(player.global_position) <= radius_squared:
				return true
	return false

func _boss_near_player(radius: float) -> bool:
	var radius_squared := radius * radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if enemy.health <= 0.0:
			continue
		if enemy.is_in_group("roster_25d") and enemy.global_position.distance_squared_to(player.global_position) <= radius_squared:
			return true
	return false

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
