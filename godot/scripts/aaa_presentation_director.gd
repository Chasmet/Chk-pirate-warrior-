extends Node

# Passe de présentation non destructive : caméra, étalonnage, impacts et
# introductions de boss. Tous les systèmes de déplacement, combat, bateau et
# sauvegarde restent pilotés par leurs scripts d'origine.

const OVERLAY_SHADER := preload("res://shaders/aaa_cinematic_overlay.gdshader")
const ZONE_GRADES := [
	{"brightness":1.02, "contrast":1.08, "saturation":1.06},
	{"brightness":1.01, "contrast":1.07, "saturation":1.13},
	{"brightness":1.05, "contrast":1.05, "saturation":0.92},
	{"brightness":1.04, "contrast":1.09, "saturation":1.04},
	{"brightness":0.98, "contrast":1.15, "saturation":0.94},
	{"brightness":0.96, "contrast":1.14, "saturation":0.82}
]

var player: PlayerController
var world: GameWorld
var environment: Environment
var overlay_layer: CanvasLayer
var overlay: ColorRect
var overlay_material: ShaderMaterial
var hit_marker: Label
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_phase_label: Label
var enemy_health: Dictionary = {}
var announced_bosses: Dictionary = {}
var scan_timer := 0.0
var elapsed_time := 0.0
var previous_health := 0.0
var previous_skill_cooldown := 0.0
var damage_flash := 0.0
var skill_flash := 0.0
var camera_kick := 0.0
var current_zone := -1
var target_brightness := 1.0
var target_contrast := 1.0
var target_saturation := 1.0
var ready_logged := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1900
	set_process(true)
	call_deferred("_build_overlay")

func _process(delta: float) -> void:
	elapsed_time += delta
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.08
		_resolve_runtime()
		_scan_enemies()

	if is_instance_valid(player):
		_detect_player_feedback()
		_update_camera_polish(delta)
	_update_environment(delta)
	_update_overlay(delta)

func _resolve_runtime() -> void:
	if not is_instance_valid(player):
		var candidate := get_tree().root.find_child("ÉquipageQuinet", true, false)
		if candidate is PlayerController:
			player = candidate as PlayerController
			previous_health = player.health
			previous_skill_cooldown = player.skill_cooldown
			current_zone = -1
			if not ready_logged:
				ready_logged = true
				print("CHK_AAA_PRESENTATION_READY world_hero=1 impacts=1 boss_intro=1")

	if is_instance_valid(player):
		var parent := player.get_parent()
		if parent is GameWorld:
			world = parent as GameWorld
		else:
			world = null
	else:
		world = null

	if is_instance_valid(world) and is_instance_valid(world.visuals):
		environment = world.visuals.environment
		if current_zone != world.current_zone:
			current_zone = world.current_zone
			_apply_zone_grade(current_zone)
	else:
		environment = null

	if not is_instance_valid(overlay_layer):
		_build_overlay()

func _detect_player_feedback() -> void:
	if previous_health <= 0.0:
		previous_health = player.health
	if player.health < previous_health - 0.01:
		var damage := previous_health - player.health
		var ratio := damage / maxf(player.max_health, 1.0)
		damage_flash = maxf(damage_flash, clampf(0.20 + ratio * 5.0, 0.20, 1.0))
		camera_kick = maxf(camera_kick, clampf(0.22 + ratio * 4.0, 0.22, 0.90))
	previous_health = player.health

	if player.skill_cooldown > previous_skill_cooldown + 0.35:
		skill_flash = 1.0
		camera_kick = maxf(camera_kick, 0.72)
	previous_skill_cooldown = player.skill_cooldown

