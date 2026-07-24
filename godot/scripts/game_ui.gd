class_name GameUI
extends CanvasLayer

signal play_requested(new_game: bool)
signal difficulty_selected(difficulty: String)
signal hero_selected(hero_id: String)
signal zone_selected(zone_index: int)
signal training_requested(stat_name: String)
signal attack_requested
signal skill_requested
signal aura_requested
signal dodge_requested
signal switch_requested
signal move_changed(value: Vector2)
signal camera_stick_changed(value: Vector2)
signal camera_dragged(relative: Vector2)
signal boat_requested
signal pause_requested
signal resume_requested
signal quit_to_menu_requested
signal voice_toggled(active: bool)

const GOLD := Color("d6a63d")
const GOLD_LIGHT := Color("f5d985")
const RED := Color("a82e2c")
const BLUE := Color("256fa3")
const GREEN := Color("2f8b5d")
const HUD_DARK := Color(0.008, 0.02, 0.04, 0.9)

var menu: MenuUI
var hud: Control
var pause_screen: Control
var game_over_screen: Control
var health_bar: ProgressBar
var energy_bar: ProgressBar
var aura_bar: ProgressBar
var health_value: Label
var energy_value: Label
var aura_value: Label
var hero_label: Label
var level_label: Label
var zone_label: Label
var mission_label: Label
var weather_label: Label
var coins_label: Label
var navigation_label: Label
var difficulty_label: Label
var hero_view: TextureRect
var sailing_speed_label: Label
var boat_button: Button
var combat_buttons: Array[Button] = []
var current_hero_id := "cheikh"
var current_hero_frame := 0
var hero_front_view := false
var sailing := false
var sailing_steering := 0.0
var sailing_throttle := 0.0
var sailing_speed_ratio := 0.0
var sailing_visual_time := 0.0
var overlay_marker_emitted := false
var boat_marker_emitted := false
var attack_held := false
var attack_repeat_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu = MenuUI.new()
	add_child(menu)
	menu.build()
	menu.play_requested.connect(func(value: bool): play_requested.emit(value))
	menu.difficulty_selected.connect(func(value: String): difficulty_selected.emit(value))
	menu.hero_selected.connect(func(value: String): hero_selected.emit(value))
	menu.zone_selected.connect(func(value: int): zone_selected.emit(value))
	menu.training_requested.connect(func(value: String): training_requested.emit(value))
	menu.voice_toggled.connect(func(value: bool): voice_toggled.emit(value))
	menu.back_to_game_requested.connect(func(): show_hud(); resume_requested.emit())
	_build_hud()
	_build_pause()
	_build_game_over()
	show_main_menu()

func _process(delta: float) -> void:
	if sailing and is_instance_valid(hero_view) and hero_view.visible:
		sailing_visual_time += delta
		hero_view.pivot_offset = hero_view.size * 0.5
		hero_view.rotation = sin(sailing_visual_time * 2.4) * 0.004 - sailing_steering * 0.012 * sailing_speed_ratio
	if attack_held and is_instance_valid(hud) and hud.visible:
		attack_repeat_timer -= delta
		if attack_repeat_timer <= 0.0:
			attack_repeat_timer = 0.14
			attack_requested.emit()

func show_main_menu() -> void:
	attack_held = false
	hud.hide()
	pause_screen.hide()
	game_over_screen.hide()
	menu.show()
	menu.show_main()

func show_hud() -> void:
	attack_held = false
	menu.hide()
	pause_screen.hide()
	game_over_screen.hide()
	hud.show()
	if not overlay_marker_emitted and is_instance_valid(hero_view) and hero_view.texture != null:
		overlay_marker_emitted = true
		print("CHK_HERO_OVERLAY_READY hero=%s" % current_hero_id)

func show_map() -> void:
	hud.hide()
	menu.show()
	menu.show_map(true)

func show_pause() -> void:
	pause_screen.show()

func show_game_over() -> void:
	game_over_screen.show()

func set_voice_enabled(active: bool) -> void:
	menu.set_voice(active)

func set_unlocked_zones(zones: Array) -> void:
	menu.set_unlocked_zones(zones)

