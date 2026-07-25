extends Node

const COMMANDANT_COUNT := 3
const ANIMAL_COUNT := 4
const AI_WAKE_DISTANCE := 82.0
const AI_SLEEP_DISTANCE := 94.0
const ANIMAL_WAKE_DISTANCE := 58.0
const ANIMAL_SLEEP_DISTANCE := 70.0

var world: GameWorld
var player: PlayerController
var bound_world_id := 0
var population_token := 0
var lod_timer := 0.0

func _ready() -> void:
	process_priority = 1250
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(world):
		_bind_world(_find_world(get_tree().root))
		return
	if not is_instance_valid(player):
		player = world.get_player()
	_apply_pending_boss_visual()
	lod_timer -= delta
	if lod_timer <= 0.0:
		lod_timer = 0.24
		_update_ai_lod()

func _bind_world(candidate: GameWorld) -> void:
	if not is_instance_valid(candidate):
		return
	if bound_world_id == candidate.get_instance_id():
		return
	world = candidate
	player = world.get_player()
	bound_world_id = world.get_instance_id()
	world.zone_changed.connect(_on_zone_changed)
	population_token += 1
	var token := population_token
	call_deferred("_populate_after_delay", world.current_zone, token)
	print("CHK_ROSTER_25D_DIRECTOR_READY")

func _on_zone_changed(zone_index: int, _zone_name: String) -> void:
	population_token += 1
	var token := population_token
	call_deferred("_populate_after_delay", zone_index, token)

func _populate_after_delay(zone_index: int, token: int) -> void:
	await get_tree().create_timer(0.16).timeout
	if token != population_token or not is_instance_valid(world) or world.current_zone != zone_index:
		return
	if not is_instance_valid(player) or player.boat_mode:
		return
	if _zone_roster_exists(zone_index):
		return
	_spawn_commandant_pairs(zone_index)
	_spawn_animals(zone_index)
	print("CHK_ROSTER_25D_POPULATED zone=%d commandants=3 nakama=3 animals=4" % zone_index)

func _spawn_commandant_pairs(zone_index: int) -> void:
	var zone: Dictionary = GameWorld.ZONES[zone_index]
	var center: Vector3 = zone["center"]
	var radius := float(zone["radius"])
	for index in range(COMMANDANT_COUNT):
		var angle := 0.55 + TAU * float(index) / float(COMMANDANT_COUNT)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-direction.z, 0.0, direction.x)
		var pair_center := center + direction * radius * 0.42
		var commandant := _spawn_profile(Enemy25DCatalog.commandant_for_zone(zone_index, index), pair_center + tangent * 2.5)
		var nakama := _spawn_profile(Enemy25DCatalog.nakama_for_zone(zone_index, index), pair_center - tangent * 3.0)
		if is_instance_valid(commandant) and is_instance_valid(nakama):
			commandant.set_meta("nakama_instance_id", nakama.get_instance_id())
			nakama.set_meta("commandant_instance_id", commandant.get_instance_id())

func _spawn_animals(zone_index: int) -> void:
	var zone: Dictionary = GameWorld.ZONES[zone_index]
	var center: Vector3 = zone["center"]
	var radius := float(zone["radius"])
	for index in range(ANIMAL_COUNT):
		var angle := 1.12 + TAU * float(index) / float(ANIMAL_COUNT)
		var distance := radius * (0.27 if index % 2 == 0 else 0.54)
		var position := center + Vector3(cos(angle), 0.0, sin(angle)) * distance
		_spawn_profile(Enemy25DCatalog.animal_for_zone(zone_index, index), position)

