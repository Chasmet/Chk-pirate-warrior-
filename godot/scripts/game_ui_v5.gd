class_name GameUIV5
extends GameUIV4

signal manual_save_requested

var save_feedback: Label
var crew_status_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu = MenuUIV4.new()
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
	_build_v5_controls()
	_build_pause()
	_build_game_over()
	show_main_menu()

func _build_v5_controls() -> void:
	# Le bouton sauvegarde est placé immédiatement à gauche de PAUSE.
	for child in hud.get_children():
		if child is Button and String((child as Button).text) == "CARTE":
			_set_rect(child as Control, 1.0, 0.0, 1.0, 0.0, -355, 18, 105, 68)
	var save_button := _small_button("SAUVEG.")
	save_button.name = "BoutonSauvegardeExacteV5"
	_set_rect(save_button, 1.0, 0.0, 1.0, 0.0, -240, 18, 105, 68)
	save_button.pressed.connect(func(): manual_save_requested.emit())
	hud.add_child(save_button)

	save_feedback = Label.new()
	save_feedback.name = "ConfirmationSauvegardeV5"
	_set_rect(save_feedback, 1.0, 0.0, 1.0, 0.0, -510, 94, 490, 38)
	save_feedback.text = ""
	save_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_feedback.add_theme_font_size_override("font_size", 19)
	save_feedback.add_theme_color_override("font_color", Color("8ff0ae"))
	save_feedback.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	save_feedback.add_theme_constant_override("shadow_offset_x", 2)
	save_feedback.add_theme_constant_override("shadow_offset_y", 2)
	save_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(save_feedback)

	crew_status_label = Label.new()
	crew_status_label.name = "RelationsÉquipagesV5"
	_set_rect(crew_status_label, 0.5, 0.0, 0.5, 0.0, -560, 232, 1120, 38)
	crew_status_label.text = "RENCONTRES LIBRES • ÉQUIPAGES EN MER"
	crew_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crew_status_label.add_theme_font_size_override("font_size", 18)
	crew_status_label.add_theme_color_override("font_color", Color("d7e7ef"))
	crew_status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	crew_status_label.add_theme_constant_override("shadow_offset_x", 2)
	crew_status_label.add_theme_constant_override("shadow_offset_y", 2)
	crew_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(crew_status_label)

func show_save_feedback(position: Vector3, boat_mode: bool) -> void:
	if not is_instance_valid(save_feedback):
		return
	var place := "EN MER" if boat_mode else "SUR L’ÎLE"
	save_feedback.text = "SAUVEGARDE V5 RÉUSSIE • %s • X%d Z%d" % [place, roundi(position.x), roundi(position.z)]
	save_feedback.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(save_feedback, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func():
		if is_instance_valid(save_feedback):
			save_feedback.text = ""
			save_feedback.modulate.a = 1.0
	)

func update_crew_status(text: String) -> void:
	if is_instance_valid(crew_status_label):
		crew_status_label.text = text
