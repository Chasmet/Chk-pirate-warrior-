class_name QuinetToonStyler
extends RefCounted

static func style(root: Node, add_contours: bool, accent: Color = Color("f0c85a")) -> void:
	var meshes: Array[MeshInstance3D] = []
	_find_meshes(root, meshes)
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null or mesh.name == "ContourAnime":
			continue
		var original := mesh.material_override as StandardMaterial3D
		var color := Color("8f7968")
		var roughness := 0.68
		var metallic := 0.02
		if original != null:
			color = original.albedo_color
			roughness = original.roughness
			metallic = original.metallic
		var toon := ShaderMaterial.new()
		toon.shader = load("res://shaders/toon_character.gdshader")
		toon.set_shader_parameter("base_color", color)
		toon.set_shader_parameter("shadow_color", color.darkened(0.76))
		toon.set_shader_parameter("rim_color", accent)
		toon.set_shader_parameter("roughness_value", roughness)
		toon.set_shader_parameter("metallic_value", metallic)
		mesh.material_override = toon
		if add_contours:
			_add_contour(mesh, accent)

static func _find_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child as MeshInstance3D)
		_find_meshes(child, meshes)

static func _add_contour(mesh: MeshInstance3D, accent: Color) -> void:
	if mesh.get_node_or_null("ContourAnime") != null:
		return
	var contour := MeshInstance3D.new()
	contour.name = "ContourAnime"
	contour.mesh = mesh.mesh
	contour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/toon_outline.gdshader")
	material.set_shader_parameter("outline_color", Color("070a12").lerp(accent.darkened(0.86), 0.22))
	material.set_shader_parameter("outline_width", 0.026)
	contour.material_override = material
	mesh.add_child(contour)
