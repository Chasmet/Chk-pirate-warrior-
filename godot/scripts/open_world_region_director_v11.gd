class_name OpenWorldRegionDirectorV11
extends OpenWorldRegionDirectorV9

signal final_relic_collected(relic_name: String)

var final_relic: Area3D
var final_relic_visual: Node3D
var final_relic_taken := false
var final_region_root: Node3D

func configure(world_reference: Node3D, player_reference: Node3D, visuals_reference: Node3D) -> void:
	world = world_reference
	player = player_reference
	visuals = visuals_reference
	regions = RegionCatalogV11.all_regions()
	var validation_errors := RegionCatalogV11.validate()
	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error("V11 CATALOGUE : " + error)
		return
	_build_region_roots()
	_build_distant_simulation()
	_build_region_hud()
	_build_final_region_atmosphere()
	_build_final_relic()
	_set_active_region(_region_from_core_zone(int(world.get("current_zone"))), false)
	set_process(true)
	set_meta("open_world_regions_v11", true)
	set_meta("eleven_authored_regions_v11", true)
	set_meta("abandoned_final_kingdom_v11", true)
	set_meta("final_rare_item_v11", true)
	print("CHK_V11_REGION_DIRECTOR_READY regions=%d living_npc=%d final=%s" % [regions.size(), RegionCatalogV11.TOTAL_NPCS, String(RegionCatalogV11.FINAL_REGION["name"])])

func _process(delta: float) -> void:
	super._process(delta)
	_update_final_relic(delta)

func simulated_npc_count() -> int:
	return max(0, RegionCatalogV11.TOTAL_NPCS - active_citizens.size())

func _build_distant_simulation() -> void:
	distant_states.clear()
	for region_index in range(regions.size()):
		var npc_count := RegionCatalogV11.npc_count_for_region(region_index)
		for npc_index in range(npc_count):
			var profile := RegionCatalogV11.npc_profile(region_index, npc_index)
			distant_states[String(profile["id"])] = {
				"region":region_index,
				"npc_index":npc_index,
				"state":"sommeil",
				"hour":world_hour,
				"weather":current_weather
			}

func _spawn_active_population() -> void:
	for citizen in active_citizens:
		if is_instance_valid(citizen):
			citizen.queue_free()
	active_citizens.clear()
	if active_region < 0 or RegionCatalogV11.is_final_region(active_region):
		population_changed.emit(0, simulated_npc_count())
		return
	var data: Dictionary = regions[active_region]
	var center: Vector3 = data["center"]
	var pois: Array = data["pois"]
	var route: Array[Vector3] = []
	for poi_value in pois:
		var poi: Dictionary = poi_value
		var position: Vector3 = center + Vector3(poi["offset"])
		position.y += 4.0
		route.append(position)
	for npc_index in range(RegionCatalogV11.npc_count_for_region(active_region)):
		var citizen := AmbientCitizenV11.new()
		add_child(citizen)
		citizen.configure(RegionCatalogV11.npc_profile(active_region, npc_index), route, player)
		citizen.set_world_context(world_hour, current_weather)
		active_citizens.append(citizen)

func _update_distant_simulation() -> void:
	for npc_id in distant_states.keys():
		var state: Dictionary = distant_states[npc_id]
		var region_index := int(state["region"])
		var npc_index := int(state.get("npc_index", 0))
		if region_index == active_region:
			state["state"] = "simulation_active"
		else:
			state["state"] = _routine_state_for_profile(RegionCatalogV11.npc_profile(region_index, npc_index), world_hour, current_weather)
		state["hour"] = world_hour
		state["weather"] = current_weather
		distant_states[npc_id] = state

func _update_status_text() -> void:
	if not is_instance_valid(region_status) or active_region < 0:
		return
	if RegionCatalogV11.is_final_region(active_region):
		var relic_state := "OBJET RARE TROUVÉ" if final_relic_taken else "CHERCHE LE CŒUR DES SOUVENIRS"
		region_status.text = "BRUME DORÉE • AUCUN HABITANT • AUCUNE FAUNE • " + relic_state
		return
	super._update_status_text()

