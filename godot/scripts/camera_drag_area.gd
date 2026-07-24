class_name CameraDragArea
extends Control

signal dragged(relative: Vector2)

var touch_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index == -1:
			touch_index = touch.index
		elif not touch.pressed and touch.index == touch_index:
			touch_index = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index:
			dragged.emit(drag.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dragged.emit((event as InputEventMouseMotion).relative)
