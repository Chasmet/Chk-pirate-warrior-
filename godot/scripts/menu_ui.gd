class_name MenuUI
extends Control

signal play_requested(new_game: bool)
signal hero_selected(hero_id: String)
signal zone_selected(zone_index: int)
signal training_requested(stat_name: String)
signal voice_toggled(active: bool)
signal back_to_game_requested

const GOLD := Color("d6a63d")
const GOLD_LIGHT := Color("f5d985")
const PANEL := Color(0.012, 0.027, 0.050, 0.94)
const PANEL_SOFT := Color(0.018, 0.045, 0.075, 0.88)
const RED := Color("a82e2c")
const BLUE := Color("256fa3")
const GREEN := Color("2f8b5d")
const PURPLE := Color("785a9e")
const ZONE_NAMES := ["PORT DES\nNAUFRAGÉS", "JUNGLE\nSAUVAGE", "ROYAUME\nDES NEIGES", "DÉSERT DES\nCORSAIRES", "ÎLE\nVOLCANIQUE", "FORTERESSE\nDE LA TEMPÊTE"]
const ZONE_COLORS := [Color("446a73"), Color("26704a"), Color("78aaca"), Color("bd813e"), RED, Color("485d78")]

var screens: Array[Control] = []
var main_menu: Control
var hero_screen: Control
var map_screen: Control
var enemies_screen: Control
var bosses_screen: Control
var training_screen: Control
var settings_screen: Control
var training_info: Label
var voice_button: Button
var voice_enabled := true
var map_from_game := false

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_main()
	_build_heroes()
	_build_map()
	enemies_screen = _build_gallery(false)
	bosses_screen = _build_gallery(true)
	_build_training()
	_build_settings()
	show_main()

func show_main() -> void:
	map_from_game = false
	_show(main_menu)

func show_map(from_game: bool = false) -> void:
	map_from_game = from_game
	_show(map_screen)

func update_training(level: int, coins: int) -> void:
	if is_instance_valid(training_info):
		training_info.text = "NIVEAU %d   •   %d PIÈCES DISPONIBLES" % [level, coins]

func set_voice(active: bool) -> void:
	voice_enabled = active
	if is_instance_valid(voice_button):
		voice_button.text = "VOIX FRANÇAISE : " + ("ACTIVÉE" if active else "DÉSACTIVÉE")

func _build_main() -> void:
	main_menu = Control.new()
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_menu)
	screens.append(main_menu)

	var backdrop := ColorRect.new()
	backdrop.color = Color("020914")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu.add_child(backdrop)

	var canvas := Control.new()
	canvas.name = "MenuRéférence"
	canvas.set_anchors_preset(Control.PRESET_CENTER)
	canvas.position = Vector2(-768, -432)
	canvas.size = Vector2(1536, 864)
	main_menu.add_child(canvas)

	var reference := TextureRect.new()
	reference.texture = load("res://assets/ui/menu_reference.jpg") as Texture2D
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reference.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(reference)

	_reference_hotspot(canvas, Rect2(38, 174, 326, 66), "Jouer une nouvelle partie", func(): play_requested.emit(true))
	_reference_hotspot(canvas, Rect2(38, 244, 326, 66), "Continuer la partie", func(): play_requested.emit(false))
	_reference_hotspot(canvas, Rect2(38, 313, 326, 64), "Choisir Cheikh, Yvane ou Nelvyn", func(): _show(hero_screen))
	_reference_hotspot(canvas, Rect2(38, 380, 326, 64), "Entraînement", func(): _show(training_screen))
	_reference_hotspot(canvas, Rect2(38, 446, 326, 64), "Paramètres", func(): _show(settings_screen))
	_reference_hotspot(canvas, Rect2(8, 512, 373, 308), "Galerie des ennemis", func(): _show(enemies_screen))
	_reference_hotspot(canvas, Rect2(1028, 465, 500, 354), "Galerie des boss", func(): _show(bosses_screen))
	_reference_hotspot(canvas, Rect2(390, 74, 492, 458), "Choix du héros", func(): _show(hero_screen))

	var zone_rects := [
		Rect2(917, 72, 188, 146),
		Rect2(1110, 72, 188, 146),
		Rect2(1304, 72, 188, 146),
		Rect2(917, 272, 188, 146),
		Rect2(1110, 272, 188, 146),
		Rect2(1304, 272, 188, 146)
	]
	for index in range(zone_rects.size()):
		_reference_hotspot(
			canvas,
			zone_rects[index],
			"Voyager : " + String(ZONE_NAMES[index]).replace("\n", " "),
			_emit_zone.bind(index)
		)

