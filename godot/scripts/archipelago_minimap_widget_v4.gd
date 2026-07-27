extends Control

const ZONE_POINTS := [
	Vector2(0.0, 0.0),
	Vector2(720.0, -420.0),
	Vector2(1580.0, -160.0),
	Vector2(700.0, 720.0),
	Vector2(1580.0, 820.0),
	Vector2(2460.0, 260.0),
	Vector2(3300.0, -560.0),
	Vector2(4140.0, 540.0),
	Vector2(5050.0, -220.0)
]
const ZONE_LABELS := ["PORT", "JUNGLE", "NEIGE", "DÉSERT", "VOLCAN", "FORT", "GÂTEAUX", "CRÂNE", "CIEL"]
const ZONE_COLORS := [
	Color("b99658"), Color("3e8a4d"), Color("c7e8f2"),
	Color("d6a15a"), Color("bb4d32"), Color("536b80"),
	Color("df8fb5"), Color("6f3028"), Color("86c8ec")
]
const ZONE_RADII := [10.0, 11.0, 10.0, 11.0, 10.0, 12.0, 11.0, 12.0, 12.0]
const MAP_MIN := Vector2(-350.0, -950.0)
const MAP_MAX := Vector2(5400.0, 1120.0)

var player: PlayerController
var world: Node
var pulse_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	set_process(true)

func _process(delta: float) -> void:
	pulse_time += delta
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
		world = player.get_parent() if is_instance_valid(player) else null
	visible = is_instance_valid(player)
	if not visible:
		return
	var viewport_size := get_viewport_rect().size
	position = Vector2(viewport_size.x - 380.0, 88.0)
	size = Vector2(356.0, 218.0)
	queue_redraw()

func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, Color(0.006, 0.018, 0.035, 0.92), true)
	draw_rect(Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 8.0)), Color(0.02, 0.09, 0.14, 0.72), true)
	draw_rect(panel, Color("d6a63d"), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12.0, 22.0), "GRAND ARCHIPEL • NAVIGATION RÉELLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("f5d985"))
	_draw_compass(font)

	var current_zone := 0
	var destination := 1
	var unlocked: Array = [0]
	if is_instance_valid(world):
		var current_value: Variant = world.get("current_zone")
		var destination_value: Variant = world.get("destination_zone")
		var unlocked_value: Variant = world.get("unlocked_zones")
		if current_value != null:
			current_zone = clampi(int(current_value), 0, ZONE_POINTS.size() - 1)
		if destination_value != null:
			destination = clampi(int(destination_value), 0, ZONE_POINTS.size() - 1)
		if unlocked_value is Array:
			unlocked = unlocked_value

	for index in range(ZONE_POINTS.size() - 1):
		_draw_dotted_route(_map_point(ZONE_POINTS[index]), _map_point(ZONE_POINTS[index + 1]), Color(0.48, 0.66, 0.74, 0.62))
	if current_zone != destination:
		_draw_dotted_route(_map_point(ZONE_POINTS[current_zone]), _map_point(ZONE_POINTS[destination]), Color(0.95, 0.68, 0.20, 0.86), 8.0, 4.0)

	for index in range(ZONE_POINTS.size()):
		var point := _map_point(ZONE_POINTS[index])
		var discovered := unlocked.has(index)
		var island_color: Color = ZONE_COLORS[index] if discovered else Color("45515a")
		_draw_island(point, ZONE_RADII[index], island_color, index == current_zone)
		if index == destination:
			var pulse := 2.0 + sin(pulse_time * 4.0) * 1.5
			draw_arc(point, ZONE_RADII[index] + 5.0 + pulse, 0.0, TAU, 32, Color("fff0a8"), 2.0)
			draw_circle(point, 3.2, Color("ffc64a"))
		var label_color := Color("f3f6f7") if discovered else Color("8e9aa1")
		draw_string(font, point + Vector2(-25.0, ZONE_RADII[index] + 12.0), ZONE_LABELS[index], HORIZONTAL_ALIGNMENT_CENTER, 50.0, 8, label_color)

	if is_instance_valid(player):
		_draw_player_marker(_map_point(Vector2(player.global_position.x, player.global_position.z)))

func _draw_island(point: Vector2, radius: float, color: Color, current: bool) -> void:
	draw_circle(point + Vector2(1.5, 2.5), radius + 1.5, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(point, radius, color.darkened(0.24))
	draw_circle(point + Vector2(-1.5, -1.0), radius * 0.78, color)
	draw_arc(point, radius, 0.0, TAU, 28, Color(color.lightened(0.24), 0.82), 1.2)
	if current:
		draw_arc(point, radius + 3.0, 0.0, TAU, 32, Color("65dfff"), 2.2)

func _draw_dotted_route(start: Vector2, finish: Vector2, color: Color, dash: float = 6.0, gap: float = 5.0) -> void:
	var delta := finish - start
	var length := delta.length()
	if length <= 0.1:
		return
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var segment_end := minf(cursor + dash, length)
		draw_line(start + direction * cursor, start + direction * segment_end, color, 1.5)
		cursor += dash + gap

func _draw_player_marker(point: Vector2) -> void:
	var yaw := player.rotation.y
	var forward := Vector2(-sin(yaw), -cos(yaw)).normalized()
	var right := Vector2(-forward.y, forward.x)
	var tip := point + forward * 9.0
	var left := point - forward * 5.0 - right * 5.0
	var right_point := point - forward * 5.0 + right * 5.0
	var triangle := PackedVector2Array([tip, left, right_point])
	draw_colored_polygon(triangle, Color("f8ffff"))
	draw_polyline(PackedVector2Array([tip, left, right_point, tip]), Color("2aa6e8"), 1.8)
	draw_arc(point, 10.5, 0.0, TAU, 24, Color(0.20, 0.75, 1.0, 0.48), 1.2)

func _draw_compass(font: Font) -> void:
	var center := Vector2(size.x - 22.0, 20.0)
	draw_circle(center, 11.0, Color(0.0, 0.0, 0.0, 0.55))
	draw_arc(center, 11.0, 0.0, TAU, 24, Color("d6a63d"), 1.2)
	draw_line(center + Vector2(0.0, 7.0), center + Vector2(0.0, -7.0), Color("dbe9ee"), 1.5)
	draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), Color("8aa6b4"), 1.0)
	draw_string(font, center + Vector2(-4.0, -10.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color("ffcf58"))

func _map_point(world_point: Vector2) -> Vector2:
	var normalized := Vector2(
		inverse_lerp(MAP_MIN.x, MAP_MAX.x, world_point.x),
		inverse_lerp(MAP_MIN.y, MAP_MAX.y, world_point.y)
	)
	return Vector2(18.0 + normalized.x * (size.x - 36.0), 40.0 + normalized.y * (size.y - 62.0))

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
