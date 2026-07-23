class_name GameUI
extends CanvasLayer

signal play_requested(new_game: bool)
signal hero_selected(hero_id: String)
signal zone_selected(zone_index: int)
signal training_requested(stat_name: String)
signal attack_requested
signal skill_requested
signal aura_requested
signal switch_requested
signal move_changed(value: Vector2)
signal camera_dragged(relative: Vector2)
signal pause_requested
signal resume_requested
signal quit_to_menu_requested
signal voice_toggled(active: bool)

const GOLD := Color("d6a63d")
const GOLD_LIGHT := Color("f5d985")
const RED := Color("a82e2c")
const BLUE := Color("256fa3")
const GREEN := Color("2f8b5d")

var menu: MenuUI
var hud: Control
var pause_screen: Control
var game_over_screen: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var aura_bar: ProgressBar
var hero_label: Label
var level_label: Label
var zone_label: Label
var mission_label: Label
var weather_label: Label
var coins_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu = MenuUI.new()
	add_child(menu)
	menu.build()
	menu.play_requested.connect(func(value: bool): play_requested.emit(value))
	menu.hero_selected.connect(func(value: String): hero_selected.emit(value))
	menu.zone_selected.connect(func(value: int): zone_selected.emit(value))
	menu.training_requested.connect(func(value: String): training_requested.emit(value))
	menu.voice_toggled.connect(func(value: bool): voice_toggled.emit(value))
	_build_hud()
	_build_pause()
	_build_game_over()
	show_main_menu()

func show_main_menu() -> void:
	hud.hide()
	pause_screen.hide()
	game_over_screen.hide()
	menu.show()
	menu.show_main()

func show_hud() -> void:
	menu.hide()
	pause_screen.hide()
	game_over_screen.hide()
	hud.show()

func show_map() -> void:
	hud.hide()
	menu.show()
	menu.show_map()

func show_pause() -> void:
	pause_screen.show()

func show_game_over() -> void:
	game_over_screen.show()

func set_voice_enabled(active: bool) -> void:
	menu.set_voice(active)

