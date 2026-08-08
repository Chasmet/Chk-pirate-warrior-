class_name MenuUIV11
extends MenuUIV4

const REGION_NAMES_V11 := [
	"VILLAGE CÔTIER", "GRANDE FORÊT", "MONTAGNES ROCHEUSES", "PLAINES AGRICOLES",
	"RÉGION VOLCANIQUE", "MARAIS BRUMEUX", "DÉSERT DE CENDRES", "GRAND PORT COMMERCIAL",
	"RUINES ANTIQUES", "MONTAGNES ENNEIGÉES", "ROYAUME TROUBLÉ"
]
const REGION_SUBTITLES_V11 := [
	"Pêche, marché et falaises marines",
	"Canopée, clairières et ruines végétales",
	"Falaises, mines et villages suspendus",
	"Fermes, moulins et cultures variées",
	"Lave, cendres et anciennes fortifications",
	"Boue, brume et chemins dissimulés",
	"Dunes grises, canyons et tempêtes",
	"Quais actifs, marchés et quartiers contrastés",
	"Temples, mécanismes et galeries souterraines",
	"Glaciers, blizzards et sommet principal",
	"Souvenirs oubliés, brume dorée et objet rare"
]
const REGION_COLORS_V11 := [
	Color("4f9eae"), Color("2f7245"), Color("6e6a62"), Color("88a94d"), Color("7b332c"),
	Color("42584c"), Color("77716b"), Color("355d72"), Color("766a50"), Color("a9c8d8"), Color("8b6a2f")
]
# Inverse du mapping CORE_TO_REGION de la fondation V9. -1 = région d'exploration libre.
const CORE_ZONE_FOR_REGION := [0, 1, 5, 6, 4, -1, 3, 8, 7, 2, -1]

func _build_main() -> void:
	super._build_main()
	var old_map := main_menu.get_node_or_null("BoutonCarteNeufÎles")
	if is_instance_valid(old_map):
		old_map.queue_free()

	var brand := PanelContainer.new()
	brand.name = "BandeauCHKOnzeRoyaumes"
	brand.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brand.offset_left = 410.0
	brand.offset_right = -410.0
	brand.offset_top = 16.0
	brand.offset_bottom = 102.0
	brand.add_theme_stylebox_override("panel", _style(Color(0.008, 0.018, 0.035, 0.94), GOLD, 24, 2))
	main_menu.add_child(brand)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	brand.add_child(row)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/icon_512.png") as Texture2D
	logo.custom_minimum_size = Vector2(68, 68)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(logo)
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(titles)
	titles.add_child(_title("CHK PIRATE WARRIOR", 29, GOLD_LIGHT))
	titles.add_child(_title("L’ARCHIPEL DES ONZE ROYAUMES", 18, Color("d8e6ec")))

	var world_map := _button("CARTE DU MONDE • 11 ROYAUMES", Color("2d789f"), 68, 23)
	world_map.name = "BoutonCarteOnzeRoyaumes"
	world_map.position = Vector2(744, 766)
	world_map.size = Vector2(440, 68)
	world_map.pressed.connect(func(): show_map(false))
	main_menu.add_child(world_map)

func _build_map() -> void:
	map_screen = _screen("CARTE DES ONZE ROYAUMES", "Neuf royaumes majeurs avec quai, un marais à trouver en exploration libre et le Royaume Troublé final.")
	var legend := Label.new()
	legend.position = Vector2(100, 92)
	legend.size = Vector2(1720, 40)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.text = "BLEU : destination par le gouvernail • EXPLORATION : accoste directement en naviguant"
	legend.add_theme_font_size_override("font_size", 18)
	legend.add_theme_color_override("font_color", Color("c9dbe3"))
	map_screen.add_child(legend)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 142)
	scroll.size = Vector2(1780, 680)
	map_screen.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size = Vector2(1710, 1240)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	map_buttons.clear()
	for region_index in range(REGION_NAMES_V11.size()):
		var core_zone := int(CORE_ZONE_FOR_REGION[region_index])
		var card := _button(_region_button_text(region_index), REGION_COLORS_V11[region_index], 285, 20)
		card.name = "RégionV11_%02d" % region_index
		card.custom_minimum_size = Vector2(545, 285)
		if core_zone >= 0:
			card.pressed.connect(_emit_zone.bind(core_zone))
		else:
			card.disabled = true
			card.tooltip_text = "Cette région se découvre en naviguant librement avec le bateau."
		grid.add_child(card)
		map_buttons.append(card)
	_add_map_back()

func set_unlocked_zones(value: Array) -> void:
	unlocked_zones = value.duplicate()
	_refresh_v11_map_buttons()

func _refresh_v11_map_buttons() -> void:
	for region_index in range(map_buttons.size()):
		var button := map_buttons[region_index]
		if not is_instance_valid(button):
			continue
		button.text = _region_button_text(region_index)

func _region_button_text(region_index: int) -> String:
	var core_zone := int(CORE_ZONE_FOR_REGION[region_index])
	var status := ""
	if region_index == RegionCatalogV11.FINAL_REGION_INDEX:
		status = "RÉGION FINALE • REPÈRE LA BRUME DORÉE EN MER"
	elif core_zone < 0:
		status = "EXPLORATION LIBRE • ACCÈS EN NAVIGUANT"
	else:
		status = "DÉBLOQUÉ" if unlocked_zones.has(core_zone) else "À DÉCOUVRIR EN BATEAU"
	return "%02d  •  %s\n%s\n%s" % [region_index + 1, REGION_NAMES_V11[region_index], REGION_SUBTITLES_V11[region_index], status]
