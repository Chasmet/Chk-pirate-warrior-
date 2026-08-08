extends CanvasLayer

const WIDGET_SCRIPT := preload("res://scripts/archipelago_minimap_widget_v4.gd")

func _ready() -> void:
	layer = 24
	var widget := WIDGET_SCRIPT.new()
	widget.name = "MiniCarteArchipelNeufÎles"
	add_child(widget)
	print("CHK_MINIMAP_V4_READY zones=9")
