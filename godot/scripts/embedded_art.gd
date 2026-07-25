class_name EmbeddedArt
extends RefCounted

static var _interface: Texture2D

static func interface_texture() -> Texture2D:
	if _interface == null:
		_interface = _gradient_texture([
			Color("030a14"), Color("0b2538"), Color("16495d"), Color("071426")
		], 1280, 720)
	return _interface

static func _gradient_texture(colors: Array[Color], width: int, height: int) -> Texture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	texture.fill_from = Vector2(0.12, 0.0)
	texture.fill_to = Vector2(0.88, 1.0)
	return texture