func _build_heroes() -> void:
	hero_screen = _screen("CHOIX DU HÉROS", "Trois personnages jouables. Choisis celui que tu contrôles.")
	var row := HBoxContainer.new()
	row.position = Vector2(72, 135)
	row.size = Vector2(1776, 690)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	hero_screen.add_child(row)
	for hero_id in ["nelvyn", "cheikh", "yvane"]:
		row.add_child(_hero_card(hero_id, Vector2(570, 675), true))
	_add_back(hero_screen)

func _build_map() -> void:
	map_screen = _screen("CARTE DU MONDE", "Six grandes régions reliées par l'océan.")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(110, 145)
	grid.size = Vector2(1700, 670)
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	map_screen.add_child(grid)
	var descriptions: Array[String] = ["Quais, navires et premier capitaine", "Cascades, végétation et créatures", "Glace, blizzard et traces dans la neige", "Ruines, chaleur et sable", "Lave, cendres et Général Volkan", "Orages, forteresse et Amiral Vorga"]
	for i in range(ZONE_NAMES.size()):
		var zone_name: String = String(ZONE_NAMES[i]).replace("\n", " ")
		var zone := _button(str(i + 1) + "  •  " + zone_name + "\n" + descriptions[i], ZONE_COLORS[i], 300, 25)
		zone.custom_minimum_size = Vector2(550, 300)
		zone.pressed.connect(_emit_zone.bind(i))
		grid.add_child(zone)
	_add_map_back()

func _build_gallery(is_bosses: bool) -> Control:
	var screen := _screen("TOUS LES BOSS" if is_bosses else "TOUS LES ENNEMIS", "Galerie complète des adversaires du jeu.")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 135)
	scroll.size = Vector2(1780, 700)
	screen.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3 if is_bosses else 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	var profiles := EnemyFactory.BOSSES if is_bosses else EnemyFactory.ENEMIES
	for profile in profiles:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(565 if is_bosses else 425, 250 if is_bosses else 205)
		card.add_theme_stylebox_override("panel", _style(PANEL, Color(profile["color"]), 22, 3))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		box.add_child(_title("☠" if is_bosses else "⚔", 64 if is_bosses else 48, Color(profile["color"]).lightened(0.25)))
		box.add_child(_title(String(profile["name"]).to_upper(), 24 if is_bosses else 20))
		box.add_child(_title("VIE %d   •   PUISSANCE %d" % [int(profile["health"]), int(profile["damage"])], 17, Color("d6dde2")))
		grid.add_child(card)
	_add_back(screen)
	return screen

func _build_training() -> void:
	training_screen = _screen("ENTRAÎNEMENT ET MAÎTRISE", "Améliore les capacités des trois héros.")
	training_info = Label.new()
	training_info.position = Vector2(240, 130)
	training_info.size = Vector2(1440, 55)
	training_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_info.add_theme_font_size_override("font_size", 27)
	training_info.add_theme_color_override("font_color", GOLD_LIGHT)
	training_screen.add_child(training_info)
	var row := HBoxContainer.new()
	row.position = Vector2(100, 210)
	row.size = Vector2(1720, 600)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	training_screen.add_child(row)
	var training_cards := [["force", "FORCE", RED, "⚔", "Dégâts et résistance"], ["vitesse", "VITESSE", BLUE, "⚡", "Course et esquive"], ["energie", "ÉNERGIE", GREEN, "✦", "Pouvoirs et aura"]]
	for data in training_cards:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(550, 560)
		card.add_theme_stylebox_override("panel", _style(PANEL, Color(data[2]), 28, 4))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 18)
		card.add_child(box)
		box.add_child(_title(String(data[3]), 105, Color(data[2])))
		box.add_child(_title(String(data[1]), 42))
		box.add_child(_title(String(data[4]), 23, Color("d6dde2")))
		var train := _button("S'ENTRAÎNER", Color(data[2]), 90, 28)
		var stat_name := String(data[0])
		train.pressed.connect(func(): training_requested.emit(stat_name))
		box.add_child(train)
		row.add_child(card)
	_add_back(training_screen)

func _build_settings() -> void:
	settings_screen = _screen("PARAMÈTRES", "Réglages adaptés au téléphone Android.")
	var panel := _panel(settings_screen, Vector2(500, 180), Vector2(920, 570), GOLD)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)
	voice_button = _button("VOIX FRANÇAISE : ACTIVÉE", BLUE, 94, 28)
	voice_button.pressed.connect(func(): voice_enabled = not voice_enabled; set_voice(voice_enabled); voice_toggled.emit(voice_enabled))
	box.add_child(voice_button)
	box.add_child(_title("QUALITÉ GRAPHIQUE : ÉLEVÉE\nPAYSAGE 20:9 VERROUILLÉ\nSAUVEGARDE LOCALE\nFONCTIONNEMENT HORS CONNEXION", 28))
	_add_back(settings_screen)

