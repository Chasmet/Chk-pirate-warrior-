class_name QuinetAmbientAnimal
extends CharacterBody3D

var species := "oiseau"
var home := Vector3.ZERO
var roam_radius := 8.0
var speed := 1.4
var target := Vector3.ZERO
var base_y := 1.7
var flying := false
var animation_time := 0.0
var rng := RandomNumberGenerator.new()
var body: MeshInstance3D
var body_rest_y := 0.0
var moving_parts: Array[Node3D] = []
var leg_parts: Array[Node3D] = []
var wing_parts: Array[Node3D] = []
var tail_parts: Array[Node3D] = []
var behavior_state := "wander"
var state_timer := 0.0
var awareness_timer := 0.0
var cached_player: PlayerController
var cached_separation := Vector3.ZERO
var desired_velocity := Vector3.ZERO
var travel_phase := 0.0
var visibility_tick := 0
var animal_scale := 1.0

func configure(kind: String, color: Color, spawn_position: Vector3, seed_value: int) -> void:
	species = kind
	position = spawn_position
	home = spawn_position
	base_y = spawn_position.y
	rng.seed = seed_value
	flying = species in ["mouette", "aigle"]
	roam_radius = 19.0 if flying else 9.0 if species == "singe" else 13.0
	speed = 5.0 if flying else 2.65 if species in ["sanglier", "cerf", "chameau"] else 1.75
	animal_scale = 1.12 if species in ["cerf", "chameau", "sanglier"] else 0.88 if species in ["lézard", "pingouin"] else 1.0
	add_to_group("ambient_animals")
	set_meta("species", species)
	set_meta("behavior_v6", true)
	set_meta("animated_physics", true)
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.55
	floor_max_angle = deg_to_rad(52.0)
	floor_stop_on_slope = true
	safe_margin = 0.06
	_build_collision()
	_build_body(color)
	_choose_target()
	state_timer = rng.randf_range(1.4, 4.0)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	animation_time += delta
	travel_phase += delta * maxf(speed, 0.5)
	awareness_timer -= delta
	if awareness_timer <= 0.0:
		awareness_timer = 0.20 + rng.randf_range(0.0, 0.12)
		_refresh_awareness()
		cached_separation = _separation_force()

	if flying:
		_process_flying(delta)
	else:
		_process_ground(delta)
	_update_body_animation(delta)

func _process_ground(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_advance_ground_state()

	var flat_target := target
	flat_target.y = global_position.y
	var offset := flat_target - global_position
	offset.y = 0.0
	if behavior_state == "flee" and is_instance_valid(cached_player):
		var away := global_position - cached_player.global_position
		away.y = 0.0
		if away.length_squared() > 0.01:
			target = home + away.normalized() * roam_radius
			offset = target - global_position
			offset.y = 0.0
	if offset.length() < 0.85 and behavior_state in ["wander", "flee"]:
		_choose_target()
		offset = target - global_position
		offset.y = 0.0

	var movement_factor := 0.0 if behavior_state in ["idle", "graze", "observe"] else 1.35 if behavior_state == "flee" else 1.0
	var direction := offset.normalized() if offset.length_squared() > 0.03 else Vector3.ZERO
	var steering := direction + cached_separation * 0.80
	if steering.length_squared() > 1.0:
		steering = steering.normalized()
	desired_velocity = steering * speed * movement_factor
	velocity.x = move_toward(velocity.x, desired_velocity.x, delta * (12.0 if behavior_state == "flee" else 7.0))
	velocity.z = move_toward(velocity.z, desired_velocity.z, delta * (12.0 if behavior_state == "flee" else 7.0))
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = minf(velocity.y, -0.4)
	if steering.length_squared() > 0.02:
		rotation.y = lerp_angle(rotation.y, atan2(steering.x, steering.z), 1.0 - exp(-5.8 * delta))
	move_and_slide()
	if global_position.distance_to(home) > roam_radius * 1.65:
		target = home
		behavior_state = "wander"

func _process_flying(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0 or global_position.distance_to(target) < 1.4:
		_choose_target()
		state_timer = rng.randf_range(2.4, 5.8)
	var offset := target - global_position
	var direction := offset.normalized() if offset.length_squared() > 0.04 else -global_transform.basis.z
	var bank_speed := speed * (1.28 if behavior_state == "flee" else 1.0)
	var next_velocity := direction * bank_speed + cached_separation * 0.9
	velocity = velocity.lerp(next_velocity, 1.0 - exp(-2.6 * delta))
	global_position += velocity * delta
	var wave := sin(animation_time * 1.65 + float(rng.seed % 17)) * 0.52
	global_position.y = lerpf(global_position.y, base_y + wave + target.y - home.y, 1.0 - exp(-1.8 * delta))
	if direction.length_squared() > 0.02:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-4.2 * delta))
		rotation.z = lerpf(rotation.z, clampf(-direction.x * 0.28, -0.38, 0.38), 1.0 - exp(-3.0 * delta))
	if global_position.distance_to(home) > roam_radius * 2.0:
		target = home + Vector3.UP * 2.0