func _scan_enemies() -> void:
	if not is_instance_valid(player):
		enemy_health.clear()
		return
	var active_ids: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node is EnemyAI:
			continue
		var enemy := node as EnemyAI
		if not is_instance_valid(enemy):
			continue
		var instance_id := enemy.get_instance_id()
		active_ids[instance_id] = true
		var current_health := enemy.health
		if enemy_health.has(instance_id):
			var old_health := float(enemy_health[instance_id])
			if current_health < old_health - 0.01:
				var lost := old_health - current_health
				var strong := enemy.boss or lost >= enemy.max_health * 0.18
				_show_hit_marker(enemy.profile.get("accent", enemy.profile.get("color", Color.WHITE)), strong)
				camera_kick = maxf(camera_kick, 0.46 if strong else 0.18)
		enemy_health[instance_id] = current_health
		if enemy.boss:
			var boss_id := String(enemy.profile.get("id", str(instance_id)))
			if not announced_bosses.has(boss_id):
				announced_bosses[boss_id] = true
				_show_boss_intro(String(enemy.profile.get("name", "BOSS")))
	for stored_id in enemy_health.keys():
		if not active_ids.has(stored_id):
			enemy_health.erase(stored_id)

func _update_camera_polish(delta: float) -> void:
	if not is_instance_valid(player.camera):
		return
	var speed_ratio := 0.0
	if player.boat_mode:
		speed_ratio = clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	else:
		var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
		speed_ratio = clampf(horizontal_speed / maxf(player._movement_speed(), 0.1), 0.0, 1.0)

	var sway_speed := 2.1 if player.boat_mode else lerpf(3.2, 10.2, speed_ratio)
	var lateral_sway := sin(elapsed_time * sway_speed) * (0.012 if player.boat_mode else 0.018) * speed_ratio
	var vertical_sway := absf(sin(elapsed_time * sway_speed * 1.85)) * 0.014 * speed_ratio
	if player.boat_mode:
		vertical_sway += sin(elapsed_time * 1.55) * (0.012 + player.sea_state * 0.025)

	var local_velocity := player.global_transform.basis.inverse() * player.velocity
	var turn_roll := clampf(-local_velocity.x * (0.0018 if player.boat_mode else 0.0028), -0.020, 0.020)
	var target_roll := turn_roll + sin(elapsed_time * sway_speed) * 0.004 * speed_ratio
	player.camera.h_offset = lerpf(player.camera.h_offset, lateral_sway, 1.0 - exp(-7.0 * delta))
	player.camera.v_offset = lerpf(player.camera.v_offset, vertical_sway + camera_kick * 0.035, 1.0 - exp(-9.0 * delta))
	player.camera.rotation.z = lerp_angle(player.camera.rotation.z, target_roll, 1.0 - exp(-8.5 * delta))
	camera_kick = move_toward(camera_kick, 0.0, delta * 3.8)

func _apply_zone_grade(zone_index: int) -> void:
	var grade: Dictionary = ZONE_GRADES[clampi(zone_index, 0, ZONE_GRADES.size() - 1)]
	target_brightness = float(grade["brightness"])
	target_contrast = float(grade["contrast"])
	target_saturation = float(grade["saturation"])

func _update_environment(delta: float) -> void:
	if not is_instance_valid(environment):
		return
	environment.adjustment_enabled = true
	environment.adjustment_brightness = lerpf(environment.adjustment_brightness, target_brightness, 1.0 - exp(-1.4 * delta))
	environment.adjustment_contrast = lerpf(environment.adjustment_contrast, target_contrast, 1.0 - exp(-1.4 * delta))
	environment.adjustment_saturation = lerpf(environment.adjustment_saturation, target_saturation, 1.0 - exp(-1.4 * delta))

