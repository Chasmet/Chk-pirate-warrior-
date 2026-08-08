class_name GeneralPolishDirectorV6
extends Node3D

const CHARACTER_SCAN_INTERVAL := 1.35
const MAX_ANIMATED_SPRITES := 72

var world: GameWorldV5
var player: PlayerController
var visuals: WorldVisualsV5
var fill_light: DirectionalLight3D
var animated_sprites: Array[Sprite3D] = []
var animated_owners: Dictionary = {}
var scan_timer := 0.0
var local_time := 0.0

func configure(target_world: GameWorldV5, target_player: PlayerController, target_visuals: WorldVisualsV5) -> void:
	world = target_world
	player = target_player
	visuals = target_visuals
	_build_fill_light()
	_upgrade_environment()
	_scan_animated_characters()
	set_meta("general_polish_v6", true)
	print("CHK_V6_GENERAL_POLISH_READY lighting=true characters=true physics=true")

func _process(delta: float) -> void:
	local_time += delta
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = CHARACTER_SCAN_INTERVAL
		_scan_animated_characters()
	_update_lighting(delta)
	_update_character_motion(delta)

func _build_fill_light() -> void:
	fill_light = DirectionalLight3D.new()
	fill_light.name = "LumièreRemplissageV6"
	fill_light.rotation_degrees = Vector3(-34.0, 142.0, 0.0)
	fill_light.light_color = Color("85bdf0")
	fill_light.light_energy = 0.30
	fill_light.shadow_enabled = false
	fill_light.directional_sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(fill_light)

func _upgrade_environment() -> void:
	if not is_instance_valid(visuals) or visuals.environment == null:
		return
	var environment := visuals.environment
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.035
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.09
	environment.ambient_light_sky_contribution = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.08
	environment.tonemap_white = 2.25
	environment.fog_height = 0.0
	environment.fog_height_density = 0.016
	environment.fog_aerial_perspective = 0.32
	environment.glow_enabled = true
	environment.glow_intensity = 0.82
	environment.glow_bloom = 0.16
	environment.glow_hdr_threshold = 1.15
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		environment.ssao_enabled = true
		environment.ssao_radius = 2.2
		environment.ssao_intensity = 1.35
		environment.ssil_enabled = true
		environment.ssil_radius = 4.0
		environment.ssil_intensity = 0.72

func _update_lighting(delta: float) -> void:
	if not is_instance_valid(fill_light) or not is_instance_valid(visuals):
		return
	var daylight := clampf((sin(visuals.day_time * TAU) + 0.12) / 1.12, 0.025, 1.0)
	var storm := 1.0 if visuals.current_weather == "tempête" else 0.55 if visuals.current_weather in ["pluie", "cendres", "neige"] else 0.0
	var target_energy := (0.10 + daylight * 0.28) * lerpf(1.0, 0.62, storm)
	fill_light.light_energy = lerpf(fill_light.light_energy, target_energy, 1.0 - exp(-1.6 * delta))
	var night_color := Color("668dc5")
	var day_color := Color("a9d3f5")
	fill_light.light_color = fill_light.light_color.lerp(night_color.lerp(day_color, daylight), 1.0 - exp(-1.1 * delta))
	if visuals.environment != null:
		var ambient_target := (0.24 + daylight * 0.62) * lerpf(1.0, 0.72, storm)
		visuals.environment.ambient_light_energy = lerpf(visuals.environment.ambient_light_energy, ambient_target, 1.0 - exp(-1.4 * delta))

func _scan_animated_characters() -> void:
	animated_sprites.clear()
	animated_owners.clear()
	var groups := ["enemies", "roster_25d", "crew_allies", "crew_neutral"]
	var seen: Dictionary = {}
	for group_name in groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if animated_sprites.size() >= MAX_ANIMATED_SPRITES:
				return
			if not is_instance_valid(node) or node is MobileCrewMemberV6:
				continue
			var sprite := _find_sprite(node)
			if sprite == null or seen.has(sprite.get_instance_id()):
				continue
			seen[sprite.get_instance_id()] = true
			if not sprite.has_meta("base_y_v6"):
				sprite.set_meta("base_y_v6", sprite.position.y)
				sprite.set_meta("phase_v6", float(abs(String(node.name).hash()) % 1000) * 0.013)
			animated_sprites.append(sprite)
			var owner := _find_character_owner(sprite)
			if owner != null:
				animated_owners[sprite.get_instance_id()] = owner
			node.set_meta("animated_character_v6", true)

func _update_character_motion(delta: float) -> void:
	for sprite in animated_sprites:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree():
			continue
		var owner: CharacterBody3D = animated_owners.get(sprite.get_instance_id()) as CharacterBody3D
		var speed_ratio := 0.0
		var velocity_x := 0.0
		if is_instance_valid(owner):
			speed_ratio = clampf(Vector2(owner.velocity.x, owner.velocity.z).length() / 4.2, 0.0, 1.4)
			velocity_x = owner.velocity.x
		var phase := float(sprite.get_meta("phase_v6", 0.0))
		var base_y := float(sprite.get_meta("base_y_v6", sprite.position.y))
		var bob := absf(sin(local_time * (6.4 + speed_ratio * 2.0) + phase)) * 0.048 * speed_ratio
		var breathe := sin(local_time * 2.1 + phase) * 0.012 if speed_ratio < 0.12 else 0.0
		sprite.position.y = lerpf(sprite.position.y, base_y + bob + breathe, 1.0 - exp(-10.0 * delta))
		var lean := clampf(-velocity_x * 0.012, -0.075, 0.075)
		sprite.rotation.z = lerpf(sprite.rotation.z, lean, 1.0 - exp(-7.0 * delta))
		if absf(velocity_x) > 0.22:
			sprite.flip_h = velocity_x < 0.0

func _find_character_owner(node: Node) -> CharacterBody3D:
	var current := node.get_parent()
	while current != null and not current is CharacterBody3D:
		current = current.get_parent()
	return current as CharacterBody3D

func _find_sprite(node: Node) -> Sprite3D:
	for child in node.get_children():
		if child is Sprite3D:
			return child as Sprite3D
		var found := _find_sprite(child)
		if found != null:
			return found
	return null
