class_name IslandLifeDirectorV6
extends Node3D

var zone_roots: Array[Node3D] = []
var active_zone := 0
var local_time := 0.0
var animated_nodes: Array[Node3D] = []
var local_lights: Array[OmniLight3D] = []

func configure(zones: Array) -> void:
	for child in get_children():
		child.queue_free()
	zone_roots.clear()
	animated_nodes.clear()
	local_lights.clear()
	for zone_index in range(zones.size()):
		var zone: Dictionary = zones[zone_index]
		var root := Node3D.new()
		root.name = "VieÎleV6_%02d" % (zone_index + 1)
		root.position = Vector3(zone["center"])
		root.set_meta("zone_index", zone_index)
		add_child(root)
		zone_roots.append(root)
		_build_zone_life(root, zone_index, float(zone["radius"]))
	set_active_zone(0)
	set_meta("animated_island_life", true)
	print("CHK_V6_ISLAND_LIFE_READY zones=%d animated=%d" % [zone_roots.size(), animated_nodes.size()])

func set_active_zone(index: int) -> void:
	active_zone = clampi(index, 0, maxi(0, zone_roots.size() - 1))
	for zone_index in range(zone_roots.size()):
		zone_roots[zone_index].visible = abs(zone_index - active_zone) <= 1

func active_animated_count() -> int:
	var count := 0
	for node in animated_nodes:
		if is_instance_valid(node) and node.is_visible_in_tree():
			count += 1
	return count

func _process(delta: float) -> void:
	local_time += delta
	for node in animated_nodes:
		if not is_instance_valid(node) or not node.is_visible_in_tree():
			continue
		var kind := String(node.get_meta("life_animation", "float"))
		var phase := float(node.get_meta("phase", 0.0))
		var base_position := Vector3(node.get_meta("base_position", node.position))
		match kind:
			"flag":
				node.rotation.z = sin(local_time * 2.4 + phase) * 0.13
				node.rotation.y = sin(local_time * 0.72 + phase) * 0.10
			"rotate":
				node.rotation.y += delta * (0.55 + fmod(phase, 0.4))
			"sway":
				node.rotation.z = sin(local_time * 1.55 + phase) * 0.18
			"pulse":
				var pulse := 1.0 + sin(local_time * 3.2 + phase) * 0.14
				node.scale = Vector3.ONE * pulse
			"lift":
				node.position = base_position + Vector3.UP * (sin(local_time * 1.25 + phase) * 0.42)
			"chain":
				node.rotation.x = sin(local_time * 1.7 + phase) * 0.22
			"windmill":
				node.rotation.z += delta * 1.65
	for light in local_lights:
		if is_instance_valid(light) and light.is_visible_in_tree():
			var phase := float(light.get_meta("phase", 0.0))
			light.light_energy = 1.15 + sin(local_time * 5.0 + phase) * 0.28

