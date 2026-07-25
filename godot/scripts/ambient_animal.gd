class_name QuinetAmbientAnimal
extends Node3D

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

func configure(kind: String, color: Color, spawn_position: Vector3, seed_value: int) -> void:
	species = kind
	position = spawn_position
	home = spawn_position
	base_y = spawn_position.y
	rng.seed = seed_value
	flying = species in ["mouette", "aigle"]
	roam_radius = 15.0 if flying else 7.0 if species == "singe" else 10.0
	speed = 4.2 if flying else 2.1 if species in ["sanglier", "cerf"] else 1.35
	add_to_group("ambient_animals")
	set_meta("species", species)
	_build_body(color)
	_choose_target()

func _process(delta: float) -> void:
	animation_time += delta
	var flat_target := target
	if not flying:
		flat_target.y = base_y
	var offset := flat_target - position
	if offset.length() < 0.8:
		_choose_target()
		offset = target - position
	if offset.length_squared() > 0.04:
		var direction := offset.normalized()
		position += direction * speed * delta
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-4.0 * delta))
	if flying:
		position.y = base_y + sin(animation_time * 1.7 + float(rng.seed % 17)) * 1.2
	elif body != null:
		body.position.y = body_rest_y + absf(sin(animation_time * speed * 3.0)) * 0.05
	for index in range(moving_parts.size()):
		var part := moving_parts[index]
		if not is_instance_valid(part):
			continue
		if flying:
			part.rotation.z = sin(animation_time * 8.0 + float(index) * PI) * 0.58
		else:
			part.rotation.x = sin(animation_time * speed * 3.2 + float(index) * PI) * 0.34

func _choose_target() -> void:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(roam_radius * 0.28, roam_radius)
	target = home + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	target.y = base_y + (rng.randf_range(-1.5, 1.5) if flying else 0.0)

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
	var beak := _cone("Bec", Vector3(0, 0.12, 1.08), 0.12, 0.42, Color("d99b35"))
	beak.rotation_degrees.x = 90.0
	add_child(beak)
	for side in [-1.0, 1.0]:
		var wing := _box("Aile", Vector3(side * 0.72, 0.02, 0), Vector3(1.15, 0.08, 0.42), color.darkened(0.12))
		wing.rotation.z = side * 0.18
		add_child(wing)
		moving_parts.append(wing)

func _build_penguin() -> void:
	body = _sphere("Corps", Vector3(0, 0.72, 0), Vector3(0.48, 0.82, 0.42), Color("1a2228"))
	add_child(body)
	var belly := _sphere("Ventre", Vector3(0, 0.72, 0.36), Vector3(0.30, 0.62, 0.10), Color("f1eee5"))
	add_child(belly)
	var head := _sphere("Tête", Vector3(0, 1.52, 0.04), Vector3.ONE * 0.36, Color("161c20"))
	add_child(head)
	var beak := _cone("Bec", Vector3(0, 1.46, 0.43), 0.10, 0.30, Color("df9a31"))
	beak.rotation_degrees.x = 90.0
	add_child(beak)

func _build_lizard(color: Color) -> void:
	body = _sphere("Corps", Vector3(0, 0.24, 0), Vector3(0.44, 0.24, 0.90), color)
	add_child(body)
	var head := _sphere("Tête", Vector3(0, 0.28, 0.84), Vector3(0.34, 0.24, 0.42), color.lightened(0.08))
	add_child(head)
	var tail := _cone("Queue", Vector3(0, 0.22, -1.05), 0.24, 1.40, color.darkened(0.12))
	tail.rotation_degrees.x = 90.0
	add_child(tail)
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
	_add_four_legs(color.darkened(0.10), 0.92)

func _build_mammal(color: Color, scale_value: float, monkey: bool) -> void:
	body = _sphere("Corps", Vector3(0, 0.68 * scale_value, 0), Vector3(0.62, 0.55, 1.02) * scale_value, color)
	add_child(body)
	var head_position := Vector3(0, 0.95 * scale_value, 0.88 * scale_value)
	var head := _sphere("Tête", head_position, Vector3.ONE * 0.43 * scale_value, color.lightened(0.06))
	add_child(head)
	_add_four_legs(color.darkened(0.12), 0.48 * scale_value)
	if monkey:
		var tail := _part_mesh("Queue", TorusMesh.new(), color.darkened(0.16))
		tail.mesh.inner_radius = 0.42
		tail.mesh.outer_radius = 0.52
		tail.position = Vector3(0, 0.82, -0.82)
		tail.rotation_degrees.x = 90.0
		add_child(tail)
	elif species == "cerf":
		for side in [-1.0, 1.0]:
			var antler := _cylinder("Bois", head_position + Vector3(side * 0.22, 0.50, 0), 0.04, 0.75, Color("6f5136"))
			antler.rotation_degrees.z = side * -22.0
			add_child(antler)

func _add_four_legs(color: Color, height: float) -> void:
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var leg := _cylinder("Patte", Vector3(x * 0.38, height * 0.48, z * 0.62), 0.09, height, color)
			add_child(leg)
			moving_parts.append(leg)

func _sphere(node_name: String, node_position: Vector3, node_scale: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
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
	mesh.radial_segments = 12
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	return node

func _cone(node_name: String, node_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var node := _part_mesh(node_name, mesh, color)
	node.position = node_position
	return node

func _part_mesh(node_name: String, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	node.material_override = material
	return node