func update_difficulty(value: String) -> void:
	var display := "DÉCOUVERTE" if value == "decouverte" else "DIFFICILE" if value == "difficile" else "INTERMÉDIAIRE"
	difficulty_label.text = "MODE " + display

func update_navigation(text: String, bearing: float, _distance: float) -> void:
	if is_instance_valid(navigation_label):
		navigation_label.text = _bearing_arrow(bearing) + "  " + text

func set_boat_action(label: String, available: bool, on_boat: bool) -> void:
	if is_instance_valid(boat_button):
		boat_button.text = label
		boat_button.disabled = not available
	set_boat_mode(on_boat)

func set_boat_mode(active: bool) -> void:
	var state_changed := sailing != active
	sailing = active
	if is_instance_valid(hero_view):
		hero_view.visible = true
		_apply_hero_view_layout()
		if state_changed:
			if active:
				update_boat_steering(current_hero_id, 0.0, 0.0, 0.0)
			else:
				hero_view.rotation = 0.0
				update_hero_pose(current_hero_id, current_hero_frame, hero_front_view)
	if is_instance_valid(sailing_speed_label):
		sailing_speed_label.visible = active
	for button in combat_buttons:
		if is_instance_valid(button):
			button.disabled = active

func update_stats(health: float, max_health: float, energy: float, aura: float, level: int, _xp: int, coins: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	energy_bar.max_value = 100.0
	energy_bar.value = energy
	aura_bar.max_value = 100.0
	aura_bar.value = aura
	health_value.text = "%d / %d" % [roundi(health), roundi(max_health)]
	energy_value.text = "%d / 100" % roundi(energy)
	aura_value.text = "%d %%" % roundi(aura)
	level_label.text = "NIVEAU " + str(level)
	coins_label.text = str(coins) + " PIÈCES"
	menu.update_training(level, coins)

func update_hero(hero_id: String, display_name: String) -> void:
	hero_label.text = display_name.to_upper()
	if sailing:
		update_boat_steering(hero_id, sailing_steering, sailing_throttle, sailing_speed_ratio)
	else:
		update_hero_pose(hero_id, 0)

func update_hero_pose(hero_id: String, frame: int, front_view: bool = false) -> void:
	if not HeroFactory.HEROES.has(hero_id) or not is_instance_valid(hero_view):
		return
	if sailing:
		return
	current_hero_id = hero_id
	current_hero_frame = clampi(frame, 0, 3)
	hero_front_view = front_view
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	var texture_path := String(profile["sprite"]) if front_view else String(profile["third_person_sprite"])
	hero_view.texture = _atlas_frame(texture_path, 4, current_hero_frame)

func update_boat_steering(hero_id: String, steering: float, throttle: float, speed_ratio: float) -> void:
	if not HeroFactory.HEROES.has(hero_id) or not is_instance_valid(hero_view):
		return
	current_hero_id = hero_id
	sailing_steering = clampf(steering, -1.0, 1.0)
	sailing_throttle = clampf(throttle, -1.0, 1.0)
	sailing_speed_ratio = clampf(speed_ratio, 0.0, 1.0)
	if not sailing:
		return
	var frame := 0 if sailing_steering < -0.16 else 2 if sailing_steering > 0.16 else 1
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	hero_view.texture = _atlas_frame(String(profile["steering_sprite"]), 3, frame)
	if is_instance_valid(sailing_speed_label):
		var speed_knots := roundi(sailing_speed_ratio * 24.0)
		var helm_text := "VIRAGE À GAUCHE" if frame == 0 else "VIRAGE À DROITE" if frame == 2 else "CAP STABLE"
		sailing_speed_label.text = "%s À LA BARRE  •  %s  •  %d NŒUDS" % [
			String(profile["display_name"]),
			helm_text,
			speed_knots
		]
	if not boat_marker_emitted:
		boat_marker_emitted = true
		print("CHK_BOAT_HELMSMAN_READY hero=%s frame=%d" % [hero_id, frame])

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

	var camera_area := CameraDragArea.new()
	_set_rect(camera_area, 0.34, 0.0, 1.0, 1.0, 0, 110, 0, 0)
	camera_area.dragged.connect(func(relative: Vector2): camera_dragged.emit(relative))
	hud.add_child(camera_area)

	# Personnage 2.5D toujours lisible : le gameplay et les collisions restent
	# en 3D, mais la planche de dos est cadrée comme dans un jeu d'aventure à
	# la troisième personne, sans dépendre du tri alpha du pilote mobile.
	hero_view = TextureRect.new()
	hero_view.name = "HérosTroisièmePersonne"
	_set_rect(hero_view, 0.5, 1.0, 0.5, 1.0, -300, -590, 360, 590)
	hero_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hero_view.z_index = 4
	hud.add_child(hero_view)
	update_hero_pose(current_hero_id, 0)

	var stats_panel := PanelContainer.new()
	_set_rect(stats_panel, 0.0, 0.0, 0.0, 0.0, 18, 16, 510, 172)
	stats_panel.add_theme_stylebox_override("panel", _style(HUD_DARK, GOLD, 22, 3))
	hud.add_child(stats_panel)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	stats_panel.add_child(stats)
	var header := HBoxContainer.new()
	stats.add_child(header)
	hero_label = Label.new()
	hero_label.text = "CHEIKH"
	hero_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_label.add_theme_font_size_override("font_size", 34)
	hero_label.add_theme_color_override("font_color", GOLD_LIGHT)
	header.add_child(hero_label)
	level_label = Label.new()
	level_label.text = "NIVEAU 1"
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(level_label)

	var health_row := _labeled_bar("VIE", Color("d5463c"), 38)
	health_bar = health_row[0]
	health_value = health_row[1]
	stats.add_child(health_row[2])
	var energy_row := _labeled_bar("ÉNERGIE", Color("2d93d2"), 29)
	energy_bar = energy_row[0]
	energy_value = energy_row[1]
	stats.add_child(energy_row[2])
	var aura_row := _labeled_bar("AURA", GOLD, 29)
	aura_bar = aura_row[0]
	aura_value = aura_row[1]
	stats.add_child(aura_row[2])

	var mission := PanelContainer.new()
	_set_rect(mission, 0.5, 0.0, 0.5, 0.0, -330, 16, 660, 126)
	mission.add_theme_stylebox_override("panel", _style(Color(0.008, 0.022, 0.045, 0.86), Color("7ea6bc"), 22, 3))
	hud.add_child(mission)
	var mission_box := VBoxContainer.new()
	mission_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mission.add_child(mission_box)
	zone_label = Label.new()
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size", 31)
	zone_label.add_theme_color_override("font_color", GOLD_LIGHT)
	mission_box.add_child(zone_label)
	mission_label = Label.new()
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.add_theme_font_size_override("font_size", 22)
	mission_box.add_child(mission_label)
	weather_label = Label.new()
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weather_label.add_theme_font_size_override("font_size", 19)
	weather_label.add_theme_color_override("font_color", Color("a9c9de"))
	mission_box.add_child(weather_label)

	var navigation_panel := PanelContainer.new()
	_set_rect(navigation_panel, 0.5, 0.0, 0.5, 0.0, -420, 152, 840, 76)
	navigation_panel.add_theme_stylebox_override("panel", _style(Color(0.01, 0.035, 0.055, 0.84), GOLD, 18, 2))
	hud.add_child(navigation_panel)
	navigation_label = Label.new()
	navigation_label.text = "↑  REJOINS LE QUAI"
	navigation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	navigation_label.add_theme_font_size_override("font_size", 23)
	navigation_label.add_theme_color_override("font_color", GOLD_LIGHT)
	navigation_panel.add_child(navigation_label)

	sailing_speed_label = Label.new()
	sailing_speed_label.name = "ÉtatPilotage"
	_set_rect(sailing_speed_label, 0.5, 1.0, 0.5, 1.0, -390, -82, 780, 48)
	sailing_speed_label.text = "CHEIKH À LA BARRE  •  CAP STABLE  •  0 NŒUD"
	sailing_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sailing_speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sailing_speed_label.add_theme_font_size_override("font_size", 21)
	sailing_speed_label.add_theme_color_override("font_color", GOLD_LIGHT)
	sailing_speed_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	sailing_speed_label.add_theme_constant_override("shadow_offset_x", 2)
	sailing_speed_label.add_theme_constant_override("shadow_offset_y", 2)
	sailing_speed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sailing_speed_label.z_index = 5
	sailing_speed_label.visible = false
	hud.add_child(sailing_speed_label)

	coins_label = Label.new()
	_set_rect(coins_label, 1.0, 0.0, 1.0, 0.0, -510, 25, 255, 54)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 27)
	coins_label.add_theme_color_override("font_color", GOLD_LIGHT)
	hud.add_child(coins_label)
	difficulty_label = Label.new()
	_set_rect(difficulty_label, 1.0, 0.0, 1.0, 0.0, -540, 70, 285, 44)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", Color("b9d4e3"))
	difficulty_label.text = "MODE INTERMÉDIAIRE"
	hud.add_child(difficulty_label)
	var map := _small_button("CARTE")
	_set_rect(map, 1.0, 0.0, 1.0, 0.0, -240, 18, 105, 68)
	map.pressed.connect(func(): pause_requested.emit(); show_map())
	hud.add_child(map)
	var pause := _small_button("PAUSE")
	_set_rect(pause, 1.0, 0.0, 1.0, 0.0, -125, 18, 105, 68)
	pause.pressed.connect(func(): pause_requested.emit(); show_pause())
	hud.add_child(pause)

	var joystick := QuinetJoystick.new()
	_set_rect(joystick, 0.0, 1.0, 0.0, 1.0, 24, -266, 248, 248)
	joystick.radius = 88.0
	joystick.knob_radius = 38.0
	joystick.vector_changed.connect(func(value: Vector2): move_changed.emit(value))
	hud.add_child(joystick)
	var camera_joystick := QuinetJoystick.new()
	camera_joystick.name = "StickCaméra360"
	_set_rect(camera_joystick, 0.0, 1.0, 0.0, 1.0, 276, -238, 216, 216)
	camera_joystick.radius = 72.0
	camera_joystick.knob_radius = 30.0
	camera_joystick.deadzone = 0.08
	camera_joystick.vector_changed.connect(func(value: Vector2): camera_stick_changed.emit(value))
	hud.add_child(camera_joystick)
	var camera_caption := Label.new()
	_set_rect(camera_caption, 0.0, 1.0, 0.0, 1.0, 284, -258, 200, 34)
	camera_caption.text = "CAMÉRA 360°"
	camera_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camera_caption.add_theme_font_size_override("font_size", 18)
	camera_caption.add_theme_color_override("font_color", GOLD_LIGHT)
	camera_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(camera_caption)
	var hero := _action_button("HÉROS", Color("785a9e"), 126, 25)
	_set_rect(hero, 0.0, 1.0, 0.0, 1.0, 510, -124, 108, 108)
	hero.pressed.connect(func(): switch_requested.emit())
	hud.add_child(hero)
	combat_buttons.append(hero)
	boat_button = _button("EMBARQUER", Color("8a5b2c"), 92, 21)
	_set_rect(boat_button, 0.0, 1.0, 0.0, 1.0, 630, -116, 190, 92)
	boat_button.disabled = true
	boat_button.pressed.connect(func(): boat_requested.emit())
	hud.add_child(boat_button)

	var attack := _action_button("ATTAQUE", RED, 158, 27)
	_set_rect(attack, 1.0, 1.0, 1.0, 1.0, -180, -180, 158, 158)
	attack.button_down.connect(func():
		attack_held = true
		attack_repeat_timer = 0.0
	)
	attack.button_up.connect(func(): attack_held = false)
	hud.add_child(attack)
	combat_buttons.append(attack)
	var skill := _action_button("POUVOIR", BLUE, 128, 23)
	_set_rect(skill, 1.0, 1.0, 1.0, 1.0, -326, -146, 128, 128)
	skill.pressed.connect(func(): skill_requested.emit())
	hud.add_child(skill)
	combat_buttons.append(skill)
	var dodge := _action_button("ESQUIVE", Color("3c7b86"), 116, 20)
	_set_rect(dodge, 1.0, 1.0, 1.0, 1.0, -456, -130, 116, 116)
	dodge.pressed.connect(func(): dodge_requested.emit())
	hud.add_child(dodge)
	combat_buttons.append(dodge)
	var aura := _action_button("DÉFERLER", Color("b98126"), 126, 21)
	_set_rect(aura, 1.0, 1.0, 1.0, 1.0, -176, -330, 126, 126)
	aura.pressed.connect(func(): aura_requested.emit())
	hud.add_child(aura)
	combat_buttons.append(aura)

