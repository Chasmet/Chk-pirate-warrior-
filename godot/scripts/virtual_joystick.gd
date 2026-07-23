class_name VirtualJoystick
extends Control

signal vector_changed(value: Vector2)

var touch_index := -1
var value := Vector2.ZERO
var radius := 92.0
var knob_radius := 38.0

func _ready() -> void:
	custom_minimum_size = Vector2(240, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index == -1:
			touch_index = touch.index
			_update_value(touch.position)
		elif not touch.pressed and touch.index == touch_index:
			touch_index = -1
			value = Vector2.ZERO
			vector_changed.emit(value)
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index:
			_update_value(drag.position)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				touch_index = 999
				_update_value(mouse.position)
			else:
				touch_index = -1
				value = Vector2.ZERO
				vector_changed.emit(value)
				queue_redraw()
	elif event is InputEventMouseMotion and touch_index == 999:
		_update_value((event as InputEventMouseMotion).position)

func _update_value(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	value = offset / radius
	vector_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius + 12.0, Color(0.01, 0.03, 0.06, 0.42))
	draw_circle(center, radius, Color(0.8, 0.9, 1.0, 0.16))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.92, 0.76, 0.3, 0.82), 4.0)
	draw_circle(center + value * radius, knob_radius, Color(0.04, 0.11, 0.18, 0.92))
	draw_arc(center + value * radius, knob_radius, 0.0, TAU, 40, Color(0.95, 0.82, 0.45, 0.95), 3.0)
