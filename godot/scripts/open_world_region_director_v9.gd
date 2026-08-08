class_name OpenWorldRegionDirectorV9
extends Node3D

signal region_entered(region_index: int, region_name: String)
signal population_changed(active_count: int, simulated_count: int)

const UPDATE_INTERVAL := 0.35
const MAX_VISIBLE_REGION_ROOTS := 3
const REGION_ACTIVATION_FACTOR := 1.28

var world: Node3D
var player: Node3D
var visuals: Node3D
var regions: Array = []
var region_roots: Array[Node3D] = []
var active_citizens: Array[AmbientCitizenV9] = []
var distant_states: Dictionary = {}
var active_region := -1
var forced_region_for_test := -1
var update_timer := 0.0
var world_hour := 8.0
var current_weather := "soleil"
var banner_layer: CanvasLayer
var region_banner: Label
var region_status: Label

func configure(world_reference: Node3D, player_reference: Node3D, visuals_reference: Node3D) -> void:
	world = world_reference
	player = player_reference
	visuals = visuals_reference
	regions = RegionCatalogV9.all_regions()
	var validation_errors := RegionCatalogV9.validate()
	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error("V9 CATALOGUE : " + error)
		return
	_build_region_roots()
	_build_distant_simulation()
	_build_region_hud()
	_set_active_region(_region_from_core_zone(int(world.get("current_zone"))), false)
	set_process(true)
	set_meta("open_world_regions_v9", true)
	set_meta("manual_region_layouts_v9", true)
	set_meta("npc_distant_simulation_v9", true)
	print("CHK_V9_REGION_DIRECTOR_READY regions=%d npc_profiles=%d active_limit=%d" % [regions.size(), RegionCatalogV9.TOTAL_NPCS, RegionCatalogV9.NPCS_PER_REGION])

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	update_timer -= delta
	if update_timer > 0.0:
		return
	update_timer = UPDATE_INTERVAL
	_sync_environment_context()
	var detected := forced_region_for_test if forced_region_for_test >= 0 else _detect_region(player.global_position)
	if detected != active_region:
		_set_active_region(detected, true)
	_update_visible_regions()
	_update_active_citizens()
	_update_distant_simulation()
	_update_status_text()

func set_core_zone(core_zone: int) -> void:
	if forced_region_for_test >= 0:
		return
	_set_active_region(_region_from_core_zone(core_zone), true)

func force_region_for_test(region_index: int) -> void:
	forced_region_for_test = clampi(region_index, 0, regions.size() - 1)
	_set_active_region(forced_region_for_test, false)

func clear_test_region_override() -> void:
	forced_region_for_test = -1

func run_update_for_test() -> void:
	_sync_environment_context()
	_update_visible_regions()
	_update_active_citizens()
	_update_distant_simulation()

func region_count() -> int:
	return regions.size()

func active_npc_count() -> int:
	return active_citizens.size()

func simulated_npc_count() -> int:
	return max(0, RegionCatalogV9.TOTAL_NPCS - active_citizens.size())

func visible_region_root_count() -> int:
	var count := 0
	for root_node in region_roots:
		if is_instance_valid(root_node) and root_node.visible:
			count += 1
	return count

func current_region_name() -> String:
	if active_region < 0 or active_region >= regions.size():
		return "Océan"
	return String((regions[active_region] as Dictionary)["name"])

func _build_region_roots() -> void:
	for index in range(regions.size()):
		var data: Dictionary = regions[index]
		var root_node := Node3D.new()
		root_node.name = "RégionV9_%02d_%s" % [index, String(data["id"])]
		root_node.position = Vector3(data["center"])
		root_node.visible = false
		root_node.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(root_node)
		region_roots.append(root_node)
		_build_authored_landmarks(root_node, data, index)
		if index == 5:
			_build_marsh_foundation(root_node, data)

