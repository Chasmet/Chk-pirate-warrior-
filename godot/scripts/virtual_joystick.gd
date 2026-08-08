class_name QuinetJoystick
extends Control

signal vector_changed(value: Vector2)

var touch_index: int = -1
var value := Vector2.ZERO
var radius: float = 92.0
var knob_radius: float = 38.0
var deadzone: float = 0.10
var mouse_dragging := false
var active_center := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(240, 240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	active_center = size * 0.5
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index == -1:
			touch_index = touch.index
			var local_position := _screen_to_local(touch.position)
			active_center = Vector2(
				clampf(local_position.x, radius + 8.0, size.x - radius - 8.0),
				clampf(local_position.y, radius + 8.0, size.y - radius - 8.0)
			)
			_update_value(local_position)
			accept_event()
		elif not touch.pressed and touch.index == touch_index:
			_release_joystick()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index:
			_update_value(_screen_to_local(drag.position))
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = mouse.pressed
			if mouse.pressed:
				touch_index = 999
				active_center = mouse.position
				_update_value(mouse.position)
			else:
				_release_joystick()
			accept_event()
	elif event is InputEventMouseMotion and mouse_dragging and touch_index == 999:
		_update_value((event as InputEventMouseMotion).position)
		accept_event()

func _screen_to_local(screen_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_position

func _update_value(local_position: Vector2) -> void:
	var offset := local_position - active_center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	var raw_value := offset / maxf(radius, 1.0)
	if raw_value.length() <= deadzone:
		value = Vector2.ZERO
	else:
		var strength: float = inverse_lerp(deadzone, 1.0, minf(raw_value.length(), 1.0))
		value = raw_value.normalized() * strength
	vector_changed.emit(value)
	queue_redraw()

func _release_joystick() -> void:
	touch_index = -1
	mouse_dragging = false
	value = Vector2.ZERO
	active_center = size * 0.5
	vector_changed.emit(value)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release_joystick()

func _draw() -> void:
	var center := active_center if active_center != Vector2.ZERO else size * 0.5
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.018
	draw_circle(center, (radius + 14.0) * pulse, Color(0.005, 0.015, 0.03, 0.62))
	draw_circle(center, radius, Color(0.72, 0.86, 0.96, 0.19))
	draw_arc(center, radius, 0.0, TAU, 72, Color(0.92, 0.72, 0.22, 0.92), 5.0)
	var knob_position := center + value * radius
	draw_circle(knob_position, knob_radius + 5.0, Color(0.0, 0.0, 0.0, 0.34))
	draw_circle(knob_position, knob_radius, Color(0.025, 0.08, 0.14, 0.98))
	draw_arc(knob_position, knob_radius, 0.0, TAU, 48, Color(1.0, 0.84, 0.38, 1.0), 4.0)
