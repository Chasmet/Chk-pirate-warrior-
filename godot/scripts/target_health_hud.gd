extends CanvasLayer

var player: PlayerController
var panel: PanelContainer
var name_label: Label
var health_bar: ProgressBar
var distance_label: Label

func _ready() -> void:
	layer = 26
	_build_interface()
	set_process(true)

func _build_interface() -> void:
	panel = PanelContainer.new()
	panel.name = "CibleCombat2D"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.025, 0.04, 0.90)
	style.border_color = Color("d6a63d")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("f5d985"))
	header.add_child(name_label)
	distance_label = Label.new()
	distance_label.add_theme_font_size_override("font_size", 15)
	distance_label.add_theme_color_override("font_color", Color("c8d7df"))
	header.add_child(distance_label)

	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(390.0, 13.0)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.09, 0.10, 0.12, 0.96)
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d94b3d")
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	layout.add_child(health_bar)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
	if not is_instance_valid(player) or player.boat_mode:
		panel.visible = false
		return
	var target := _nearest_enemy(24.0)
	if not is_instance_valid(target):
		panel.visible = false
		return
	var viewport_size := get_viewport().get_visible_rect().size
	panel.size = Vector2(430.0, 62.0)
	panel.position = Vector2(viewport_size.x * 0.5 - panel.size.x * 0.5, 224.0)
	name_label.text = String(target.profile.get("name", "ENNEMI")).to_upper()
	distance_label.text = "%d m" % roundi(target.global_position.distance_to(player.global_position))
	health_bar.max_value = maxf(target.max_health, 1.0)
	health_bar.value = clampf(target.health, 0.0, target.max_health)
	panel.visible = true

func _nearest_enemy(maximum_distance: float) -> EnemyAI:
	var result: EnemyAI
	var nearest := maximum_distance
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if enemy.health <= 0.0:
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		if distance < nearest:
			nearest = distance
			result = enemy
	return result

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