func update_stats(health: float, max_health: float, energy: float, aura: float, level: int, _xp: int, coins: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	energy_bar.value = energy
	aura_bar.value = aura
	level_label.text = "NIVEAU " + str(level)
	coins_label.text = str(coins) + " PIÈCES"
	menu.update_training(level, coins)

func update_hero(_hero_id: String, display_name: String) -> void:
	hero_label.text = display_name
func update_zone(name: String) -> void:
	zone_label.text = name.to_upper()
func update_mission(text: String) -> void:
	mission_label.text = text
func update_weather(label: String) -> void:
	weather_label.text = label.to_upper()

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(20, 18)
	top.size = Vector2(600, 180)
	top.add_theme_stylebox_override("panel", _style(Color(0.01,0.025,0.05,0.8), GOLD, 18, 2))
	hud.add_child(top)
	var stats := VBoxContainer.new()
	top.add_child(stats)
	var header := HBoxContainer.new()
	stats.add_child(header)
	hero_label = Label.new()
	hero_label.text = "CHEIKH"
	hero_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_label.add_theme_font_size_override("font_size", 28)
	hero_label.add_theme_color_override("font_color", GOLD_LIGHT)
	header.add_child(hero_label)
	level_label = Label.new()
	level_label.text = "NIVEAU 1"
	header.add_child(level_label)
	health_bar = _bar(Color("d5463c"), 34)
	energy_bar = _bar(Color("2d93d2"), 26)
	aura_bar = _bar(GOLD, 26)
	stats.add_child(health_bar)
	stats.add_child(energy_bar)
	stats.add_child(aura_bar)

	var mission := PanelContainer.new()
	mission.position = Vector2(650, 18)
	mission.size = Vector2(620, 150)
	mission.add_theme_stylebox_override("panel", _style(Color(0.01,0.025,0.05,0.76), Color("7ea6bc"), 18, 2))
	hud.add_child(mission)
	var box := VBoxContainer.new()
	mission.add_child(box)
	zone_label = Label.new()
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size", 27)
	zone_label.add_theme_color_override("font_color", GOLD_LIGHT)
	box.add_child(zone_label)
	mission_label = Label.new()
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(mission_label)
	weather_label = Label.new()
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(weather_label)

	coins_label = Label.new()
	coins_label.position = Vector2(1300, 30)
	coins_label.size = Vector2(350, 60)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 24)
	coins_label.add_theme_color_override("font_color", GOLD_LIGHT)
	hud.add_child(coins_label)
	var map := _small_button("CARTE")
	map.position = Vector2(1660, 25)
	map.pressed.connect(func(): pause_requested.emit(); show_map())
	hud.add_child(map)
	var pause := _small_button("PAUSE")
	pause.position = Vector2(1785, 25)
	pause.pressed.connect(func(): pause_requested.emit(); show_pause())
	hud.add_child(pause)

	var camera_area := CameraDragArea.new()
	camera_area.position = Vector2(500, 170)
	camera_area.size = Vector2(1420, 900)
	camera_area.dragged.connect(func(relative: Vector2): camera_dragged.emit(relative))
	hud.add_child(camera_area)
	var joystick := QuinetJoystick.new()
	joystick.position = Vector2(25, 790)
	joystick.size = Vector2(260, 260)
	joystick.vector_changed.connect(func(value: Vector2): move_changed.emit(value))
	hud.add_child(joystick)
	var hero := _action_button("HÉROS", Color("785a9e"), 115)
	hero.position = Vector2(310, 900)
	hero.pressed.connect(func(): switch_requested.emit())
	hud.add_child(hero)
	var attack := _action_button("ATTAQUE", RED, 150)
	attack.position = Vector2(1715, 865)
	attack.pressed.connect(func(): attack_requested.emit())
	hud.add_child(attack)
	var skill := _action_button("POUVOIR", BLUE, 126)
	skill.position = Vector2(1560, 780)
	skill.pressed.connect(func(): skill_requested.emit())
	hud.add_child(skill)
	var aura := _action_button("DÉFERLER", Color("b98126"), 126)
	aura.position = Vector2(1720, 650)
	aura.pressed.connect(func(): aura_requested.emit())
	hud.add_child(aura)

func _build_pause() -> void:
	pause_screen = ColorRect.new()
	pause_screen.color = Color(0,0,0,0.78)
	pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_screen)
	var column := VBoxContainer.new()
	column.position = Vector2(650, 300)
	column.size = Vector2(620, 440)
	column.add_theme_constant_override("separation", 25)
	pause_screen.add_child(column)
	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	column.add_child(title)
	var resume := _button("REPRENDRE", GREEN, 82)
	resume.pressed.connect(func(): pause_screen.hide(); resume_requested.emit())
	column.add_child(resume)
	var main_menu := _button("MENU PRINCIPAL", RED, 82)
	main_menu.pressed.connect(func(): pause_screen.hide(); quit_to_menu_requested.emit())
	column.add_child(main_menu)

func _build_game_over() -> void:
	game_over_screen = ColorRect.new()
	game_over_screen.color = Color(0.06,0,0,0.80)
	game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_over_screen)
	var label := Label.new()
	label.text = "ÉQUIPAGE À TERRE\nRetour au point de départ..."
	label.position = Vector2(460, 390)
	label.size = Vector2(1000, 220)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", GOLD_LIGHT)
	game_over_screen.add_child(label)

func _small_button(text: String) -> Button:
	var button := _button(text, Color("243b52"), 62)
	button.size = Vector2(120, 62)
	return button
func _action_button(text: String, color: Color, diameter: float) -> Button:
	var button := _button(text, color, diameter)
	button.size = Vector2(diameter, diameter)
	return button
func _button(text: String, color: Color, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = height
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_stylebox_override("normal", _style(Color(color,0.88), GOLD, 16, 2))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.28), GOLD_LIGHT, 16, 4))
	return button
func _bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = 100
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0,0,0,0.65), Color(1,1,1,0.22), 10, 1))
	bar.add_theme_stylebox_override("fill", _style(color, color.lightened(0.15), 10, 1))
	return bar
func _style(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