func _build_final_region_atmosphere() -> void:
	if region_roots.size() <= RegionCatalogV11.FINAL_REGION_INDEX:
		return
	final_region_root = region_roots[RegionCatalogV11.FINAL_REGION_INDEX]
	var accent := Color(String(RegionCatalogV11.FINAL_REGION["accent"]))
	for index in range(28):
		var fragment := MeshInstance3D.new()
		fragment.name = "FragmentMémoire_%02d" % index
		var mesh := BoxMesh.new()
		var scale_value := 0.22 + float(index % 5) * 0.08
		mesh.size = Vector3(scale_value, 0.55 + float(index % 4) * 0.18, scale_value * 0.65)
		fragment.mesh = mesh
		var angle := TAU * float(index) / 28.0
		var radius := 48.0 + float((index * 37) % 190)
		fragment.position = Vector3(cos(angle) * radius, 7.0 + float((index * 11) % 34), sin(angle) * radius)
		fragment.rotation = Vector3(angle * 0.17, angle, angle * 0.08)
		var material := StandardMaterial3D.new()
		material.albedo_color = accent.lightened(float(index % 4) * 0.07)
		material.emission_enabled = true
		material.emission = accent
		material.emission_energy_multiplier = 2.1
		material.roughness = 0.28
		fragment.material_override = material
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fragment.visibility_range_end = 260.0
		final_region_root.add_child(fragment)

	# Cercles de brume stylisés très transparents, compatibles mobile.
	for index in range(9):
		var mist := MeshInstance3D.new()
		mist.name = "VoileDoré_%02d" % index
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 34.0 + float(index) * 22.0
		cylinder.bottom_radius = cylinder.top_radius * 1.03
		cylinder.height = 0.18
		cylinder.radial_segments = 32
		mist.mesh = cylinder
		mist.position.y = 0.45 + float(index % 3) * 0.42
		var mist_material := StandardMaterial3D.new()
		mist_material.albedo_color = Color(accent, 0.055 + float(index % 2) * 0.025)
		mist_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mist_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mist.material_override = mist_material
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		final_region_root.add_child(mist)

