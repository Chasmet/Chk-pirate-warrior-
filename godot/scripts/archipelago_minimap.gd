extends CanvasLayer

const WIDGET_SCRIPT := preload("res://scripts/archipelago_minimap_widget.gd")

func _ready() -> void:
	layer = 24
	var widget := WIDGET_SCRIPT.new()
	widget.name = "MiniCarteArchipel"
	add_child(widget)
	print("CHK_MINIMAP_READY")