func _build_authored_landmarks(root_node: Node3D, data: Dictionary, region_index: int) -> void:
	var pois: Array = data["pois"]
	var base_color := Color(String(data["color"]))
	var accent_color := Color(String(data["accent"]))
	for poi_index in range(pois.size()):
		var poi: Dictionary = pois[poi_index]
		var landmark := StaticBody3D.new()
		landmark.name = "POI_%02d_%s" % [poi_index, String(poi["name"]).to_snake_case()]
		landmark.position = Vector3(poi["offset"])
		landmark.set_meta("poi_name", String(poi["name"]))
		landmark.set_meta("poi_kind", String(poi["kind"]))
		landmark.set_meta("region_index", region_index)
		root_node.add_child(landmark)
		_build_landmark_mesh(landmark, String(poi["kind"]), base_color, accent_color, poi_index)
		var label := Label3D.new()
		label.name = "NomDuLieu"
		label.text = String(poi["name"])
		label.position = Vector3(0.0, 7.0, 0.0)
		label.font_size = 28
		label.outline_size = 6
		label.modulate = accent_color.lightened(0.18)
		label.outline_modulate = Color(0.01, 0.02, 0.03, 0.94)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.visibility_range_end = 82.0
		landmark.add_child(label)
	for connection_index in range(pois.size() - 1):
		var start: Vector3 = (pois[connection_index] as Dictionary)["offset"]
		var finish: Vector3 = (pois[connection_index + 1] as Dictionary)["offset"]
		_build_path_segment(root_node, start, finish, base_color.lightened(0.08), connection_index)

func _build_landmark_mesh(parent: StaticBody3D, kind: String, base_color: Color, accent_color: Color, variant: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "VolumeVisible"
	var size := Vector3(6.0, 5.0, 6.0)
	if kind in ["phare", "tour", "grue", "sommet", "volcan"]:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 1.6 + float(variant % 2) * 0.5
		cylinder.bottom_radius = 2.8 + float(variant % 3) * 0.35
		cylinder.height = 9.0 + float(variant % 4) * 2.0
		cylinder.radial_segments = 12
		mesh_instance.mesh = cylinder
		size = Vector3(cylinder.bottom_radius * 2.0, cylinder.height, cylinder.bottom_radius * 2.0)
	elif kind in ["pont", "ponton", "quai", "passage", "ruisseau", "lave"]:
		var bridge := BoxMesh.new()
		bridge.size = Vector3(10.0 + float(variant % 3) * 4.0, 0.65, 3.4)
		mesh_instance.mesh = bridge
		size = bridge.size
	elif kind in ["grotte", "mine", "tunnel", "crypte", "egouts", "donjon"]:
		var cave := TorusMesh.new()
		cave.inner_radius = 2.0
		cave.outer_radius = 3.4
		cave.rings = 12
		cave.ring_segments = 8
		mesh_instance.mesh = cave
		mesh_instance.rotation.x = deg_to_rad(90.0)
		size = Vector3(6.8, 5.0, 2.2)
	elif kind in ["arbre", "belvedere", "statue", "colonnes"]:
		var pillar := CylinderMesh.new()
		pillar.top_radius = 1.1
		pillar.bottom_radius = 1.45
		pillar.height = 7.0
		pillar.radial_segments = 10
		mesh_instance.mesh = pillar
		size = Vector3(2.9, 7.0, 2.9)
	else:
		var building := BoxMesh.new()
		building.size = Vector3(6.0 + float(variant % 3) * 1.8, 4.0 + float(variant % 4), 5.0 + float((variant + 1) % 3) * 1.5)
		mesh_instance.mesh = building
		size = building.size
	mesh_instance.position.y = maxf(0.35, size.y * 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color.lerp(accent_color, 0.22 + float(variant % 4) * 0.10)
	material.roughness = 0.86
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.visibility_range_end = 245.0
	mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mesh_instance)
	if kind not in ["ruisseau", "lave", "bassin", "oasis", "lac_gele"]:
		var collision := CollisionShape3D.new()
		collision.name = "CollisionLieu"
		var shape := BoxShape3D.new()
		shape.size = Vector3(maxf(1.0, size.x * 0.82), maxf(1.0, size.y), maxf(1.0, size.z * 0.82))
		collision.shape = shape
		collision.position = mesh_instance.position
		parent.add_child(collision)

func _build_path_segment(root_node: Node3D, start: Vector3, finish: Vector3, color: Color, index: int) -> void:
	var flat_start := Vector3(start.x, start.y + 0.12, start.z)
	var flat_finish := Vector3(finish.x, finish.y + 0.12, finish.z)
	var delta := flat_finish - flat_start
	var length := delta.length()
	if length < 2.0:
		return
	var segment := MeshInstance3D.new()
	segment.name = "CheminManuel_%02d" % index
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.2, 0.18, length)
	segment.mesh = mesh
	segment.position = (flat_start + flat_finish) * 0.5
	segment.look_at_from_position(segment.position, flat_finish, Vector3.UP)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	segment.material_override = material
	segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	segment.visibility_range_end = 185.0
	root_node.add_child(segment)