func _hero_card(hero_id: String, card_size: Vector2, selectable: bool) -> PanelContainer:
	var profile: Dictionary = HeroFactory.HEROES[hero_id]
	var card := PanelContainer.new()
	card.custom_minimum_size = card_size
	card.add_theme_stylebox_override("panel", _style(PANEL_SOFT, Color(profile["aura"]), 24, 3))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var preview_height := card_size.y - (185 if selectable else 120)
	box.add_child(_hero_preview(hero_id, Vector2(card_size.x - 18, preview_height)))
	box.add_child(_title(String(profile["display_name"]), 34 if selectable else 28))
	box.add_child(_title(String(profile["role"]), 19, Color("d2dbe0")))
	if selectable:
		var choose := _button("CHOISIR " + String(profile["display_name"]), Color(profile["aura"]), 72, 23)
		choose.pressed.connect(func(): hero_selected.emit(hero_id))
		box.add_child(choose)
	return card

func _hero_preview(hero_id: String, preview_size: Vector2) -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = preview_size
	container.stretch = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(maxi(256, int(preview_size.x)), maxi(384, int(preview_size.y)))
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var hero := HeroFactory.create_hero(hero_id, false)
	stage.add_child(hero)
	hero.scale = Vector3.ONE
	var nameplate := hero.get_node_or_null("Nom")
	if nameplate != null:
		nameplate.hide()
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 1.05, -3.25 if hero_id == "cheikh" else -2.85)
	camera.look_at_from_position(camera.position, Vector3(0, float(HeroFactory.HEROES[hero_id]["height"]) * 0.48, 0), Vector3.UP)
	camera.fov = 34.0
	camera.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 145, 0)
	key.light_energy = 2.0
	key.light_color = Color("ffe4bc")
	stage.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.8, 1.6, -2.0)
	fill.light_energy = 5.0
	fill.light_color = Color(HeroFactory.HEROES[hero_id]["aura"])
	fill.omni_range = 6.0
	stage.add_child(fill)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.005, 0.012, 0.025, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8da8bc")
	environment.ambient_light_energy = 0.72
	environment_node.environment = environment
	stage.add_child(environment_node)
	return container

func _screen(title_text: String, subtitle: String) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	screens.append(screen)
	var background := TextureRect.new()
	background.texture = EmbeddedArt.interface_texture()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	if not title_text.is_empty():
		var title := _title(title_text, 48)
		title.position = Vector2(170, 22)
		title.size = Vector2(1580, 72)
		screen.add_child(title)
		var sub := _title(subtitle, 20, Color("d6dde2"))
		sub.position = Vector2(260, 86)
		sub.size = Vector2(1400, 38)
		screen.add_child(sub)
	return screen

func _panel(parent: Control, position: Vector2, panel_size: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _style(PANEL, border, 26, 4))
	parent.add_child(panel)
	return panel

func _title(text_value: String, font_size: int, color: Color = GOLD_LIGHT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _add_back(screen: Control) -> void:
	var back := _button("← RETOUR", Color("243b52"), 66, 21)
	back.position = Vector2(22, 20)
	back.size = Vector2(155, 66)
	back.pressed.connect(show_main)
	screen.add_child(back)

func _add_map_back() -> void:
	var back := _button("← RETOUR", Color("243b52"), 66, 21)
	back.position = Vector2(22, 20)
	back.size = Vector2(155, 66)
	back.pressed.connect(func():
		if map_from_game:
			map_from_game = false
			back_to_game_requested.emit()
		else:
			show_main()
	)
	map_screen.add_child(back)

func _show(target: Control) -> void:
	for screen in screens:
		screen.hide()
	target.show()

func _emit_zone(zone_index: int) -> void:
	zone_selected.emit(zone_index)

func _button(text_value: String, color: Color, height: float, font_size: int = 24) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = height
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _style(Color(color, 0.92), GOLD, 18, 3))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.08), GOLD_LIGHT, 18, 4))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.28), Color.WHITE, 18, 5))
	return button

func _reference_hotspot(parent: Control, rect: Rect2, tooltip: String, callback: Callable) -> void:
	var hotspot := Button.new()
	hotspot.position = rect.position
	hotspot.size = rect.size
	hotspot.flat = true
	hotspot.tooltip_text = tooltip
	hotspot.focus_mode = Control.FOCUS_NONE
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color.TRANSPARENT
	clear.border_color = Color.TRANSPARENT
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.96, 0.66, 0.16, 0.10)
	hover.border_color = GOLD_LIGHT
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(12)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(1.0, 0.73, 0.22, 0.24)
	pressed.border_color = Color.WHITE
	pressed.set_border_width_all(4)
	pressed.set_corner_radius_all(12)
	hotspot.add_theme_stylebox_override("normal", clear)
	hotspot.add_theme_stylebox_override("hover", hover)
	hotspot.add_theme_stylebox_override("pressed", pressed)
	hotspot.pressed.connect(callback)
	parent.add_child(hotspot)

func _style(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
