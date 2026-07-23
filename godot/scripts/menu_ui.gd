class_name MenuUI
extends Control

signal play_requested(new_game: bool)
signal hero_selected(hero_id: String)
signal zone_selected(zone_index: int)
signal training_requested(stat_name: String)
signal voice_toggled(active: bool)

const GOLD := Color("d6a63d")
const GOLD_LIGHT := Color("f5d985")
const PANEL := Color(0.015, 0.035, 0.065, 0.94)
const RED := Color("a82e2c")
const BLUE := Color("256fa3")
const GREEN := Color("2f8b5d")

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

func show_main() -> void: _show(main_menu)
func show_map() -> void: _show(map_screen)
func update_training(level: int, coins: int) -> void:
	training_info.text = "Niveau %d  •  %d pièces disponibles" % [level, coins]
func set_voice(active: bool) -> void:
	voice_enabled = active
	if is_instance_valid(voice_button): voice_button.text = "VOIX FRANÇAISE : " + ("ACTIVÉE" if active else "DÉSACTIVÉE")

func _build_main() -> void:
	main_menu = _screen("CHK PIRATE WARRIOR", "L'ARCHIPEL DES QUINET — V2 MONDE OUVERT 3D")
	var menu := VBoxContainer.new()
	menu.position = Vector2(90, 285)
	menu.size = Vector2(520, 690)
	menu.add_theme_constant_override("separation", 14)
	main_menu.add_child(menu)
	var actions := [
		["JOUER", RED, func(): play_requested.emit(true)], ["CONTINUER", BLUE, func(): play_requested.emit(false)],
		["CHOIX DU HÉROS", Color("785a9e"), func(): _show(hero_screen)], ["CARTE DU MONDE", Color("2c7187"), func(): _show(map_screen)],
		["ENTRAÎNEMENT", GREEN, func(): _show(training_screen)], ["TOUS LES ENNEMIS", Color("8b5b36"), func(): _show(enemies_screen)],
		["TOUS LES BOSS", Color("862f38"), func(): _show(bosses_screen)], ["PARAMÈTRES", Color("4f5968"), func(): _show(settings_screen)]
	]
	for action in actions:
		var button := _button(String(action[0]), Color(action[1]), 62)
		button.pressed.connect(action[2])
		menu.add_child(button)
	var row := HBoxContainer.new()
	row.position = Vector2(740, 285)
	row.size = Vector2(1080, 560)
	row.add_theme_constant_override("separation", 25)
	main_menu.add_child(row)
	for id in ["nelvyn", "cheikh", "yvane"]:
		var profile: Dictionary = HeroFactory.HEROES[id]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(335, 530)
		card.add_theme_stylebox_override("panel", _style(Color(0.01,0.03,0.05,0.86), Color(profile["aura"]), 24, 3))
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; card.add_child(column)
		var icon := Label.new(); icon.text = "⚙" if id == "nelvyn" else "♛" if id == "cheikh" else "⚡"; icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 130); icon.add_theme_color_override("font_color", Color(profile["aura"])); column.add_child(icon)
		var name := Label.new(); name.text = String(profile["display_name"]); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.add_theme_font_size_override("font_size", 38); name.add_theme_color_override("font_color", GOLD_LIGHT); column.add_child(name)
		var role := Label.new(); role.text = String(profile["role"]); role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; role.add_theme_font_size_override("font_size", 21); column.add_child(role)
		row.add_child(card)

func _build_heroes() -> void:
	hero_screen = _screen("CHOIX DU HÉROS", "Trois styles de combat, trois auras et trois évolutions.")
	var row := HBoxContainer.new(); row.position = Vector2(130, 260); row.size = Vector2(1660, 600); row.add_theme_constant_override("separation", 35); hero_screen.add_child(row)
	for id in ["cheikh", "yvane", "nelvyn"]:
		var profile: Dictionary = HeroFactory.HEROES[id]
		var card := PanelContainer.new(); card.custom_minimum_size = Vector2(520, 570); card.add_theme_stylebox_override("panel", _style(PANEL, Color(profile["aura"]), 28, 4))
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; card.add_child(column)
		var icon := Label.new(); icon.text = "♛" if id == "cheikh" else "⚡" if id == "yvane" else "⚙"; icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 130); icon.add_theme_color_override("font_color", Color(profile["aura"])); column.add_child(icon)
		var title := Label.new(); title.text = String(profile["display_name"]); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 44); title.add_theme_color_override("font_color", GOLD_LIGHT); column.add_child(title)
		var role := Label.new(); role.text = String(profile["role"]); role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; role.add_theme_font_size_override("font_size", 24); column.add_child(role)
		var choose := _button("CHOISIR", Color(profile["aura"]), 70); choose.pressed.connect(func(): hero_selected.emit(id)); column.add_child(choose)
		row.add_child(card)
	_add_back(hero_screen)

func _build_map() -> void:
	map_screen = _screen("CARTE DU MONDE", "Six régions reliées par l'océan.")
	var grid := GridContainer.new(); grid.columns = 3; grid.position = Vector2(220, 240); grid.size = Vector2(1480, 650); grid.add_theme_constant_override("h_separation", 30); grid.add_theme_constant_override("v_separation", 30); map_screen.add_child(grid)
	var names := ["PORT DES NAUFRAGÉS", "JUNGLE SAUVAGE", "ROYAUME DES NEIGES", "DÉSERT DES CORSAIRES", "ÎLE VOLCANIQUE", "FORTERESSE DE LA TEMPÊTE"]
	var colors := [GREEN, Color("26704a"), Color("78aaca"), Color("bd813e"), RED, Color("485d78")]
	for i in range(names.size()):
		var button := _button(str(i + 1) + "  •  " + names[i], colors[i], 170); button.custom_minimum_size = Vector2(450, 170); button.pressed.connect(func(): zone_selected.emit(i)); grid.add_child(button)
	_add_back(map_screen)