func _build_marsh_foundation(root_node: Node3D, data: Dictionary) -> void:
	# Le marais est la dixième implantation physique ajoutée à l’archipel V8.
	# Ses îlots et passerelles ont des positions fixes afin de rester reproductibles.
	var pads := [
		Vector4(-104, -76, 42, 1.4), Vector4(126, -132, 34, 1.1), Vector4(188, 92, 38, 1.0),
		Vector4(-164, 142, 44, 1.6), Vector4(28, 44, 52, 0.8), Vector4(-214, -18, 31, 1.2),
		Vector4(72, 198, 40, 1.5), Vector4(218, -38, 35, 0.9), Vector4(-12, -190, 30, 1.3)
	]
	for pad_index in range(pads.size()):
		var pad: Vector4 = pads[pad_index]
		var body := StaticBody3D.new()
		body.name = "ÎlotMarais_%02d" % pad_index
		body.position = Vector3(pad.x, pad.w - 1.0, pad.y)
		root_node.add_child(body)
		var mesh_instance := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = pad.z
		cylinder.bottom_radius = pad.z * 1.08
		cylinder.height = maxf(1.0, pad.w * 2.0)
		cylinder.radial_segments = 20
		mesh_instance.mesh = cylinder
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(String(data["color"])).darkened(0.12 + float(pad_index % 3) * 0.04)
		material.roughness = 0.98
		mesh_instance.material_override = material
		body.add_child(mesh_instance)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = pad.z
		shape.height = maxf(1.0, pad.w * 2.0)
		collision.shape = shape
		body.add_child(collision)

func _build_distant_simulation() -> void:
	distant_states.clear()
	for region_index in range(regions.size()):
		for npc_index in range(RegionCatalogV9.NPCS_PER_REGION):
			var profile := RegionCatalogV9.npc_profile(region_index, npc_index)
			distant_states[String(profile["id"])] = {
				"region":region_index,
				"state":"sommeil",
				"hour":world_hour,
				"weather":current_weather
			}

func _build_region_hud() -> void:
	banner_layer = CanvasLayer.new()
	banner_layer.name = "InterfaceRégionsV9"
	banner_layer.layer = 34
	add_child(banner_layer)
	region_banner = Label.new()
	region_banner.name = "BannièreRégion"
	region_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	region_banner.offset_top = 98.0
	region_banner.offset_bottom = 152.0
	region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_banner.add_theme_font_size_override("font_size", 32)
	region_banner.add_theme_color_override("font_color", Color("f8f3df"))
	region_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.96))
	region_banner.add_theme_constant_override("shadow_offset_x", 3)
	region_banner.add_theme_constant_override("shadow_offset_y", 3)
	region_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_layer.add_child(region_banner)
	region_status = Label.new()
	region_status.name = "ÉtatRégion"
	region_status.position = Vector2(20.0, 134.0)
	region_status.size = Vector2(560.0, 52.0)
	region_status.add_theme_font_size_override("font_size", 18)
	region_status.add_theme_color_override("font_color", Color("d9e8ef"))
	region_status.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	region_status.add_theme_constant_override("shadow_offset_x", 2)
	region_status.add_theme_constant_override("shadow_offset_y", 2)
	region_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_layer.add_child(region_status)

func _set_active_region(index: int, announce: bool) -> void:
	var resolved := clampi(index, 0, regions.size() - 1)
	if resolved == active_region and not active_citizens.is_empty():
		return
	active_region = resolved
	_update_visible_regions()
	_spawn_active_population()
	var data: Dictionary = regions[active_region]
	if is_instance_valid(region_banner):
		region_banner.text = "%s\n%s" % [String(data["name"]).to_upper(), String(data["subtitle"])]
		region_banner.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(2.4)
		tween.tween_property(region_banner, "modulate:a", 0.18, 0.8)
	if announce:
		VoiceFR.speak("Entrée dans la région : " + String(data["name"]) + ".")
	region_entered.emit(active_region, String(data["name"]))
	population_changed.emit(active_citizens.size(), simulated_npc_count())
	print("CHK_V9_REGION_ENTERED index=%d name=%s active_npc=%d simulated=%d" % [active_region, String(data["name"]), active_citizens.size(), simulated_npc_count()])

func _spawn_active_population() -> void:
	for citizen in active_citizens:
		if is_instance_valid(citizen):
			citizen.queue_free()
	active_citizens.clear()
	var data: Dictionary = regions[active_region]
	var center: Vector3 = data["center"]
	var pois: Array = data["pois"]
	var route: Array[Vector3] = []
	for poi_value in pois:
		var poi: Dictionary = poi_value
		var position: Vector3 = center + Vector3(poi["offset"])
		position.y += 4.0
		route.append(position)
	for npc_index in range(RegionCatalogV9.NPCS_PER_REGION):
		var citizen := AmbientCitizenV9.new()
		add_child(citizen)
		citizen.configure(RegionCatalogV9.npc_profile(active_region, npc_index), route, player)
		citizen.set_world_context(world_hour, current_weather)
		active_citizens.append(citizen)