func _build_pause() -> void:
	pause_screen = ColorRect.new()
	pause_screen.color = Color(0, 0, 0, 0.82)
	pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_screen)
	var panel := PanelContainer.new()
	_set_rect(panel, 0.5, 0.5, 0.5, 0.5, -340, -235, 680, 470)
	panel.add_theme_stylebox_override("panel", _style(HUD_DARK, GOLD, 28, 4))
	pause_screen.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	panel.add_child(column)
	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", GOLD_LIGHT)
	column.add_child(title)
	var resume := _button("REPRENDRE", GREEN, 92, 29)
	resume.pressed.connect(func(): pause_screen.hide(); resume_requested.emit())
	column.add_child(resume)
	var main_menu := _button("MENU PRINCIPAL", RED, 92, 29)
	main_menu.pressed.connect(func(): pause_screen.hide(); quit_to_menu_requested.emit())
	column.add_child(main_menu)

func _build_game_over() -> void:
	game_over_screen = ColorRect.new()
	game_over_screen.color = Color(0.06, 0, 0, 0.84)
	game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_over_screen)
	var label := Label.new()
	_set_rect(label, 0.5, 0.5, 0.5, 0.5, -580, -125, 1160, 250)
	label.text = "ÉQUIPAGE À TERRE\nRetour au point de départ..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 58)
	label.add_theme_color_override("font_color", GOLD_LIGHT)
	game_over_screen.add_child(label)

