class_name GameUIV4
extends GameUI

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
	_build_pause()
	_build_game_over()
	show_main_menu()