func _build_overlay() -> void:
	if is_instance_valid(overlay_layer):
		return
	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "PrésentationAAA"
	overlay_layer.layer = 94
	add_child(overlay_layer)

	overlay = ColorRect.new()
	overlay.name = "VoileCinématique"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = OVERLAY_SHADER
	overlay.material = overlay_material
	overlay_layer.add_child(overlay)

	hit_marker = Label.new()
	hit_marker.name = "ConfirmationImpact"
	hit_marker.text = "✕"
	hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hit_marker.add_theme_font_size_override("font_size", 42)
	hit_marker.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	hit_marker.add_theme_constant_override("shadow_offset_x", 2)
	hit_marker.add_theme_constant_override("shadow_offset_y", 2)
	hit_marker.anchor_left = 0.5
	hit_marker.anchor_top = 0.5
	hit_marker.anchor_right = 0.5
	hit_marker.anchor_bottom = 0.5
	hit_marker.offset_left = -34.0
	hit_marker.offset_top = -34.0
	hit_marker.offset_right = 34.0
	hit_marker.offset_bottom = 34.0
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_marker.hide()
	overlay_layer.add_child(hit_marker)

	boss_panel = PanelContainer.new()
	boss_panel.name = "IntroductionBoss"
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -360.0
	boss_panel.offset_right = 360.0
	boss_panel.offset_top = 74.0
	boss_panel.offset_bottom = 174.0
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.018, 0.024, 0.034, 0.93)
	panel_style.border_color = Color("d6a63d")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	boss_panel.add_theme_stylebox_override("panel", panel_style)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_panel.add_child(box)
	boss_phase_label = Label.new()
	boss_phase_label.text = "MENACE MAJEURE • PHASE I"
	boss_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_phase_label.add_theme_font_size_override("font_size", 16)
	boss_phase_label.add_theme_color_override("font_color", Color("efc95b"))
	box.add_child(boss_phase_label)
	boss_name_label = Label.new()
	boss_name_label.text = "BOSS"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 30)
	boss_name_label.add_theme_color_override("font_color", Color("fff3d0"))
	boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(boss_name_label)
	boss_panel.modulate.a = 0.0
	boss_panel.hide()
	overlay_layer.add_child(boss_panel)

func _update_overlay(delta: float) -> void:
	damage_flash = move_toward(damage_flash, 0.0, delta * 2.8)
	skill_flash = move_toward(skill_flash, 0.0, delta * 2.2)
	if overlay_material == null:
		return
	var active := is_instance_valid(world) and world.visible and is_instance_valid(player)
	overlay.visible = active
	var health_ratio := player.health / maxf(player.max_health, 1.0) if active else 1.0
	var low_health := clampf((0.42 - health_ratio) / 0.30, 0.0, 1.0)
	overlay_material.set_shader_parameter("vignette_strength", 0.19 if active else 0.0)
	overlay_material.set_shader_parameter("damage_strength", damage_flash if active else 0.0)
	overlay_material.set_shader_parameter("low_health", low_health if active else 0.0)
	overlay_material.set_shader_parameter("skill_flash", skill_flash if active else 0.0)
	overlay_material.set_shader_parameter("pulse_time", elapsed_time)

func _show_hit_marker(color_value: Variant, strong: bool) -> void:
	if not is_instance_valid(hit_marker):
		return
	var color: Color = color_value if color_value is Color else Color.WHITE
	hit_marker.text = "✦" if strong else "✕"
	hit_marker.modulate = color.lightened(0.28)
	hit_marker.modulate.a = 1.0
	hit_marker.scale = Vector2.ONE * (0.72 if strong else 0.88)
	hit_marker.show()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hit_marker, "scale", Vector2.ONE * (1.28 if strong else 1.08), 0.16)
	tween.tween_property(hit_marker, "modulate:a", 0.0, 0.20)
	tween.chain().tween_callback(func():
		if is_instance_valid(hit_marker):
			hit_marker.hide()
	)

func _show_boss_intro(display_name: String) -> void:
	if not is_instance_valid(boss_panel):
		return
	boss_name_label.text = display_name.to_upper()
	boss_panel.modulate.a = 0.0
	boss_panel.scale = Vector2(0.92, 0.92)
	boss_panel.show()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(boss_panel, "modulate:a", 1.0, 0.24)
	tween.tween_property(boss_panel, "scale", Vector2.ONE, 0.28)
	tween.chain().tween_interval(1.75)
	tween.tween_property(boss_panel, "modulate:a", 0.0, 0.46)
	tween.tween_callback(func():
		if is_instance_valid(boss_panel):
			boss_panel.hide()
	)