func _labeled_bar(title: String, color: Color, height: float) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 92
	label.add_theme_font_size_override("font_size", 20)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var bar := _bar(color, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	var value := Label.new()
	value.text = "100 / 100"
	value.custom_minimum_size.x = 105
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	row.add_child(value)
	return [bar, value, row]

func _small_button(text: String) -> Button:
	return _button(text, Color("243b52"), 68, 20)

func _action_button(text: String, color: Color, diameter: float, font_size: int) -> Button:
	var button := _button(text, color, diameter, font_size)
	button.custom_minimum_size = Vector2(diameter, diameter)
	return button

func _button(text: String, color: Color, height: float, font_size: int = 24) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = height
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _style(Color(color, 0.92), GOLD, 22, 3))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.08), GOLD_LIGHT, 22, 4))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.28), Color.WHITE, 22, 5))
	return button

func _bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = 100
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0, 0, 0, 0.72), Color(1, 1, 1, 0.28), 12, 2))
	bar.add_theme_stylebox_override("fill", _style(color, color.lightened(0.18), 12, 2))
	return bar

func _style(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _set_rect(control: Control, anchor_left: float, anchor_top: float, anchor_right: float, anchor_bottom: float, x: float, y: float, width: float, height: float) -> void:
	control.anchor_left = anchor_left
	control.anchor_top = anchor_top
	control.anchor_right = anchor_right
	control.anchor_bottom = anchor_bottom
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height

func _bearing_arrow(bearing: float) -> String:
	var directions := ["↑", "↖", "←", "↙", "↓", "↘", "→", "↗"]
	var index := posmod(roundi(bearing / (PI / 4.0)), directions.size())
	return directions[index]

func _atlas_frame(texture_path: String, frame_count: int, frame: int) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = load(texture_path) as Texture2D
	var safe_count := maxi(frame_count, 1)
	var frame_width := float(atlas_texture.atlas.get_width()) / float(safe_count)
	atlas_texture.region = Rect2(
		frame_width * clampi(frame, 0, safe_count - 1),
		0.0,
		frame_width,
		float(atlas_texture.atlas.get_height())
	)
	return atlas_texture

func _apply_hero_view_layout() -> void:
	if not is_instance_valid(hero_view):
		return
	if sailing:
		_set_rect(hero_view, 0.5, 1.0, 0.5, 1.0, -270, -650, 540, 610)
	else:
		_set_rect(hero_view, 0.5, 1.0, 0.5, 1.0, -300, -590, 360, 590)