func _spawn_profile(base_profile: Dictionary, world_position: Vector3) -> EnemyAI:
	if not is_instance_valid(world) or not is_instance_valid(player):
		return null
	var profile := base_profile.duplicate(true)
	profile["difficulty"] = world.difficulty
	profile["zone"] = world.current_zone
	var enemy := EnemyFactory.create_enemy(profile, player)
	enemy.add_to_group("roster_25d")
	enemy.set_meta("roster_zone", world.current_zone)
	enemy.set_meta("spawn_msec", Time.get_ticks_msec())
	world.add_child(enemy)
	Enemy25DVisual.apply(enemy, profile)
	var animator := QuinetEnemyAnimator.new()
	animator.name = "AnimationEnnemi"
	enemy.add_child(animator)
	animator.bind(enemy)
	enemy.global_position = world_position + Vector3.UP * 8.0
	player.register_enemy(enemy)
	return enemy

func _apply_pending_boss_visual() -> void:
	if not is_instance_valid(world):
		return
	for node in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var boss := node as EnemyAI
		if boss.has_meta("visual_pipeline"):
			continue
		var zone_index := clampi(int(boss.profile.get("zone", world.current_zone)), 0, GameWorld.ZONES.size() - 1)
		var profile := Enemy25DCatalog.boss_for_zone(zone_index)
		profile["difficulty"] = world.difficulty
		profile["zone"] = zone_index
		profile["id"] = String(boss.profile.get("id", profile["id"]))
		_upgrade_existing_boss(boss, profile)

func _upgrade_existing_boss(boss: EnemyAI, profile: Dictionary) -> void:
	var health_factor := 1.0
	var damage_factor := 1.0
	match String(profile.get("difficulty", "intermediaire")):
		"decouverte":
			health_factor = 0.82
			damage_factor = 0.78
		"difficile":
			health_factor = 1.30
			damage_factor = 1.40
	boss.profile = profile
	boss.name = String(profile["name"])
	boss.max_health = float(profile["health"]) * health_factor
	boss.health = boss.max_health
	boss.speed = float(profile["speed"])
	boss.damage = float(profile["damage"]) * damage_factor
	boss.attack_range = float(profile["range"])
	boss.xp_reward = int(profile["xp"])
	boss.coin_reward = int(profile["coins"])
	boss.boss = true
	var label := boss.get_node_or_null("NomEnnemi") as Label3D
	if label != null:
		label.text = String(profile["name"])
		label.position.y = 4.0
	Enemy25DVisual.apply(boss, profile)
	if is_instance_valid(world):
		world.call("_set_mission", "BOSS DE L’ÎLE : " + String(profile["name"]))
	print("CHK_BOSS_25D_READY zone=%d name=%s" % [int(profile["zone"]), String(profile["name"])])

func _update_ai_lod() -> void:
	if not is_instance_valid(player):
		return
	for node in get_tree().get_nodes_in_group("roster_25d"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if enemy.health <= 0.0 or enemy.boss:
			continue
		var age := float(Time.get_ticks_msec() - int(enemy.get_meta("spawn_msec", 0))) * 0.001
		if age < 1.8:
			enemy.set_physics_process(true)
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		var is_animal := String(enemy.profile.get("rank", "")) == "animal"
		var wake_distance := ANIMAL_WAKE_DISTANCE if is_animal else AI_WAKE_DISTANCE
		var sleep_distance := ANIMAL_SLEEP_DISTANCE if is_animal else AI_SLEEP_DISTANCE
		if enemy.is_physics_processing() and distance > sleep_distance:
			enemy.velocity = Vector3.ZERO
			enemy.set_physics_process(false)
		elif not enemy.is_physics_processing() and distance < wake_distance:
			enemy.set_physics_process(true)

func _zone_roster_exists(zone_index: int) -> bool:
	for node in get_tree().get_nodes_in_group("roster_25d"):
		if is_instance_valid(node) and int(node.get_meta("roster_zone", -1)) == zone_index:
			return true
	return false

func _find_world(node: Node) -> GameWorld:
	if node is GameWorld:
		return node as GameWorld
	for child in node.get_children():
		var result := _find_world(child)
		if is_instance_valid(result):
			return result
	return null
