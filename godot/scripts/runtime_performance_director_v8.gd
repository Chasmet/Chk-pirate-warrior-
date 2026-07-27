class_name RuntimePerformanceDirectorV8
extends Node

# Optimisation non destructive : toutes les îles et tous les assets restent
# chargés, mais seuls les secteurs utiles au joueur continuent à dessiner,
# traiter leur IA et participer aux collisions.
const SAMPLE_INTERVAL := 0.45
const NEARBY_ZONE_MARGIN := 210.0
const RECOVERY_DELAY := 3.2

var world: GameWorldV6
var player: PlayerController
var visuals: WorldVisualsV5
var zone_roots: Dictionary = {}
var average_delta := 1.0 / 60.0
var sample_timer := 0.0
var recovery_timer := 0.0
var quality_level := 0
var last_focus_key := ""
var last_quality_level := -1

func configure(target_world: GameWorldV6, target_player: PlayerController, target_visuals: WorldVisualsV5) -> void:
	world = target_world
	player = target_player
	visuals = target_visuals
	_index_zone_roots()
	refresh_focus(true)
	_apply_quality(true)
	set_process(true)
	set_meta("runtime_performance_v8", true)
	print("CHK_RUNTIME_PERFORMANCE_V8_READY zone_culling=1 adaptive_quality=1")

func _process(delta: float) -> void:
	average_delta = lerpf(average_delta, clampf(delta, 0.001, 0.080), 1.0 - exp(-1.7 * delta))
	sample_timer -= delta
	if sample_timer > 0.0:
		return
	sample_timer = SAMPLE_INTERVAL
	_update_quality_state()
	refresh_focus(false)
	_apply_quality(false)

func refresh_focus(force: bool = false) -> void:
	if not is_instance_valid(world) or not is_instance_valid(player):
		return
	if zone_roots.is_empty():
		_index_zone_roots()
	var relevant: Dictionary = {}
	relevant[clampi(world.current_zone, 0, world.zones_v5.size() - 1)] = true
	relevant[clampi(world.destination_zone, 0, world.zones_v5.size() - 1)] = true
	for zone_index in range(world.zones_v5.size()):
		var zone := world.zones_v5[zone_index] as Dictionary
		var center := Vector3(zone.get("center", Vector3.ZERO))
		var radius := float(zone.get("radius", 100.0))
		var flat_distance := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
		if flat_distance <= radius + NEARBY_ZONE_MARGIN:
			relevant[zone_index] = true
	var indices: Array = relevant.keys()
	indices.sort()
	var focus_key := "%s|boat=%s" % [str(indices), str(player.boat_mode)]
	if not force and focus_key == last_focus_key:
		return
	last_focus_key = focus_key
	for zone_index_value in zone_roots.keys():
		var zone_index := int(zone_index_value)
		var root := zone_roots[zone_index] as Node3D
		if not is_instance_valid(root):
			continue
		var enabled := relevant.has(zone_index)
		root.visible = enabled
		root.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		root.set_meta("runtime_focus_v8", enabled)
		_set_collision_objects_enabled(root, enabled)
	world.set_meta("active_zone_roots_v8", indices)

func run_update_for_test() -> void:
	_update_quality_state()
	refresh_focus(true)
	_apply_quality(true)

func active_zone_root_count() -> int:
	var count := 0
	for root_value in zone_roots.values():
		var root := root_value as Node3D
		if is_instance_valid(root) and root.visible:
			count += 1
	return count

func quality_name() -> String:
	return "économie" if quality_level == 2 else "équilibrée" if quality_level == 1 else "haute"

func _index_zone_roots() -> void:
	zone_roots.clear()
	if not is_instance_valid(visuals):
		return
	for child in visuals.get_children():
		if child is Node3D and child.has_meta("zone_index"):
			zone_roots[int(child.get_meta("zone_index"))] = child

func _set_collision_objects_enabled(root: Node, enabled: bool) -> void:
	for node in root.find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		if not body.has_meta("v8_original_collision_layer"):
			body.set_meta("v8_original_collision_layer", body.collision_layer)
			body.set_meta("v8_original_collision_mask", body.collision_mask)
		var target_layer := int(body.get_meta("v8_original_collision_layer", 1)) if enabled else 0
		var target_mask := int(body.get_meta("v8_original_collision_mask", 1)) if enabled else 0
		body.set_deferred("collision_layer", target_layer)
		body.set_deferred("collision_mask", target_mask)

func _update_quality_state() -> void:
	var requested := 2 if average_delta > 0.038 else 1 if average_delta > 0.026 else 0
	if requested > quality_level:
		quality_level = requested
		recovery_timer = 0.0
	elif requested < quality_level:
		recovery_timer += SAMPLE_INTERVAL
		if recovery_timer >= RECOVERY_DELAY:
			quality_level -= 1
			recovery_timer = 0.0
	else:
		recovery_timer = 0.0

func _apply_quality(force: bool) -> void:
	if not force and quality_level == last_quality_level:
		# La météo peut changer sans modifier le niveau de qualité ; le nombre de
		# particules est donc recalé à chaque échantillon, mais les nuages ne sont
		# reparcourus que lors d'un vrai changement de niveau.
		_apply_weather_particle_budget()
		return
	last_quality_level = quality_level
	_apply_cloud_budget()
	_apply_weather_particle_budget()
	if is_instance_valid(visuals) and is_instance_valid(visuals.sun):
		visuals.sun.directional_shadow_max_distance = 285.0 if quality_level == 0 else 205.0 if quality_level == 1 else 150.0
	if is_instance_valid(world):
		world.set_meta("adaptive_quality_v8", quality_level)
	print("CHK_ADAPTIVE_QUALITY_V8 mode=%s avg_ms=%.1f" % [quality_name(), average_delta * 1000.0])

func _apply_cloud_budget() -> void:
	if not is_instance_valid(visuals):
		return
	var cloud_root := visuals.get_node_or_null("NuagesDynamiquesV5") as Node3D
	if cloud_root == null:
		return
	var divisor := 1 if quality_level == 0 else 2 if quality_level == 1 else 3
	var index := 0
	for child in cloud_root.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).visible = index % divisor == 0
			index += 1

func _apply_weather_particle_budget() -> void:
	if not is_instance_valid(visuals) or not is_instance_valid(visuals.particles):
		return
	var weather := String(visuals.current_weather)
	var base_amount := 1700 if weather == "tempête" else 1300 if weather == "pluie" else 850 if weather == "neige" else 650 if weather == "cendres" else 1
	var scale := 1.0 if quality_level == 0 else 0.72 if quality_level == 1 else 0.48
	visuals.particles.amount = maxi(1, roundi(float(base_amount) * scale))
	if weather == "soleil":
		visuals.particles.emitting = false
