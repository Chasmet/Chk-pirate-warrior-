class_name AmbientCitizenV9
extends CharacterBody3D

const WALK_SPEED := 2.15
const RUN_SPEED := 3.65
const ARRIVAL_DISTANCE := 0.85
const PLAYER_OBSERVE_DISTANCE := 5.5
const LABEL_DISTANCE := 20.0

var profile: Dictionary = {}
var route: Array[Vector3] = []
var route_index := 0
var current_state := "repos"
var current_hour := 8.0
var current_weather := "soleil"
var player: Node3D
var body_mesh: MeshInstance3D
var name_label: Label3D
var state_label: Label3D
var home_position := Vector3.ZERO
var work_position := Vector3.ZERO
var meal_position := Vector3.ZERO
var social_position := Vector3.ZERO
var target_position := Vector3.ZERO
var reaction_cooldown := 0.0
var base_color := Color("d7c6a5")

func configure(data: Dictionary, authored_route: Array[Vector3], player_reference: Node3D) -> void:
	profile = data.duplicate(true)
	route = authored_route.duplicate()
	player = player_reference
	name = "PNJ_%s" % String(profile.get("id", "inconnu"))
	add_to_group("npc_v9")
	_build_visual()
	_build_collision()
	_resolve_schedule_positions()
	global_position = home_position + Vector3.UP * 4.0
	floor_snap_length = 0.65
	floor_max_angle = deg_to_rad(48.0)
	floor_stop_on_slope = true
	floor_constant_speed = true
	safe_margin = 0.045
	set_physics_process(true)
	set_meta("npc_id", String(profile.get("id", "")))
	set_meta("npc_name", String(profile.get("name", "Habitant")))
	set_meta("npc_job", String(profile.get("job", "habitant")))
	set_meta("daily_routine_v9", true)

func _build_visual() -> void:
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Silhouette"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.72
	capsule.radial_segments = 10
	capsule.rings = 5
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.86
	var material := StandardMaterial3D.new()
	base_color = Color(String(profile.get("color", "d7c6a5"))).darkened(float(int(profile.get("region", 0)) % 3) * 0.055)
	material.albedo_color = base_color
	material.roughness = 0.88
	body_mesh.material_override = material
	body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body_mesh.visibility_range_end = 115.0
	body_mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(body_mesh)

	name_label = Label3D.new()
	name_label.name = "Nom"
	name_label.text = "%s • %s" % [String(profile.get("name", "Habitant")), String(profile.get("job", "habitant"))]
	name_label.position = Vector3(0.0, 2.12, 0.0)
	name_label.font_size = 34
	name_label.outline_size = 7
	name_label.modulate = Color("f6f1df")
	name_label.outline_modulate = Color(0.02, 0.03, 0.04, 0.92)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.visible = false
	add_child(name_label)

	state_label = Label3D.new()
	state_label.name = "ÉtatRoutine"
	state_label.position = Vector3(0.0, 1.84, 0.0)
	state_label.font_size = 24
	state_label.outline_size = 5
	state_label.modulate = Color("a8d6e8")
	state_label.outline_modulate = Color(0.02, 0.03, 0.04, 0.90)
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	state_label.no_depth_test = true
	state_label.visible = false
	add_child(state_label)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionPNJ"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.72
	collision.shape = shape
	collision.position.y = 0.86
	add_child(collision)

func _resolve_schedule_positions() -> void:
	if route.is_empty():
		route = [Vector3.ZERO, Vector3(3.0, 0.0, 3.0), Vector3(-3.0, 0.0, -3.0), Vector3(5.0, 0.0, -2.0)]
	var home_index := int(profile.get("home_poi", 0)) % route.size()
	var work_index := int(profile.get("work_poi", 1)) % route.size()
	var meal_index := int(profile.get("meal_poi", 2)) % route.size()
	var social_index := int(profile.get("social_poi", 3)) % route.size()
	home_position = route[home_index]
	work_position = route[work_index]
	meal_position = route[meal_index]
	social_position = route[social_index]
	target_position = home_position

func set_world_context(hour: float, weather: String) -> void:
	current_hour = fposmod(hour, 24.0)
	current_weather = weather
	_update_routine_state()

func react_to_danger(origin: Vector3) -> void:
	if reaction_cooldown > 0.0:
		return
	reaction_cooldown = 4.5
	current_state = "fuite"
	var away := global_position - origin
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.FORWARD
	target_position = global_position + away.normalized() * 14.0

func _update_routine_state() -> void:
	if current_state == "fuite" and reaction_cooldown > 0.0:
		return
	var schedule: Dictionary = profile.get("schedule", {})
	var wake := float(schedule.get("wake", 6.0))
	var work_start := float(schedule.get("work_start", 8.0))
	var meal := float(schedule.get("meal", 12.0))
	var work_end := float(schedule.get("work_end", 17.0))
	var sleep := float(schedule.get("sleep", 22.0))
	var next_state := "sommeil"
	var next_target := home_position
	if current_weather in ["tempête", "tempête de cendres", "blizzard", "orage"]:
		next_state = "abri"
		next_target = home_position
	elif current_hour >= wake and current_hour < work_start:
		next_state = "trajet"
		next_target = work_position
	elif current_hour >= work_start and current_hour < meal:
		next_state = "travail"
		next_target = work_position
	elif current_hour >= meal and current_hour < meal + 1.35:
		next_state = "repas"
		next_target = meal_position
	elif current_hour >= meal + 1.35 and current_hour < work_end:
		next_state = "travail"
		next_target = work_position
	elif current_hour >= work_end and current_hour < sleep:
		next_state = "discussion"
		next_target = social_position
	else:
		next_state = "sommeil"
		next_target = home_position
	if next_state != current_state or target_position.distance_squared_to(next_target) > 0.04:
		current_state = next_state
		target_position = next_target
		if is_instance_valid(state_label):
			state_label.text = current_state.to_upper()

func _physics_process(delta: float) -> void:
	reaction_cooldown = maxf(0.0, reaction_cooldown - delta)
	if not is_instance_valid(player):
		velocity = Vector3.ZERO
		return
	var player_distance := global_position.distance_to(player.global_position)
	if is_instance_valid(name_label):
		name_label.visible = player_distance <= LABEL_DISTANCE
	if is_instance_valid(state_label):
		state_label.visible = player_distance <= 11.0
	if player_distance <= PLAYER_OBSERVE_DISTANCE and current_state not in ["fuite", "sommeil", "abri"]:
		var look_target := player.global_position
		look_target.y = global_position.y
		if global_position.distance_squared_to(look_target) > 0.01:
			look_at(look_target, Vector3.UP, true)
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
	else:
		_move_toward_target(delta)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	if global_position.y < -15.0:
		global_position = home_position + Vector3.UP * 4.0
		velocity = Vector3.ZERO

func _move_toward_target(delta: float) -> void:
	var difference := target_position - global_position
	difference.y = 0.0
	if difference.length() <= ARRIVAL_DISTANCE:
		velocity.x = move_toward(velocity.x, 0.0, delta * 7.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 7.0)
		return
	var direction := difference.normalized()
	var speed := RUN_SPEED if current_state == "fuite" else WALK_SPEED
	if current_weather in ["pluie", "neige", "brouillard"]:
		speed *= 0.82
	if current_state in ["sommeil", "abri"]:
		speed *= 0.72
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 6.5)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 6.5)
	var facing := global_position + Vector3(direction.x, 0.0, direction.z)
	look_at(facing, Vector3.UP, true)