func _build_final_relic() -> void:
	final_relic = Area3D.new()
	final_relic.name = "CoeurDesSouvenirsV11"
	final_relic.global_position = RegionCatalogV11.final_relic_position()
	add_child(final_relic)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.4
	collision.shape = shape
	final_relic.add_child(collision)

	final_relic_visual = Node3D.new()
	final_relic_visual.name = "ReliqueVisible"
	final_relic.add_child(final_relic_visual)
	var crystal := MeshInstance3D.new()
	var crystal_mesh := CylinderMesh.new()
	crystal_mesh.top_radius = 0.18
	crystal_mesh.bottom_radius = 0.72
	crystal_mesh.height = 2.25
	crystal_mesh.radial_segments = 6
	crystal.mesh = crystal_mesh
	crystal.rotation.x = deg_to_rad(18.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd76a")
	material.emission_enabled = true
	material.emission = Color("ffbd35")
	material.emission_energy_multiplier = 3.4
	material.metallic = 0.22
	material.roughness = 0.20
	crystal.material_override = material
	final_relic_visual.add_child(crystal)
	var halo := OmniLight3D.new()
	halo.name = "LueurRelique"
	halo.light_color = Color("ffd56a")
	halo.light_energy = 2.2
	halo.omni_range = 9.0
	halo.shadow_enabled = false
	final_relic_visual.add_child(halo)
	var label := Label3D.new()
	label.text = "CŒUR DES SOUVENIRS"
	label.position = Vector3(0.0, 2.1, 0.0)
	label.font_size = 34
	label.outline_size = 8
	label.modulate = Color("ffe69b")
	label.outline_modulate = Color(0.02, 0.02, 0.02, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	final_relic_visual.add_child(label)

func _update_final_relic(delta: float) -> void:
	if final_relic_taken or not is_instance_valid(final_relic) or not is_instance_valid(player):
		return
	if is_instance_valid(final_relic_visual):
		final_relic_visual.rotation.y += delta * 0.72
		final_relic_visual.position.y = 0.32 + sin(Time.get_ticks_msec() * 0.0023) * 0.18
	if active_region != RegionCatalogV11.FINAL_REGION_INDEX:
		return
	if player.global_position.distance_to(final_relic.global_position) <= 3.6:
		final_relic_taken = true
		final_relic.visible = false
		final_relic.monitoring = false
		final_relic_collected.emit(String(RegionCatalogV11.FINAL_REGION["rare_item"]))
		if is_instance_valid(region_banner):
			region_banner.text = "FIN DE L’AVENTURE\nCŒUR DES SOUVENIRS OBTENU"
			region_banner.modulate.a = 1.0
		VoiceFR.speak("Tu as retrouvé le Cœur des Souvenirs. L’archipel se souviendra de ton équipage.")
		Input.vibrate_handheld(180)
		print("CHK_V11_FINAL_RELIC_COLLECTED")

func mark_final_relic_collected() -> void:
	final_relic_taken = true
	if is_instance_valid(final_relic):
		final_relic.visible = false
		final_relic.monitoring = false

func _build_landmark_mesh(parent: StaticBody3D, kind: String, base_color: Color, accent_color: Color, variant: int) -> void:
	if kind not in ["porte_flottante", "palais", "horloge", "bibliotheque", "miroir", "fragment_memoire", "sanctuaire"]:
		super._build_landmark_mesh(parent, kind, base_color, accent_color, variant)
		return
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ArchitectureTroubléeV11"
	var size := Vector3(7.0, 7.0, 5.0)
	match kind:
		"horloge":
			var clock := CylinderMesh.new()
			clock.top_radius = 4.6
			clock.bottom_radius = 4.6
			clock.height = 0.8
			clock.radial_segments = 24
			mesh_instance.mesh = clock
			mesh_instance.rotation.x = deg_to_rad(90.0)
			size = Vector3(9.2, 9.2, 1.2)
		"miroir":
			var mirror := BoxMesh.new()
			mirror.size = Vector3(6.8, 8.6, 0.35)
			mesh_instance.mesh = mirror
			size = mirror.size
		"porte_flottante":
			var door := TorusMesh.new()
			door.inner_radius = 2.6
			door.outer_radius = 4.1
			door.rings = 18
			door.ring_segments = 10
			mesh_instance.mesh = door
			mesh_instance.rotation.x = deg_to_rad(90.0)
			size = Vector3(8.2, 8.2, 1.6)
		"fragment_memoire":
			var shard := BoxMesh.new()
			shard.size = Vector3(2.4, 6.8, 1.4)
			mesh_instance.mesh = shard
			mesh_instance.rotation = Vector3(0.22, 0.65, 0.28)
			size = shard.size
		_:
			var building := BoxMesh.new()
			building.size = Vector3(9.0 + float(variant % 2) * 3.0, 7.0 + float(variant % 3) * 2.0, 7.0 + float((variant + 1) % 2) * 2.0)
			mesh_instance.mesh = building
			size = building.size
	mesh_instance.position.y = maxf(1.0, size.y * 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color.lerp(accent_color, 0.38)
	material.emission_enabled = true
	material.emission = accent_color.darkened(0.16)
	material.emission_energy_multiplier = 0.55
	material.roughness = 0.72
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.visibility_range_end = 285.0
	parent.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(1.0, size.x * 0.78), maxf(1.0, size.y), maxf(1.0, size.z * 0.78))
	collision.shape = shape
	collision.position = mesh_instance.position
	parent.add_child(collision)