func _refresh_awareness() -> void:
	if not is_instance_valid(cached_player):
		cached_player = get_tree().get_first_node_in_group("player_actor") as PlayerController
	if not is_instance_valid(cached_player):
		return
	var distance := global_position.distance_to(cached_player.global_position)
	var flee_distance := 7.0 if species in ["lézard", "mouette", "pingouin"] else 9.5
	if distance < flee_distance and not cached_player.boat_mode:
		behavior_state = "flee"
		state_timer = 2.0
	elif behavior_state == "flee" and distance > flee_distance * 1.8:
		behavior_state = "wander"
		state_timer = rng.randf_range(2.0, 4.0)
		_choose_target()

func _advance_ground_state() -> void:
	var roll := rng.randf()
	if behavior_state == "flee":
		behavior_state = "wander"
	elif roll < 0.18:
		behavior_state = "idle"
	elif roll < 0.36:
		behavior_state = "graze"
	elif roll < 0.48:
		behavior_state = "observe"
	else:
		behavior_state = "wander"
		_choose_target()
	state_timer = rng.randf_range(1.2, 3.8) if behavior_state != "wander" else rng.randf_range(2.2, 5.2)

func _choose_target() -> void:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(roam_radius * 0.28, roam_radius)
	target = home + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	target.y = base_y + (rng.randf_range(-2.0, 2.0) if flying else 0.0)

func _separation_force() -> Vector3:
	var force := Vector3.ZERO
	var checked := 0
	for node in get_tree().get_nodes_in_group("ambient_animals"):
		if node == self or not is_instance_valid(node) or not node is QuinetAmbientAnimal:
			continue
		var other := node as QuinetAmbientAnimal
		if other.flying != flying:
			continue
		var offset := global_position - other.global_position
		var distance := offset.length()
		if distance > 0.001 and distance < 2.3 * animal_scale:
			force += offset.normalized() * (1.0 - distance / (2.3 * animal_scale))
		checked += 1
		if checked >= 12:
			break
	return force

func _update_body_animation(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var movement_ratio := clampf(horizontal_speed / maxf(speed, 0.1), 0.0, 1.45)
	if is_instance_valid(body):
		if flying:
			body.position.y = body_rest_y + sin(animation_time * 3.2) * 0.06
		else:
			body.position.y = body_rest_y + absf(sin(travel_phase * 2.8)) * 0.07 * movement_ratio
			body.rotation.x = lerpf(body.rotation.x, -0.08 if behavior_state == "graze" else 0.0, 1.0 - exp(-4.0 * delta))
	for index in range(leg_parts.size()):
		var leg := leg_parts[index]
		if is_instance_valid(leg):
			leg.rotation.x = sin(travel_phase * 3.2 + float(index % 2) * PI) * 0.46 * movement_ratio
	for index in range(wing_parts.size()):
		var wing := wing_parts[index]
		if is_instance_valid(wing):
			wing.rotation.z = sin(animation_time * 9.2 + float(index) * PI) * (0.72 if behavior_state == "flee" else 0.54)
	for tail in tail_parts:
		if is_instance_valid(tail):
			tail.rotation.y = sin(animation_time * 3.4) * 0.32

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionFauneV6"
	if flying:
		collision.disabled = true
	else:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.34 * animal_scale
		capsule.height = 1.10 * animal_scale
		collision.shape = capsule
		collision.position.y = 0.56 * animal_scale
	add_child(collision)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, not flying)

func _build_body(color: Color) -> void:
	match species:
		"mouette", "aigle":
			_build_bird(color)
		"pingouin":
			_build_penguin()
		"lézard":
			_build_lizard(color)
		"chameau":
			_build_camel(color)
		"singe":
			_build_mammal(color, 0.78, true)
		"cerf":
			_build_mammal(color, 1.12, false)
		_:
			_build_mammal(color, 0.92, false)
	if body != null:
		body_rest_y = body.position.y

func _build_bird(color: Color) -> void:
	body = _sphere("Corps", Vector3(0, 0, 0), Vector3(0.65, 0.38, 0.92), color)
	add_child(body)
	var head := _sphere("Tête", Vector3(0, 0.16, 0.72), Vector3.ONE * 0.34, color.lightened(0.08))
	add_child(head)
	_add_eyes(Vector3(0, 0.24, 0.96), 0.16)
	var beak := _cone("Bec", Vector3(0, 0.12, 1.08), 0.12, 0.42, Color("d99b35"))
	beak.rotation_degrees.x = 90.0
	add_child(beak)
	for side in [-1.0, 1.0]:
		var wing := _box("Aile", Vector3(side * 0.72, 0.02, 0), Vector3(1.15, 0.08, 0.42), color.darkened(0.12))
		wing.rotation.z = side * 0.18
		add_child(wing)
		moving_parts.append(wing)
		wing_parts.append(wing)

