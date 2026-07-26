class_name MenuUIV4
extends MenuUI

const ZONE_NAMES_V4 := [
	"PORT DES\nNAUFRAGÉS", "JUNGLE\nSAUVAGE", "ROYAUME\nDES NEIGES",
	"DÉSERT DES\nCORSAIRES", "ÎLE\nVOLCANIQUE", "FORTERESSE\nDE LA TEMPÊTE",
	"ÎLE DES\nGÂTEAUX", "CITADELLE\nDU CRÂNE", "ROYAUME\nCÉLESTE"
]
const ZONE_COLORS_V4 := [
	Color("446a73"), Color("26704a"), Color("78aaca"), Color("bd813e"), Color("a82e2c"), Color("485d78"),
	Color("d97fa8"), Color("5d2925"), Color("76bfe8")
]
const ZONE_DESCRIPTIONS_V4 := [
	"Quais, navires et premier capitaine",
	"Cascades, végétation et créatures",
	"Glace, blizzard et traces dans la neige",
	"Ruines, chaleur et sable",
	"Lave, cendres et Général Volkan",
	"Orages, forteresse et Amiral Vorga",
	"Ville pâtissière, caramel et pirates des délices",
	"Forteresse-crâne, magma et armée des cornes",
	"Palais suspendu, cascades célestes et anciens de l’éther"
]

func _build_main() -> void:
	super._build_main()
	var world_map := _button("CARTE DU MONDE • 9 ÎLES", Color("2d789f"), 64, 23)
	world_map.name = "BoutonCarteNeufÎles"
	world_map.position = Vector2(754, 770)
	world_map.size = Vector2(420, 64)
	world_map.pressed.connect(func(): show_map(false))
	main_menu.add_child(world_map)

func set_unlocked_zones(value: Array) -> void:
	unlocked_zones = value.duplicate()
	for index in range(map_buttons.size()):
		var button := map_buttons[index]
		if not is_instance_valid(button):
			continue
		var status := "DÉBLOQUÉE" if unlocked_zones.has(index) else "À DÉCOUVRIR EN BATEAU"
		button.text = str(index + 1) + "  •  " + String(ZONE_NAMES_V4[index]).replace("\n", " ") + "\n" + ZONE_DESCRIPTIONS_V4[index] + "\n" + status

func _build_map() -> void:
	map_screen = _screen("CARTE DU MONDE", "Neuf grandes régions 3D reliées par un océan continu et accessibles en bateau.")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 132)
	scroll.size = Vector2(1760, 690)
	map_screen.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size = Vector2(1700, 980)
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	for i in range(ZONE_NAMES_V4.size()):
		var zone_name := String(ZONE_NAMES_V4[i]).replace("\n", " ")
		var status := "DÉBLOQUÉE" if unlocked_zones.has(i) else "À DÉCOUVRIR EN BATEAU"
		var zone := _button(str(i + 1) + "  •  " + zone_name + "\n" + ZONE_DESCRIPTIONS_V4[i] + "\n" + status, ZONE_COLORS_V4[i], 300, 22)
		zone.custom_minimum_size = Vector2(535, 295)
		zone.pressed.connect(_emit_zone.bind(i))
		grid.add_child(zone)
		map_buttons.append(zone)
	_add_map_back()

func _build_gallery(is_bosses: bool) -> Control:
	if not is_bosses:
		return super._build_gallery(false)
	var screen := _screen("TOUS LES BOSS", "Les neuf Boss officiels de l’archipel.")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 135)
	scroll.size = Vector2(1780, 700)
	screen.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	for zone_index in range(Enemy25DCatalog.ISLANDS.size()):
		var profile := Enemy25DCatalog.boss_for_zone(zone_index)
		var color: Color = profile["color"]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(565, 250)
		card.add_theme_stylebox_override("panel", _style(PANEL, color, 22, 3))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		box.add_child(_title("☠", 64, color.lightened(0.25)))
		box.add_child(_title(String(profile["name"]).to_upper(), 23))
		box.add_child(_title("ÎLE %d   •   VIE %d   •   PUISSANCE %d" % [zone_index + 1, int(profile["health"]), int(profile["damage"])], 16, Color("d6dde2")))
		grid.add_child(card)
	_add_back(screen)
	return screen
