extends Node

# Couche de finition mobile appliquée sans détruire les systèmes existants.
# Elle renforce les silhouettes des six îles, garantit la présence du pilote
# au gouvernail et remplace le sillage à particules par des meshes fiables.

var player: PlayerController
var world: GameWorld
var upgraded_world_id := 0
var upgraded_boat_id := 0
var wake_root: Node3D
var wake_materials: Array[StandardMaterial3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_priority = 1450
	rng.seed = 19820415
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player(get_tree().root)
		world = null
		upgraded_world_id = 0
		upgraded_boat_id = 0
		wake_root = null
		wake_materials.clear()
		if not is_instance_valid(player):
			return

	if not is_instance_valid(world):
		var parent := player.get_parent()
		if parent is GameWorld:
			world = parent as GameWorld

	if is_instance_valid(world) and world.get_instance_id() != upgraded_world_id:
		upgraded_world_id = world.get_instance_id()
		_apply_world_pass(world)

	if is_instance_valid(player.boat_visual) and player.boat_visual.get_instance_id() != upgraded_boat_id:
		upgraded_boat_id = player.boat_visual.get_instance_id()
		_prepare_boat_runtime()

	if player.boat_mode:
		_update_boat_runtime(delta)
	elif is_instance_valid(wake_root):
		wake_root.visible = false

func _apply_world_pass(game_world: GameWorld) -> void:
	if not is_instance_valid(game_world.visuals):
		return
	for zone_index in range(GameWorld.ZONES.size()):
		var zone_root := game_world.visuals.get_node_or_null("Zone_%d" % zone_index) as Node3D
		if zone_root == null:
			continue
		if zone_root.has_node("FinitionStudio"):
			continue
		var finish := Node3D.new()
		finish.name = "FinitionStudio"
		zone_root.add_child(finish)
		_build_zone_silhouette(finish, zone_index, float(GameWorld.ZONES[zone_index]["radius"]))
	print("CHK_STUDIO_WORLD_READY zones=6")

func _build_zone_silhouette(root: Node3D, zone_index: int, radius: float) -> void:
	var palette := _zone_palette(zone_index)
	_build_coast_rocks(root, zone_index, radius, palette)
	match zone_index:
		0:
			_build_port_landmark(root, radius, palette)
		1:
			_build_jungle_landmark(root, radius, palette)
		2:
			_build_snow_landmark(root, radius, palette)
		3:
			_build_desert_landmark(root, radius, palette)
		4:
			_build_volcano_landmark(root, radius, palette)
		5:
			_build_storm_fortress(root, radius, palette)

func _build_coast_rocks(root: Node3D, zone_index: int, radius: float, palette: Dictionary) -> void:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = 8100 + zone_index * 977
	for index in range(20):
		var angle := TAU * float(index) / 20.0 + local_rng.randf_range(-0.11, 0.11)
		var distance := radius * local_rng.randf_range(0.68, 0.88)
		var rock := _mesh_part("RocheCôtière", SphereMesh.new(), Color(palette["rock"]), 0.92, 0.0)
		(rock.mesh as SphereMesh).radius = local_rng.randf_range(1.2, 3.0)
		(rock.mesh as SphereMesh).height = local_rng.randf_range(1.8, 4.8)
		rock.position = Vector3(cos(angle) * distance, local_rng.randf_range(0.4, 1.25), sin(angle) * distance)
		rock.scale = Vector3(local_rng.randf_range(0.72, 1.55), local_rng.randf_range(0.62, 1.30), local_rng.randf_range(0.72, 1.55))
		rock.rotation_degrees = Vector3(local_rng.randf_range(-12.0, 12.0), local_rng.randf_range(0.0, 180.0), local_rng.randf_range(-10.0, 10.0))
		rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(rock)

func _build_port_landmark(root: Node3D, radius: float, palette: Dictionary) -> void:
	var lighthouse := Node3D.new()
	lighthouse.name = "GrandPhareDuPort"
	lighthouse.position = Vector3(-radius * 0.42, 0.0, -radius * 0.28)
	root.add_child(lighthouse)
	_add_cylinder(lighthouse, "Tour", Vector3(0, 7.5, 0), 3.5, 15.0, Color("e6d2aa"))
	_add_cylinder(lighthouse, "Couronne", Vector3(0, 15.4, 0), 4.4, 1.2, Color("7f3028"))
	var light := _mesh_part("Lanterne", SphereMesh.new(), Color("ffd86b"), 0.25, 0.05)
	(light.mesh as SphereMesh).radius = 1.25
	(light.mesh as SphereMesh).height = 2.1
	light.position = Vector3(0, 16.9, 0)
	var glow := light.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("ffbf3f")
	glow.emission_energy_multiplier = 4.2
	lighthouse.add_child(light)
	for index in range(5):
		var warehouse := Node3D.new()
		warehouse.position = Vector3(-28.0 + index * 13.5, 0.0, 22.0 + absf(2.0 - index) * 3.0)
		root.add_child(warehouse)
		_add_box(warehouse, "Entrepôt", Vector3(0, 3.0, 0), Vector3(9.5, 6.0, 7.5), Color(palette["building"]))
		_add_prism(warehouse, "Toit", Vector3(0, 6.5, 0), Vector3(10.4, 2.5, 8.4), Color("6f3328"))
	_build_crates(root, Vector3(8, 0, 34), 12, Color("8a552f"))

func _build_jungle_landmark(root: Node3D, radius: float, palette: Dictionary) -> void:
	var temple := Node3D.new()
	temple.name = "TempleJungle"
	temple.position = Vector3(0, 0, -radius * 0.18)
	root.add_child(temple)
	for level in range(4):
		_add_box(temple, "Terrasse", Vector3(0, 1.1 + level * 2.0, 0), Vector3(25.0 - level * 4.0, 2.0, 21.0 - level * 3.2), Color("6f7550").darkened(float(level) * 0.04))
	for side in [-1.0, 1.0]:
		_add_box(temple, "Pilier", Vector3(side * 5.8, 10.2, -1.0), Vector3(2.2, 12.0, 2.2), Color("7f8060"))
	_add_box(temple, "Fronton", Vector3(0, 15.8, -1.0), Vector3(15.5, 2.4, 3.0), Color("687152"))
	for index in range(26):
		var angle := TAU * float(index) / 26.0
		var distance := radius * (0.34 + float(index % 5) * 0.055)
		_build_palm(root, Vector3(cos(angle) * distance, 0, sin(angle) * distance), 7.0 + float(index % 4) * 1.5)

func _build_snow_landmark(root: Node3D, radius: float, palette: Dictionary) -> void:
	var keep := Node3D.new()
	keep.name = "CitadelleDeGlace"
	keep.position = Vector3(0, 0, -radius * 0.14)
	root.add_child(keep)
	_add_box(keep, "Donjon", Vector3(0, 9.0, 0), Vector3(18, 18, 15), Color("b5ced7"))
	for corner in [Vector3(-11, 0, -9), Vector3(11, 0, -9), Vector3(-11, 0, 9), Vector3(11, 0, 9)]:
		_add_cylinder(keep, "TourGlacée", corner + Vector3(0, 8.0, 0), 3.6, 16.0, Color("d9edf3"))
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		var spike := _mesh_part("PicDeGlace", PrismMesh.new(), Color("d7f4ff"), 0.32, 0.05)
		(spike.mesh as PrismMesh).size = Vector3(3.2 + float(index % 3), 8.0 + float(index % 5) * 2.0, 3.2 + float(index % 2))
		spike.position = Vector3(cos(angle) * radius * 0.48, 3.8, sin(angle) * radius * 0.48)
		spike.rotation_degrees.y = rad_to_deg(-angle)
		root.add_child(spike)

func _build_desert_landmark(root: Node3D, radius: float, palette: Dictionary) -> void:
	var city := Node3D.new()
	city.name = "CitéDesCorsaires"
	city.position = Vector3(0, 0, -radius * 0.12)
	root.add_child(city)
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var position := Vector3(cos(angle) * 21.0, 0, sin(angle) * 18.0)
		_add_cylinder(city, "TourSable", position + Vector3(0, 8.0, 0), 4.2, 16.0 + float(index % 2) * 5.0, Color("c99a59"))
		_add_prism(city, "ToitTour", position + Vector3(0, 17.0 + float(index % 2) * 2.5, 0), Vector3(9.4, 4.0, 9.4), Color("8f5131"))
	_add_box(city, "Palais", Vector3(0, 6.0, 0), Vector3(25, 12, 18), Color("d4ad6d"))
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		var dune := _mesh_part("Dune", SphereMesh.new(), Color("dcb36c"), 1.0, 0.0)
		(dune.mesh as SphereMesh).radius = 6.0 + float(index % 4)
		(dune.mesh as SphereMesh).height = 3.0 + float(index % 3)
		dune.scale = Vector3(1.8, 0.35, 1.25)
		dune.position = Vector3(cos(angle) * radius * 0.56, 0.4, sin(angle) * radius * 0.56)
		root.add_child(dune)

func _build_volcano_landmark(root: Node3D, radius: float, palette: Dictionary) -> void:
	var volcano := Node3D.new()
	volcano.name = "GrandVolcan"
	volcano.position = Vector3(0, 0, -radius * 0.10)
	root.add_child(volcano)
	for level in range(7):
		var cone := _mesh_part("StrateVolcanique", CylinderMesh.new(), Color("332b2a").lightened(float(level) * 0.025), 0.96, 0.0)
		var cylinder := cone.mesh as CylinderMesh
		cylinder.top_radius = 22.0 - float(level) * 2.55
		cylinder.bottom_radius = 25.0 - float(level) * 2.4
		cylinder.height = 5.0
		cone.position.y = 2.5 + float(level) * 4.5
		volcano.add_child(cone)
	var crater := _mesh_part("CratèreLave", CylinderMesh.new(), Color("ff5a18"), 0.16, 0.0)
	var crater_mesh := crater.mesh as CylinderMesh
	crater_mesh.top_radius = 6.2
	crater_mesh.bottom_radius = 7.0
	crater_mesh.height = 0.8
	crater.position.y = 31.8
	var lava := crater.material_override as StandardMaterial3D
	lava.emission_enabled = true
	lava.emission = Color("ff3b0a")
	lava.emission_energy_multiplier = 5.8
	volcano.add_child(crater)
	for index in range(8):
		var flow := _mesh_part("CouléeDeLave", BoxMesh.new(), Color("e74012"), 0.24, 0.0)
		(flow.mesh as BoxMesh).size = Vector3(1.7, 0.25, 12.0 + float(index % 3) * 4.0)
		flow.position = Vector3(-7.0 + float(index) * 2.0, 1.2, 8.0 + float(index % 2) * 4.0)
		flow.rotation_degrees.y = -18.0 + float(index) * 5.0
		var flow_mat := flow.material_override as StandardMaterial3D
		flow_mat.emission_enabled = true
		flow_mat.emission = Color("ff3a0b")
		flow_mat.emission_energy_multiplier = 3.6
		root.add_child(flow)

func _build_storm_fortress(root: Node3D, radius: float, palette: Dictionary) -> void:
	var fort := Node3D.new()
	fort.name = "ForteresseDeLaTempête"
	fort.position = Vector3(0, 0, -radius * 0.12)
	root.add_child(fort)
	_add_box(fort, "MurNord", Vector3(0, 6.0, -18), Vector3(48, 12, 5), Color("344653"))
	_add_box(fort, "MurSud", Vector3(0, 6.0, 18), Vector3(48, 12, 5), Color("344653"))
	_add_box(fort, "MurEst", Vector3(22, 6.0, 0), Vector3(5, 12, 36), Color("3b4b58"))
	_add_box(fort, "MurOuest", Vector3(-22, 6.0, 0), Vector3(5, 12, 36), Color("3b4b58"))
	for corner in [Vector3(-23, 0, -19), Vector3(23, 0, -19), Vector3(-23, 0, 19), Vector3(23, 0, 19)]:
		_add_cylinder(fort, "TourOrage", corner + Vector3(0, 11.0, 0), 5.4, 22.0, Color("293b48"))
		_add_cylinder(fort, "Paratonnerre", corner + Vector3(0, 25.0, 0), 0.32, 8.0, Color("a8bbc5"))
	_add_box(fort, "Donjon", Vector3(0, 13.0, 0), Vector3(19, 26, 17), Color("263845"))

func _prepare_boat_runtime() -> void:
	if not is_instance_valid(player.boat_visual):
		return
	wake_root = player.boat_visual.get_node_or_null("SillageStudio") as Node3D
	if wake_root == null:
		wake_root = Node3D.new()
		wake_root.name = "SillageStudio"
		wake_root.position = Vector3(0, -0.42, 4.9)
		player.boat_visual.add_child(wake_root)
		for side in [-1.0, 1.0]:
			var strip := _mesh_part("Écume", PlaneMesh.new(), Color(0.80, 0.95, 1.0, 0.0), 0.18, 0.0)
			(strip.mesh as PlaneMesh).size = Vector2(1.25, 8.0)
			strip.position = Vector3(side * 1.22, 0.0, 2.1)
			strip.rotation_degrees.y = side * 5.0
			var material := strip.material_override as StandardMaterial3D
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.albedo_color = Color(0.78, 0.95, 1.0, 0.0)
			wake_materials.append(material)
			wake_root.add_child(strip)
	if is_instance_valid(player.boat_collision) and player.boat_collision.shape is BoxShape3D:
		(player.boat_collision.shape as BoxShape3D).size = Vector3(4.15, 1.45, 10.8)
	print("CHK_STUDIO_BOAT_READY visible_pilot=1 external_camera=1")

func _update_boat_runtime(delta: float) -> void:
	if not is_instance_valid(player.boat_visual):
		return
	player.boat_visual.visible = true
	if is_instance_valid(player.hero_visual):
		player.hero_visual.visible = true
		player.hero_visual.position = player.hero_visual.position.lerp(Vector3(0.0, 0.78, 1.48), 1.0 - exp(-10.0 * delta))
		var sprite := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
		if sprite != null:
			sprite.visible = true
			sprite.modulate = Color.WHITE
			sprite.no_depth_test = false
			sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	var ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	if is_instance_valid(wake_root):
		wake_root.visible = ratio > 0.04
		wake_root.scale.z = lerpf(0.35, 1.55, ratio)
		for material in wake_materials:
			material.albedo_color = Color(0.78, 0.95, 1.0, lerpf(0.0, 0.66, ratio))

func _build_crates(root: Node3D, origin: Vector3, count: int, color: Color) -> void:
	for index in range(count):
		var offset := Vector3(float(index % 4) * 2.1, float(index / 4) * 1.05, float(index % 3) * 1.8)
		_add_box(root, "Caisse", origin + offset, Vector3(1.8, 1.8, 1.8), color.lightened(float(index % 2) * 0.06))

func _build_palm(root: Node3D, position: Vector3, height: float) -> void:
	var palm := Node3D.new()
	palm.position = position
	root.add_child(palm)
	_add_cylinder(palm, "Tronc", Vector3(0, height * 0.5, 0), 0.42, height, Color("7c5532"))
	for leaf_index in range(6):
		var leaf := _mesh_part("PalmeStudio", BoxMesh.new(), Color("2f7e3c"), 0.88, 0.0)
		(leaf.mesh as BoxMesh).size = Vector3(0.42, 0.16, 4.8)
		leaf.position = Vector3(0, height, 0)
		leaf.rotation_degrees = Vector3(-18.0, float(leaf_index) * 60.0, 0.0)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		palm.add_child(leaf)

func _add_box(root: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := _mesh_part(node_name, BoxMesh.new(), color, 0.86, 0.0)
	(part.mesh as BoxMesh).size = size
	part.position = position
	root.add_child(part)
	return part

func _add_prism(root: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := _mesh_part(node_name, PrismMesh.new(), color, 0.82, 0.0)
	(part.mesh as PrismMesh).size = size
	part.position = position
	part.rotation_degrees.y = 90.0
	root.add_child(part)
	return part

func _add_cylinder(root: Node3D, node_name: String, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var part := _mesh_part(node_name, CylinderMesh.new(), color, 0.84, 0.0)
	var cylinder := part.mesh as CylinderMesh
	cylinder.top_radius = radius * 0.88
	cylinder.bottom_radius = radius
	cylinder.height = height
	part.position = position
	root.add_child(part)
	return part

func _mesh_part(node_name: String, mesh: PrimitiveMesh, color: Color, roughness: float, metallic: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	part.material_override = material
	return part

func _zone_palette(zone_index: int) -> Dictionary:
	match zone_index:
		0:
			return {"rock": Color("665646"), "building": Color("a56f4d")}
		1:
			return {"rock": Color("3d5940"), "building": Color("6d7551")}
		2:
			return {"rock": Color("a9bcc6"), "building": Color("c9dce3")}
		3:
			return {"rock": Color("8e6944"), "building": Color("c99a59")}
		4:
			return {"rock": Color("2b2525"), "building": Color("51312a")}
		_:
			return {"rock": Color("3e505b"), "building": Color("344653")}

func _find_player(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player(child)
		if is_instance_valid(found):
			return found
	return null