func _build_penguin() -> void:
	body = _sphere("Corps", Vector3(0, 0.72, 0), Vector3(0.48, 0.82, 0.42), Color("1a2228"))
	add_child(body)
	var belly := _sphere("Ventre", Vector3(0, 0.72, 0.36), Vector3(0.30, 0.62, 0.10), Color("f1eee5"))
	add_child(belly)
	var head := _sphere("Tête", Vector3(0, 1.52, 0.04), Vector3.ONE * 0.36, Color("161c20"))
	add_child(head)
	_add_eyes(Vector3(0, 1.60, 0.34), 0.15)
	var beak := _cone("Bec", Vector3(0, 1.46, 0.43), 0.10, 0.30, Color("df9a31"))
	beak.rotation_degrees.x = 90.0
	add_child(beak)

func _build_lizard(color: Color) -> void:
	body = _sphere("Corps", Vector3(0, 0.24, 0), Vector3(0.44, 0.24, 0.90), color)
	add_child(body)
	var head := _sphere("Tête", Vector3(0, 0.28, 0.84), Vector3(0.34, 0.24, 0.42), color.lightened(0.08))
	add_child(head)
	_add_eyes(Vector3(0, 0.37, 1.12), 0.17)
	var tail := _cone("Queue", Vector3(0, 0.22, -1.05), 0.24, 1.40, color.darkened(0.12))
	tail.rotation_degrees.x = 90.0
	add_child(tail)
	tail_parts.append(tail)
	_add_four_legs(color.darkened(0.18), 0.20)

func _build_camel(color: Color) -> void:
	body = _sphere("Corps", Vector3(0, 1.28, 0), Vector3(0.72, 0.64, 1.28), color)
	add_child(body)
	var hump := _sphere("Bosse", Vector3(0, 1.90, -0.15), Vector3(0.48, 0.58, 0.62), color.lightened(0.05))
	add_child(hump)
	var neck := _cylinder("Cou", Vector3(0, 2.02, 0.86), 0.22, 1.28, color)
	neck.rotation_degrees.x = -18.0
	add_child(neck)
	var head := _sphere("Tête", Vector3(0, 2.72, 1.04), Vector3(0.38, 0.28, 0.55), color)
	add_child(head)
	_add_eyes(Vector3(0, 2.80, 1.47), 0.20)
	_add_four_legs(color.darkened(0.10), 0.92)

func _build_mammal(color: Color, scale_value: float, monkey: bool) -> void:
	body = _sphere("Corps", Vector3(0, 0.68 * scale_value, 0), Vector3(0.62, 0.55, 1.02) * scale_value, color)
	add_child(body)
	var head_position := Vector3(0, 0.95 * scale_value, 0.88 * scale_value)
	var head := _sphere("Tête", head_position, Vector3.ONE * 0.43 * scale_value, color.lightened(0.06))
	add_child(head)
	_add_eyes(head_position + Vector3(0, 0.08, 0.36 * scale_value), 0.16 * scale_value)
	_add_four_legs(color.darkened(0.12), 0.48 * scale_value)
	if monkey:
		var tail := _part_mesh("Queue", TorusMesh.new(), color.darkened(0.16))
		(tail.mesh as TorusMesh).inner_radius = 0.42
		(tail.mesh as TorusMesh).outer_radius = 0.52
		tail.position = Vector3(0, 0.82, -0.82)
		tail.rotation_degrees.x = 90.0
		add_child(tail)
		tail_parts.append(tail)
	elif species == "cerf":
		for side in [-1.0, 1.0]:
			var antler := _cylinder("Bois", head_position + Vector3(side * 0.22, 0.50, 0), 0.04, 0.75, Color("6f5136"))
			antler.rotation_degrees.z = side * -22.0
			add_child(antler)

func _add_eyes(center: Vector3, spacing: float) -> void:
	for side in [-1.0, 1.0]:
		var eye := _sphere("Œil", center + Vector3(side * spacing, 0.0, 0.0), Vector3.ONE * 0.075, Color("111216"))
		add_child(eye)

func _add_four_legs(color: Color, height: float) -> void:
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var leg := _cylinder("Patte", Vector3(x * 0.38, height * 0.48, z * 0.62), 0.09, height, color)
			add_child(leg)
			moving_parts.append(leg)
			leg_parts.append(leg)

func _sphere(node_name: String, node_position: Vector3, node_scale: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 7
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	node.scale = node_scale
	return node

func _box(node_name: String, node_position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	return node

func _cylinder(node_name: String, node_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	return node

func _cone(node_name: String, node_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	return node

func _part_mesh(node_name: String, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.metallic = 0.04
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node