func _build_gallery(bosses: bool) -> Control:
	var screen := _screen("TOUS LES BOSS" if bosses else "TOUS LES ENNEMIS", "Galerie complète des adversaires.")
	var scroll := ScrollContainer.new(); scroll.position = Vector2(120, 210); scroll.size = Vector2(1680, 720); screen.add_child(scroll)
	var grid := GridContainer.new(); grid.columns = 3 if bosses else 4; grid.add_theme_constant_override("h_separation", 22); grid.add_theme_constant_override("v_separation", 22); scroll.add_child(grid)
	var profiles := EnemyFactory.BOSSES if bosses else EnemyFactory.ENEMIES
	for profile in profiles:
		var panel := PanelContainer.new(); panel.custom_minimum_size = Vector2(500 if bosses else 380, 230); panel.add_theme_stylebox_override("panel", _style(PANEL, Color(profile["color"]), 22, 3))
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; panel.add_child(column)
		var icon := Label.new(); icon.text = "☠" if bosses else "⚔"; icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 68); icon.add_theme_color_override("font_color", Color(profile["color"]).lightened(0.25)); column.add_child(icon)
		var label := Label.new(); label.text = String(profile["name"]).to_upper(); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size", 21); label.add_theme_color_override("font_color", GOLD_LIGHT); column.add_child(label)
		var stats := Label.new(); stats.text = "VIE %d  •  PUISSANCE %d" % [int(profile["health"]), int(profile["damage"])]; stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(stats)
		grid.add_child(panel)
	_add_back(screen)
	return screen

func _build_training() -> void:
	training_screen = _screen("ENTRAÎNEMENT ET MAÎTRISE", "Améliore toute la famille.")
	training_info = Label.new(); training_info.position = Vector2(200, 185); training_info.size = Vector2(1520, 55); training_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; training_info.add_theme_font_size_override("font_size", 26); training_info.add_theme_color_override("font_color", GOLD_LIGHT); training_screen.add_child(training_info)
	var row := HBoxContainer.new(); row.position = Vector2(165, 300); row.size = Vector2(1590, 470); row.add_theme_constant_override("separation", 35); training_screen.add_child(row)
	for data in [["force","FORCE",RED,"⚔"],["vitesse","VITESSE",BLUE,"⚡"],["energie","ÉNERGIE",GREEN,"✦"]]:
		var panel := PanelContainer.new(); panel.custom_minimum_size = Vector2(500, 420); panel.add_theme_stylebox_override("panel", _style(PANEL, Color(data[2]), 26, 4))
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; panel.add_child(column)
		var icon := Label.new(); icon.text = String(data[3]); icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 100); icon.add_theme_color_override("font_color", Color(data[2])); column.add_child(icon)
		var title := Label.new(); title.text = String(data[1]); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 38); column.add_child(title)
		var button := _button("S'ENTRAÎNER", Color(data[2]), 72); var stat_name := String(data[0]); button.pressed.connect(func(): training_requested.emit(stat_name)); column.add_child(button)
		row.add_child(panel)
	_add_back(training_screen)

func _build_settings() -> void:
	settings_screen = _screen("PARAMÈTRES", "Réglages adaptés au téléphone Android.")
	var column := VBoxContainer.new(); column.position = Vector2(560, 300); column.size = Vector2(800, 420); column.add_theme_constant_override("separation", 25); settings_screen.add_child(column)
	voice_button = _button("VOIX FRANÇAISE : ACTIVÉE", BLUE, 80); voice_button.pressed.connect(func(): voice_enabled = not voice_enabled; set_voice(voice_enabled); voice_toggled.emit(voice_enabled)); column.add_child(voice_button)
	var label := Label.new(); label.text = "QUALITÉ GRAPHIQUE : ÉLEVÉE\nMode paysage • sauvegarde locale • fonctionnement hors connexion"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 25); column.add_child(label)
	_add_back(settings_screen)

func _screen(title_text: String, subtitle: String) -> Control:
	var screen := Control.new(); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(screen); screens.append(screen)
	var background := TextureRect.new(); background.texture = EmbeddedArt.interface_texture(); background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(background)
	var shade := ColorRect.new(); shade.color = Color(0,0,0,0.44); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(shade)
	var title := Label.new(); title.text = title_text; title.position = Vector2(80, 50); title.size = Vector2(1760, 80); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 58); title.add_theme_color_override("font_color", GOLD_LIGHT); screen.add_child(title)
	var sub := Label.new(); sub.text = subtitle; sub.position = Vector2(150, 130); sub.size = Vector2(1620, 50); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sub.add_theme_font_size_override("font_size", 22); screen.add_child(sub)
	return screen

func _add_back(screen: Control) -> void:
	var back := _button("RETOUR", Color("243b52"), 62); back.position = Vector2(45, 35); back.size = Vector2(150, 62); back.pressed.connect(show_main); screen.add_child(back)
func _show(target: Control) -> void:
	for screen in screens: screen.hide()
	target.show()
func _button(text: String, color: Color, height: float) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = height; button.add_theme_font_size_override("font_size", 24); button.add_theme_stylebox_override("normal", _style(Color(color,0.88), GOLD, 16, 2)); button.add_theme_stylebox_override("pressed", _style(color.darkened(0.28), GOLD_LIGHT, 16, 4)); return button
func _style(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.set_corner_radius_all(radius); style.content_margin_left = 20; style.content_margin_right = 20; style.content_margin_top = 12; style.content_margin_bottom = 12; return style