func _build_zone_life(root: Node3D, zone_index: int, radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61000 + zone_index * 1193
	for index in range(12):
		var angle := TAU * float(index) / 12.0 + rng.randf_range(-0.20, 0.20)
		var distance := rng.randf_range(radius * 0.22, radius * 0.67)
		var position := Vector3(cos(angle) * distance, 3.0 + rng.randf_range(0.0, 2.8), sin(angle) * distance)
		match zone_index:
			0:
				_add_flag(root, position, Color("d84632") if index % 2 == 0 else Color("e7bb59"), index)
			1:
				_add_swaying_vine(root, position, Color("3d9a4d"), index)
			2:
				_add_crystal(root, position, Color("87d9ff"), index)
			3:
				_add_windmill(root, position, Color("d8b16a"), index)
			4:
				_add_vent(root, position, Color("ff5a26"), index)
			5:
				_add_chain(root, position, Color("718493"), index)
			6:
				_add_lantern(root, position, Color("ff8fc5"), index)
			7:
				_add_ember(root, position, Color("ff4a1f"), index)
			8:
				_add_halo(root, position + Vector3.UP * 2.5, Color("a6e2ff"), index)

func _add_flag(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	_add_cylinder(root, position + Vector3.UP * 1.5, 0.07, 3.0, Color("4d3b2d"))
	var flag := _add_box(root, position + Vector3(0.65, 2.55, 0), Vector3(1.3, 0.62, 0.05), color, true)
	_register(flag, "flag", index)

func _add_swaying_vine(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	var vine := _add_cylinder(root, position, 0.11, 3.8, color)
	_register(vine, "sway", index)
	_add_sphere(vine, Vector3(0, 1.55, 0), 0.34, color.lightened(0.18), false)

func _add_crystal(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	var crystal := _add_cone(root, position, 0.55, 2.6, color, true)
	_register(crystal, "pulse", index)
	_add_light(root, position + Vector3.UP * 1.0, color, index, 6.5)

func _add_windmill(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	_add_cylinder(root, position, 0.18, 3.1, Color("7d5a37"))
	var rotor := Node3D.new()
	rotor.position = position + Vector3(0, 2.9, 0.15)
	root.add_child(rotor)
	for side in range(4):
		var blade := _add_box(rotor, Vector3(0, 0.82, 0), Vector3(0.18, 1.65, 0.08), color, false)
		blade.rotation.z = float(side) * PI * 0.5
	_register(rotor, "windmill", index)

func _add_vent(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	_add_cylinder(root, position, 0.48, 0.55, Color("342b29"))
	var glow := _add_sphere(root, position + Vector3.UP * 0.6, 0.38, color, true)
	_register(glow, "lift", index)
	_add_light(root, position + Vector3.UP * 0.8, color, index, 7.5)

func _add_chain(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	var chain := Node3D.new()
	chain.position = position
	root.add_child(chain)
	for link in range(6):
		var torus := TorusMesh.new()
		torus.inner_radius = 0.12
		torus.outer_radius = 0.20
		var part := _mesh_node(torus, color, false)
		part.position.y = float(link) * 0.36
		part.rotation.x = PI * 0.5 if link % 2 == 0 else 0.0
		chain.add_child(part)
	_register(chain, "chain", index)

func _add_lantern(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	_add_cylinder(root, position, 0.08, 2.1, Color("68494e"))
	var lantern := _add_sphere(root, position + Vector3.UP * 1.35, 0.38, color, true)
	_register(lantern, "pulse", index)
	_add_light(root, position + Vector3.UP * 1.4, color, index, 8.0)

func _add_ember(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	var ember := _add_sphere(root, position, 0.28, color, true)
	_register(ember, "lift", index)
	_add_light(root, position, color, index, 5.5)

func _add_halo(root: Node3D, position: Vector3, color: Color, index: int) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.54
	torus.outer_radius = 0.68
	var halo := _mesh_node(torus, color, true)
	halo.position = position
	root.add_child(halo)
	_register(halo, "rotate", index)
	_add_light(root, position, color, index, 9.0)

func _register(node: Node3D, animation: String, index: int) -> void:
	node.set_meta("life_animation", animation)
	node.set_meta("phase", float(index) * 0.73)
	node.set_meta("base_position", node.position)
	animated_nodes.append(node)

func _add_light(root: Node3D, position: Vector3, color: Color, index: int, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = 1.15
	light.omni_range = range_value
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 42.0
	light.distance_fade_length = 24.0
	light.set_meta("phase", float(index) * 0.51)
	root.add_child(light)
	local_lights.append(light)

func _add_box(root: Node, position: Vector3, size: Vector3, color: Color, emissive: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh_node(mesh, color, emissive)
	node.position = position
	root.add_child(node)
	return node

func _add_sphere(root: Node, position: Vector3, radius: float, color: Color, emissive: bool) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 7
	var node := _mesh_node(mesh, color, emissive)
	node.position = position
	root.add_child(node)
	return node

func _add_cylinder(root: Node, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.86
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node := _mesh_node(mesh, color, false)
	node.position = position
	root.add_child(node)
	return node

func _add_cone(root: Node, position: Vector3, radius: float, height: float, color: Color, emissive: bool) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	var node := _mesh_node(mesh, color, emissive)
	node.position = position
	root.add_child(node)
	return node

func _mesh_node(mesh: PrimitiveMesh, color: Color, emissive: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.66
	material.metallic = 0.10
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.2
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	node.visibility_range_end = 165.0
	return node
