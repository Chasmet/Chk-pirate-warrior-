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
