class_name AmbientShipV5
extends Node3D

var route: Array[Vector3] = []
var route_index := 0
var speed := 4.0
var waterline := 0.48
var vessel_scale := 1.0
var time_offset := 0.0
var primary := Color("6f4026")
var accent := Color("e7d6aa")
var ship_label := "Navire marchand"
var moving := true

func configure(points: Array[Vector3], label: String, main_color: Color, accent_color: Color, scale_value: float, speed_value: float, seed_value: int) -> void:
	route = points.duplicate()
	ship_label = label
	primary = main_color
	accent = accent_color
	vessel_scale = scale_value
	speed = speed_value
	time_offset = float(seed_value % 1000) * 0.017
	name = label.replace(" ", "_")
	set_meta("ship_name", label)
	set_meta("ambient_vessel", true)
	_build_ship()
	if not route.is_empty():
		global_position = route[0]
		route_index = 1 % route.size()

func _process(delta: float) -> void:
	if not moving or route.size() < 2:
		return
	var target := route[route_index]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 4.0:
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		offset = target - global_position
		offset.y = 0.0
	if offset.length_squared() > 0.01:
		var direction := offset.normalized()
		global_position += direction * speed * delta
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-2.6 * delta))
	var t := float(Time.get_ticks_msec()) * 0.001 + time_offset
	global_position.y = waterline + sin(t * 1.45) * 0.10 * vessel_scale
	var visual := get_node_or_null("VisuelNavire") as Node3D
	if visual != null:
		visual.rotation.z = sin(t * 1.1) * 0.025
		visual.rotation.x = sin(t * 0.82 + 1.7) * 0.018

func _build_ship() -> void:
	var root := Node3D.new()
	root.name = "VisuelNavire"
	root.scale = Vector3.ONE * vessel_scale
	add_child(root)

	_add_box(root, "Coque", Vector3(0, 0.45, 0), Vector3(3.2, 1.05, 8.0), primary)
	_add_box(root, "Pont", Vector3(0, 1.08, -0.15), Vector3(2.75, 0.22, 6.8), primary.lightened(0.16))
	_add_box(root, "Poupe", Vector3(0, 1.65, 2.55), Vector3(2.45, 1.35, 2.1), primary.darkened(0.12))
	_add_box(root, "Cabine", Vector3(0, 2.38, 2.65), Vector3(1.95, 1.15, 1.45), accent.darkened(0.30))
	_add_box(root, "Étrave", Vector3(0, 0.80, -4.35), Vector3(1.7, 0.75, 1.4), primary.darkened(0.05))

	for mast_z in [-1.1, 1.55]:
		_add_cylinder(root, "Mât", Vector3(0, 4.25, mast_z), 0.12, 6.8, Color("624126"))
		_add_box(root, "Vergue", Vector3(0, 5.15, mast_z), Vector3(4.15, 0.12, 0.12), Color("654329"))
		var sail := _add_box(root, "Voile", Vector3(0, 4.10, mast_z + 0.05), Vector3(3.7, 2.55, 0.08), accent)
		sail.rotation.z = 0.025 if mast_z < 0.0 else -0.025

	_add_cylinder(root, "Beaupré", Vector3(0, 1.95, -5.05), 0.09, 3.2, Color("624126"), Vector3(90, 0, 0))
	_add_box(root, "Pavillon", Vector3(0.70, 6.7, 1.55), Vector3(1.35, 0.72, 0.06), accent.darkened(0.18))
	for side in [-1.0, 1.0]:
		for z in [-2.1, 0.2, 2.2]:
			_add_cylinder(root, "Canon", Vector3(side * 1.65, 1.18, z), 0.13, 0.85, Color("282b30"), Vector3(0, 0, 90))

func _add_box(root: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = _material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(node)
	return node

func _add_cylinder(root: Node3D, node_name: String, position: Vector3, radius: float, height: float, color: Color, rotation_degrees_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.86
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	node.mesh = mesh
	node.position = position
	node.rotation_degrees = rotation_degrees_value
	node.material_override = _material(color)
	root.add_child(node)
	return node

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.76
	material.metallic = 0.05
	return material
