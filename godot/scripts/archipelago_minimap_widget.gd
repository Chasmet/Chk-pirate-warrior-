extends Control

const ZONE_POINTS := [
	Vector2(0.0, 0.0),
	Vector2(315.0, -175.0),
	Vector2(655.0, -72.0),
	Vector2(275.0, 260.0),
	Vector2(625.0, 295.0),
	Vector2(955.0, 105.0)
]
const ZONE_LABELS := ["PORT", "JUNGLE", "NEIGE", "DÉSERT", "VOLCAN", "FORT"]
const MAP_MIN := Vector2(-90.0, -310.0)
const MAP_MAX := Vector2(1040.0, 360.0)

var player: PlayerController
var world: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	set_process(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
		world = player.get_parent() if is_instance_valid(player) else null
	visible = is_instance_valid(player)
	if not visible:
		return
	var viewport_size := get_viewport_rect().size
	position = Vector2(viewport_size.x - 304.0, 96.0)
	size = Vector2(280.0, 176.0)
	queue_redraw()

func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, Color(0.008, 0.02, 0.04, 0.88), true)
	draw_rect(panel, Color("d6a63d"), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12.0, 22.0), "ARCHIPEL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("f5d985"))

	var current_zone := 0
	var destination := 1
	var unlocked: Array = [0]
	if is_instance_valid(world):
		var current_value = world.get("current_zone")
		var destination_value = world.get("destination_zone")
		var unlocked_value = world.get("unlocked_zones")
		if current_value != null:
			current_zone = clampi(int(current_value), 0, ZONE_POINTS.size() - 1)
		if destination_value != null:
			destination = clampi(int(destination_value), 0, ZONE_POINTS.size() - 1)
		if unlocked_value is Array:
			unlocked = unlocked_value

	for index in range(ZONE_POINTS.size() - 1):
		draw_line(_map_point(ZONE_POINTS[index]), _map_point(ZONE_POINTS[index + 1]), Color(0.45, 0.58, 0.66, 0.72), 2.0)

	for index in range(ZONE_POINTS.size()):
		var point := _map_point(ZONE_POINTS[index])
		var discovered := unlocked.has(index)
		var color := Color("5ed08a") if discovered else Color("606a72")
		if index == destination:
			color = Color("f0b93f")
		draw_circle(point, 8.0 if index == current_zone else 6.0, color)
		if index == destination:
			draw_arc(point, 11.0, 0.0, TAU, 24, Color("fff0a8"), 2.0)
		draw_string(font, point + Vector2(-18.0, 20.0), ZONE_LABELS[index], HORIZONTAL_ALIGNMENT_CENTER, 36.0, 10, Color("dbe8ee"))

	if is_instance_valid(player):
		var player_point := _map_point(Vector2(player.global_position.x, player.global_position.z))
		draw_circle(player_point, 4.5, Color.WHITE)
		draw_arc(player_point, 7.0, 0.0, TAU, 18, Color("2aa6e8"), 1.5)

func _map_point(world_point: Vector2) -> Vector2:
	var normalized := Vector2(
		inverse_lerp(MAP_MIN.x, MAP_MAX.x, world_point.x),
		inverse_lerp(MAP_MIN.y, MAP_MAX.y, world_point.y)
	)
	return Vector2(18.0 + normalized.x * (size.x - 36.0), 38.0 + normalized.y * (size.y - 58.0))

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
