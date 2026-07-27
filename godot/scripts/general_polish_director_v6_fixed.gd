class_name GeneralPolishDirectorV6Fixed
extends GeneralPolishDirectorV6

func _build_fill_light() -> void:
	fill_light = DirectionalLight3D.new()
	fill_light.name = "LumièreRemplissageV6"
	fill_light.rotation_degrees = Vector3(-34.0, 142.0, 0.0)
	fill_light.light_color = Color("85bdf0")
	fill_light.light_energy = 0.30
	fill_light.shadow_enabled = false
	add_child(fill_light)
