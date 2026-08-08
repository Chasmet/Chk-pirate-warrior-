class_name AmbientCitizenV11
extends AmbientCitizenV9

var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var walk_phase := 0.0
var visual_root: Node3D

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HabitantStyliséV11"
	add_child(visual_root)

	var identity_seed := abs(String(profile.get("id", "habitant")).hash())
	var region_index := int(profile.get("region", 0))
	base_color = Color(String(profile.get("color", "d7c6a5"))).darkened(float(region_index % 3) * 0.04)
	var cloth_secondary := base_color.darkened(0.26)
	var cloth_detail := base_color.lightened(0.18)
	var skin_palette := [Color("8c5b3d"), Color("b97850"), Color("d19a72"), Color("e3b58b"), Color("7a4a33")]
	var skin: Color = skin_palette[identity_seed % skin_palette.size()]
	var hair_palette := [Color("171513"), Color("35251c"), Color("5b3a24"), Color("81705f"), Color("c5b59a")]
	var hair: Color = hair_palette[(identity_seed / 7) % hair_palette.size()]

	# Torse avec épaules lisibles : on abandonne la capsule monobloc de la V9.
	body_mesh = _box_part("Torse", Vector3(0.70, 0.88, 0.38), base_color)
	body_mesh.position = Vector3(0.0, 1.22, 0.0)
	visual_root.add_child(body_mesh)
	var belt := _box_part("Ceinture", Vector3(0.73, 0.11, 0.40), cloth_secondary)
	belt.position = Vector3(0.0, 0.83, 0.0)
	visual_root.add_child(belt)
	var chest_detail := _box_part("DétailVêtement", Vector3(0.12, 0.58, 0.405), cloth_detail)
	chest_detail.position = Vector3(0.0, 1.23, -0.01)
	visual_root.add_child(chest_detail)

	# Tête, cheveux et nez donnent une vraie direction au regard.
	var head := _sphere_part("Tête", 0.25, skin)
	head.position = Vector3(0.0, 1.91, 0.0)
	visual_root.add_child(head)
	var hair_mesh := _sphere_part("Cheveux", 0.255, hair)
	hair_mesh.scale = Vector3(1.02, 0.55, 1.02)
	hair_mesh.position = Vector3(0.0, 2.035, 0.01)
	visual_root.add_child(hair_mesh)
	var nose := _box_part("Nez", Vector3(0.07, 0.08, 0.09), skin.darkened(0.04))
	nose.position = Vector3(0.0, 1.91, -0.255)
	visual_root.add_child(nose)

	left_arm_pivot = _limb_pivot("BrasGauche", Vector3(-0.46, 1.54, 0.0), 0.14, 0.72, cloth_secondary)
	right_arm_pivot = _limb_pivot("BrasDroit", Vector3(0.46, 1.54, 0.0), 0.14, 0.72, cloth_secondary)
	left_leg_pivot = _limb_pivot("JambeGauche", Vector3(-0.20, 0.78, 0.0), 0.16, 0.82, cloth_secondary.darkened(0.10))
	right_leg_pivot = _limb_pivot("JambeDroite", Vector3(0.20, 0.78, 0.0), 0.16, 0.82, cloth_secondary.darkened(0.10))
	visual_root.add_child(left_arm_pivot)
	visual_root.add_child(right_arm_pivot)
	visual_root.add_child(left_leg_pivot)
	visual_root.add_child(right_leg_pivot)

	# Accessoire simple dépendant du métier pour éviter 20 clones visuels par région.
	_build_job_accessory(String(profile.get("job", "habitant")), identity_seed, cloth_detail, hair)

	name_label = Label3D.new()
	name_label.name = "Nom"
	name_label.text = "%s • %s" % [String(profile.get("name", "Habitant")), String(profile.get("job", "habitant"))]
	name_label.position = Vector3(0.0, 2.38, 0.0)
	name_label.font_size = 32
	name_label.outline_size = 7
	name_label.modulate = Color("f6f1df")
	name_label.outline_modulate = Color(0.02, 0.03, 0.04, 0.94)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.visible = false
	add_child(name_label)

	state_label = Label3D.new()
	state_label.name = "ÉtatRoutine"
	state_label.position = Vector3(0.0, 2.13, 0.0)
	state_label.font_size = 22
	state_label.outline_size = 5
	state_label.modulate = Color("a8d6e8")
	state_label.outline_modulate = Color(0.02, 0.03, 0.04, 0.92)
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	state_label.no_depth_test = true
	state_label.visible = false
	add_child(state_label)

	set_meta("humanoid_visual_v11", true)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_animate_humanoid(delta)

func _animate_humanoid(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.22
	if moving:
		walk_phase = fmod(walk_phase + delta * (5.2 + horizontal_speed * 0.65), TAU)
	else:
		walk_phase = lerpf(walk_phase, 0.0, minf(1.0, delta * 4.5))
	var swing := sin(walk_phase) * (0.55 if moving else 0.035)
	if is_instance_valid(left_arm_pivot): left_arm_pivot.rotation.x = swing
	if is_instance_valid(right_arm_pivot): right_arm_pivot.rotation.x = -swing
	if is_instance_valid(left_leg_pivot): left_leg_pivot.rotation.x = -swing * 0.82
	if is_instance_valid(right_leg_pivot): right_leg_pivot.rotation.x = swing * 0.82
	visual_root.position.y = (abs(sin(walk_phase * 2.0)) * 0.035) if moving else sin(Time.get_ticks_msec() * 0.0022) * 0.012

func _box_part(part_name: String, size: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = _material(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	part.visibility_range_end = 125.0
	part.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return part

func _sphere_part(part_name: String, radius: float, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 7
	part.mesh = mesh
	part.material_override = _material(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	part.visibility_range_end = 125.0
	part.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return part

func _limb_pivot(part_name: String, origin: Vector3, radius: float, length: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = origin
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	mesh.rings = 4
	part.mesh = mesh
	part.position.y = -length * 0.38
	part.material_override = _material(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	part.visibility_range_end = 125.0
	pivot.add_child(part)
	return pivot

func _build_job_accessory(job: String, identity_seed: int, accent: Color, hair: Color) -> void:
	var lower_job := job.to_lower()
	if "garde" in lower_job or "marin" in lower_job or "pêche" in lower_job or identity_seed % 5 == 0:
		var hat := MeshInstance3D.new()
		hat.name = "CouvreChef"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.27
		mesh.bottom_radius = 0.31
		mesh.height = 0.12
		mesh.radial_segments = 12
		hat.mesh = mesh
		hat.position = Vector3(0.0, 2.17, 0.0)
		hat.material_override = _material(accent.darkened(0.12))
		visual_root.add_child(hat)
	elif "forger" in lower_job or "mine" in lower_job or "artisan" in lower_job:
		var apron := _box_part("Tablier", Vector3(0.52, 0.64, 0.08), Color("5b4638"))
		apron.position = Vector3(0.0, 1.12, -0.22)
		visual_root.add_child(apron)
	elif identity_seed % 3 == 0:
		var scarf := _box_part("Écharpe", Vector3(0.57, 0.12, 0.42), hair.lightened(0.12))
		scarf.position = Vector3(0.0, 1.67, 0.0)
		visual_root.add_child(scarf)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.metallic = 0.0
	return material
