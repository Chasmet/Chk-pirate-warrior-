class_name GameUIV11
extends GameUIV5

var finale_feedback: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu = MenuUIV11.new()
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
	_build_v11_feedback()
	_build_pause()
	_build_game_over()
	show_main_menu()

func _build_v11_feedback() -> void:
	finale_feedback = Label.new()
	finale_feedback.name = "FinaleFeedbackV11"
	_set_rect(finale_feedback, 0.5, 0.0, 0.5, 0.0, -580, 286, 1160, 84)
	finale_feedback.text = ""
	finale_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finale_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finale_feedback.add_theme_font_size_override("font_size", 28)
	finale_feedback.add_theme_color_override("font_color", Color("ffe39a"))
	finale_feedback.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.98))
	finale_feedback.add_theme_constant_override("shadow_offset_x", 3)
	finale_feedback.add_theme_constant_override("shadow_offset_y", 3)
	finale_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(finale_feedback)

func show_final_region_feedback(active: bool) -> void:
	if not is_instance_valid(finale_feedback):
		return
	if not active:
		finale_feedback.text = ""
		return
	finale_feedback.text = "ROYAUME TROUBLÉ • AUCUN HABITANT • AUCUNE FAUNE • RETROUVE LE CŒUR DES SOUVENIRS"
	finale_feedback.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(4.2)
	tween.tween_property(finale_feedback, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		if is_instance_valid(finale_feedback):
			finale_feedback.text = ""
			finale_feedback.modulate.a = 1.0
	)

func show_final_relic_feedback(relic_name: String) -> void:
	if not is_instance_valid(finale_feedback):
		return
	finale_feedback.text = "AVENTURE TERMINÉE • %s OBTENU • EXPLORATION LIBRE DÉBLOQUÉE" % relic_name.to_upper()
	finale_feedback.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(finale_feedback, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(finale_feedback):
			finale_feedback.text = ""
			finale_feedback.modulate.a = 1.0
	)