func _update_visible_regions() -> void:
	if active_region < 0:
		return
	var ranked: Array = []
	for index in range(regions.size()):
		var center: Vector3 = (regions[index] as Dictionary)["center"]
		ranked.append({"index":index, "distance":player.global_position.distance_squared_to(center) if is_instance_valid(player) else float(index)})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["distance"]) < float(b["distance"]))
	var visible_indices := [active_region]
	for entry_value in ranked:
		if visible_indices.size() >= MAX_VISIBLE_REGION_ROOTS:
			break
		var entry: Dictionary = entry_value
		var candidate := int(entry["index"])
		if not visible_indices.has(candidate):
			visible_indices.append(candidate)
	for index in range(region_roots.size()):
		var root_node := region_roots[index]
		var should_be_visible := visible_indices.has(index)
		root_node.visible = should_be_visible
		root_node.process_mode = Node.PROCESS_MODE_INHERIT if should_be_visible else Node.PROCESS_MODE_DISABLED

func _update_active_citizens() -> void:
	for citizen in active_citizens:
		if is_instance_valid(citizen):
			citizen.set_world_context(world_hour, current_weather)

func _update_distant_simulation() -> void:
	for npc_id in distant_states.keys():
		var state: Dictionary = distant_states[npc_id]
		var region_index := int(state["region"])
		if region_index == active_region:
			state["state"] = "simulation_active"
		else:
			state["state"] = _routine_state_for_profile(RegionCatalogV9.npc_profile(region_index, int(String(npc_id).right(2))), world_hour, current_weather)
		state["hour"] = world_hour
		state["weather"] = current_weather
		distant_states[npc_id] = state

func _routine_state_for_profile(profile: Dictionary, hour: float, weather: String) -> String:
	if weather in ["tempête", "tempête de cendres", "blizzard", "orage"]:
		return "abri"
	var schedule: Dictionary = profile["schedule"]
	if hour < float(schedule["wake"]) or hour >= float(schedule["sleep"]):
		return "sommeil"
	if hour < float(schedule["work_start"]):
		return "trajet"
	if hour < float(schedule["meal"]):
		return "travail"
	if hour < float(schedule["meal"]) + 1.35:
		return "repas"
	if hour < float(schedule["work_end"]):
		return "travail"
	return "discussion"

func _sync_environment_context() -> void:
	if is_instance_valid(visuals):
		var day_value: Variant = visuals.get("day_time")
		if day_value != null:
			world_hour = fposmod(float(day_value) * 24.0, 24.0)
		else:
			world_hour = fposmod(world_hour + UPDATE_INTERVAL * 0.04, 24.0)
		var weather_value: Variant = visuals.get("current_weather")
		if weather_value != null and not String(weather_value).is_empty():
			current_weather = String(weather_value)
	else:
		world_hour = fposmod(world_hour + UPDATE_INTERVAL * 0.04, 24.0)

func _update_status_text() -> void:
	if not is_instance_valid(region_status) or active_region < 0:
		return
	region_status.text = "%02d:%02d • %s • PNJ proches %d / 20 • simulation distante %d" % [
		int(world_hour), int(fmod(world_hour * 60.0, 60.0)), current_weather.to_upper(), active_citizens.size(), simulated_npc_count()
	]

func _detect_region(position: Vector3) -> int:
	var best_index := _region_from_core_zone(int(world.get("current_zone")))
	var best_distance := INF
	for index in range(regions.size()):
		var data: Dictionary = regions[index]
		var center: Vector3 = data["center"]
		var flat_distance := Vector2(position.x - center.x, position.z - center.z).length()
		if flat_distance < best_distance and flat_distance <= float(data["radius"]) * REGION_ACTIVATION_FACTOR:
			best_distance = flat_distance
			best_index = index
	return best_index

func _region_from_core_zone(core_zone: int) -> int:
	# Les neuf îles V8 restent jouables. Le marais V9 est une implantation
	# supplémentaire située entre la forêt et les montagnes enneigées.
	const CORE_TO_REGION := [0, 1, 9, 6, 4, 2, 3, 8, 7]
	return CORE_TO_REGION[clampi(core_zone, 0, CORE_TO_REGION.size() - 1)]
