class_name FinalKingdomLandmassV11
extends Node3D

const DOCK_DIRECTION := Vector3(-0.82, 0.0, -0.57)

func build() -> void:
	name = "TerrainRoyaumeTroubléV11"
	var data: Dictionary = RegionCatalogV11.FINAL_REGION
	global_position = Vector3(data["center"])
	_build_main_island(float(data["radius"]), Color(String(data["color"])), Color(String(data["accent"])))
	_build_terraces(Color(String(data["color"])), Color(String(data["accent"])))
	_build_dock(float(data["radius"]), Color(String(data["accent"])))
	_build_ruin_field(Color(String(data["color"])), Color(String(data["accent"])))
	set_meta("playable_final_landmass_v11", true)

func _build_main_island(radius: float, base_color: Color, accent: Color) -> void:
	var body := StaticBody3D.new()
	body.name = "PlateauPrincipal"
	body.position.y = -5.0
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius - 20.0
	mesh.bottom_radius = radius - 3.0
	mesh.height = 10.0
	mesh.radial_segments = 48
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color.darkened(0.10)
	material.roughness = 0.96
	material.metallic = 0.02
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.visibility_range_end = 920.0
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius - 20.0
	shape.height = 10.0
	collision.shape = shape
	body.add_child(collision)

	# Couronne rocheuse : elle casse la silhouette trop ronde du cylindre principal.
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		var rock_body := StaticBody3D.new()
		rock_body.name = "RocheRivage_%02d" % index
		var shore_radius := radius - 15.0 + sin(float(index) * 2.31) * 13.0
		rock_body.position = Vector3(cos(angle) * shore_radius, -1.6 + float(index % 3) * 0.6, sin(angle) * shore_radius)
		rock_body.rotation.y = angle
		add_child(rock_body)
		var rock := MeshInstance3D.new()
		var rock_mesh := BoxMesh.new()
		rock_mesh.size = Vector3(18.0 + float(index % 5) * 4.0, 7.0 + float(index % 4) * 2.2, 13.0 + float((index + 2) % 4) * 3.0)
		rock.mesh = rock_mesh
		rock.rotation = Vector3(0.12 * float(index % 3), 0.18 * float(index % 4), 0.08 * float(index % 2))
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = base_color.darkened(0.20 + float(index % 4) * 0.025).lerp(accent, 0.06)
		rock_material.roughness = 1.0
		rock.material_override = rock_material
		rock_body.add_child(rock)
		var rock_collision := CollisionShape3D.new()
		var rock_shape := BoxShape3D.new()
		rock_shape.size = rock_mesh.size * Vector3(0.86, 0.90, 0.86)
		rock_collision.shape = rock_shape
		rock_body.add_child(rock_collision)

func _build_terraces(base_color: Color, accent: Color) -> void:
	var terraces := [
		{"pos":Vector3(-118, 1.5, -96), "radius":74.0, "height":3.0},
		{"pos":Vector3(92, 2.4, -126), "radius":88.0, "height":4.8},
		{"pos":Vector3(-78, 1.2, 126), "radius":96.0, "height":2.4},
		{"pos":Vector3(112, 1.8, 116), "radius":72.0, "height":3.6},
		{"pos":Vector3(18, 2.8, 58), "radius":62.0, "height":5.6}
	]
	for index in range(terraces.size()):
		var data: Dictionary = terraces[index]
		var body := StaticBody3D.new()
		body.name = "TerrasseMémoire_%02d" % index
		body.position = Vector3(data["pos"])
		add_child(body)
		var mesh_instance := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = float(data["radius"])
		mesh.bottom_radius = float(data["radius"]) * 1.07
		mesh.height = float(data["height"])
		mesh.radial_segments = 32
		mesh_instance.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = base_color.lightened(0.04 + float(index) * 0.012).lerp(accent, 0.05)
		material.roughness = 0.94
		mesh_instance.material_override = material
		body.add_child(mesh_instance)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = float(data["radius"])
		shape.height = float(data["height"])
		collision.shape = shape
		body.add_child(collision)

func _build_dock(radius: float, accent: Color) -> void:
	var direction := DOCK_DIRECTION.normalized()
	var dock_center := direction * (radius - 2.0)
	var dock := StaticBody3D.new()
	dock.name = "PontDuRetourImpossible"
	dock.position = Vector3(dock_center.x, 1.1, dock_center.z)
	dock.rotation.y = atan2(direction.x, direction.z)
	add_child(dock)
	var bridge := MeshInstance3D.new()
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(7.5, 0.8, 92.0)
	bridge.mesh = bridge_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("5a4732").lerp(accent, 0.12)
	material.roughness = 0.88
	bridge.material_override = material
	bridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	dock.add_child(bridge)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bridge_mesh.size
	collision.shape = shape
	dock.add_child(collision)

	for side in [-1, 1]:
		for index in range(7):
			var post := MeshInstance3D.new()
			var post_mesh := CylinderMesh.new()
			post_mesh.top_radius = 0.23
			post_mesh.bottom_radius = 0.30
			post_mesh.height = 3.2
			post_mesh.radial_segments = 8
			post.mesh = post_mesh
			post.position = Vector3(float(side) * 3.1, -1.4, -38.0 + float(index) * 12.5)
			post.material_override = material
			dock.add_child(post)

func _build_ruin_field(base_color: Color, accent: Color) -> void:
	for index in range(34):
		var angle := float(index) * 2.399963
		var radius := 78.0 + float((index * 47) % 190)
		var ruin := StaticBody3D.new()
		ruin.name = "RuineSecondaire_%02d" % index
		ruin.position = Vector3(cos(angle) * radius, 1.8, sin(angle) * radius)
		ruin.rotation.y = angle * 0.63
		add_child(ruin)
		var column := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.3 + float(index % 3), 3.0 + float(index % 7) * 1.15, 2.1 + float((index + 1) % 3))
		column.mesh = mesh
		column.position.y = mesh.size.y * 0.5
		column.rotation.z = (-0.10 + float(index % 5) * 0.045)
		var material := StandardMaterial3D.new()
		material.albedo_color = base_color.lightened(float(index % 4) * 0.025).lerp(accent, 0.035)
		material.roughness = 0.98
		column.material_override = material
		column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		column.visibility_range_end = 300.0
		ruin.add_child(column)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size * Vector3(0.86, 0.95, 0.86)
		collision.shape = shape
		collision.position = column.position
		ruin.add_child(collision)
