class_name QuinetReferenceCharacterEnhancer
extends Node

var controller: PlayerController
var tracked_visual_id: int = 0

func bind(player: PlayerController) -> void:
	controller = player
	set_process(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(controller.hero_visual):
		return
	var visual: CharacterBody3D = controller.hero_visual
	if visual.get_instance_id() == tracked_visual_id:
		return
	tracked_visual_id = visual.get_instance_id()
	_apply_reference_design(visual, controller.hero_id)

func _apply_reference_design(visual: CharacterBody3D, hero_id: String) -> void:
	var rig := visual.get_node_or_null("RigVisuel") as Node3D
	if rig == null:
		return
	for old_node: Node in rig.get_children():
		if String(old_node.name).begins_with("Référence"):
			old_node.queue_free()

	match hero_id:
		"cheikh":
			rig.scale = Vector3(1.18, 1.13, 1.10)
			_build_cheikh(rig)
			QuinetToonStyler.style(visual, true, Color("e2aa42"))
		"yvane":
			rig.scale = Vector3(0.95, 1.07, 0.92)
			_build_yvane(rig)
			QuinetToonStyler.style(visual, true, Color("4ba8e8"))
		_:
			rig.scale = Vector3(0.78, 0.82, 0.78)
			_build_nelvyn(rig)
			QuinetToonStyler.style(visual, true, Color("e8b85b"))

func _build_cheikh(rig: Node3D) -> void:
	_add_box(rig, "RéférenceGiletGauche", Vector3(0.26, 0.76, 0.15), Vector3(-0.25, 1.34, 0.12), Color("17191c"), Vector3(0.0, 0.0, -0.10))
	_add_box(rig, "RéférenceGiletDroit", Vector3(0.26, 0.76, 0.15), Vector3(0.25, 1.34, 0.12), Color("17191c"), Vector3(0.0, 0.0, 0.10))
	_add_box(rig, "RéférenceChemise", Vector3(0.28, 0.66, 0.12), Vector3(0.0, 1.30, 0.18), Color("ede5d7"))
	_add_box(rig, "RéférenceCeintureRouge", Vector3(0.88, 0.20, 0.28), Vector3(0.0, 0.90, 0.0), Color("a52f2b"))
	_add_box(rig, "RéférenceBoucleOr", Vector3(0.25, 0.20, 0.08), Vector3(0.0, 0.91, 0.18), Color("d8a33e"), Vector3.ZERO, 0.55)
	_add_box(rig, "RéférencePagneRouge", Vector3(0.38, 0.82, 0.09), Vector3(0.23, 0.48, 0.15), Color("a92f2c"), Vector3(0.0, 0.0, -0.22))
	_add_beard(rig, Vector3(0.0, 2.18, -0.03), 1.0)
	_add_brows_and_eyes(rig, Vector3(0.0, 2.30, -0.23), 1.0, Color("2c1a12"))
	_add_curved_saber(rig, Vector3(0.67, 0.90, 0.03), 1.15, Color("d7e3ea"))
	_add_arm_wrap(rig, Vector3(0.53, 1.27, 0.0), 1.0)

func _build_yvane(rig: Node3D) -> void:
	_add_box(rig, "RéférenceTeeShirtNoir", Vector3(0.66, 0.76, 0.30), Vector3(0.0, 1.36, 0.0), Color("111317"))
	_add_box(rig, "RéférencePantalonNoir", Vector3(0.66, 0.56, 0.30), Vector3(0.0, 0.66, 0.0), Color("15181d"))
	_add_box(rig, "RéférenceCeintureVerte", Vector3(0.82, 0.18, 0.30), Vector3(0.0, 0.93, 0.0), Color("65752d"))
	_add_box(rig, "RéférenceSangleDiagonale", Vector3(0.10, 1.02, 0.08), Vector3(0.0, 1.48, 0.19), Color("6b452f"), Vector3(0.0, 0.0, -0.52))
	_add_brows_and_eyes(rig, Vector3(0.0, 2.19, -0.22), 0.90, Color("20130d"))
	_add_twist_hair(rig, Vector3(0.0, 2.46, 0.0), 0.88)
	_add_slingshot(rig, Vector3(0.63, 1.18, 0.0), 1.0)
	_add_box(rig, "RéférenceFoulardVert", Vector3(0.45, 0.70, 0.08), Vector3(0.34, 0.58, 0.16), Color("65752d"), Vector3(0.0, 0.0, -0.26))

func _build_nelvyn(rig: Node3D) -> void:
	_add_box(rig, "RéférenceChemiseBlanche", Vector3(0.72, 0.70, 0.28), Vector3(0.0, 1.35, 0.0), Color("eee9dd"))
	_add_box(rig, "RéférenceGiletBleu", Vector3(0.68, 0.62, 0.14), Vector3(0.0, 1.36, 0.17), Color("35566b"))
	_add_box(rig, "RéférenceShortBeige", Vector3(0.74, 0.52, 0.32), Vector3(0.0, 0.68, 0.0), Color("b88447"))
	_add_box(rig, "RéférenceCeintureBrune", Vector3(0.82, 0.16, 0.30), Vector3(0.0, 0.94, 0.0), Color("67412b"))
	_add_box(rig, "RéférenceSacoche", Vector3(0.28, 0.34, 0.17), Vector3(0.42, 0.74, 0.13), Color("70462e"))
	_add_box(rig, "RéférenceSangle", Vector3(0.08, 1.04, 0.07), Vector3(0.0, 1.38, 0.20), Color("7b5034"), Vector3(0.0, 0.0, 0.56))
	_add_brows_and_eyes(rig, Vector3(0.0, 2.18, -0.22), 0.92, Color("281910"))
	_add_short_hair(rig, Vector3(0.0, 2.39, 0.0), 0.92)
	_add_box(rig, "RéférenceBracelet", Vector3(0.18, 0.12, 0.18), Vector3(-0.55, 1.12, 0.0), Color("252a30"))

func _add_beard(root: Node3D, position: Vector3, scale_value: float) -> void:
	var beard := _add_sphere(root, "RéférenceBarbe", Vector3(0.31, 0.25, 0.24) * scale_value, position + Vector3(0.0, -0.08, -0.18), Color("201814"))
	beard.scale = Vector3(1.0, 0.78, 0.52)
	_add_box(root, "RéférenceMoustache", Vector3(0.30, 0.07, 0.06) * scale_value, position + Vector3(0.0, 0.05, -0.31), Color("201814"))

func _add_brows_and_eyes(root: Node3D, center: Vector3, scale_value: float, hair_color: Color) -> void:
	for side in [-1.0, 1.0]:
		_add_sphere(root, "RéférenceŒil", Vector3(0.075, 0.048, 0.032) * scale_value, center + Vector3(side * 0.12, 0.0, 0.0), Color("f7f4ed"))
		_add_sphere(root, "RéférencePupille", Vector3(0.027, 0.027, 0.018) * scale_value, center + Vector3(side * 0.12, 0.0, -0.035), Color("17100d"))
		_add_box(root, "RéférenceSourcil", Vector3(0.14, 0.035, 0.035) * scale_value, center + Vector3(side * 0.12, 0.105, -0.005), hair_color, Vector3(0.0, 0.0, side * -0.10))
	_add_box(root, "RéférenceNez", Vector3(0.07, 0.15, 0.07) * scale_value, center + Vector3(0.0, -0.10, -0.025), Color("8b583b"))
	_add_box(root, "RéférenceBouche", Vector3(0.18, 0.035, 0.025) * scale_value, center + Vector3(0.0, -0.23, -0.015), Color("4b211d"))

func _add_twist_hair(root: Node3D, center: Vector3, scale_value: float) -> void:
	for i in range(13):
		var angle: float = TAU * float(i) / 13.0
		var radius: float = 0.21 + 0.05 * sin(float(i) * 2.1)
		var pos := center + Vector3(cos(angle) * radius, 0.07 + 0.05 * (i % 3), sin(angle) * radius * 0.62)
		var twist := _add_capsule(root, "RéférenceTresse", 0.055 * scale_value, 0.34 * scale_value, pos, Color("171311"))
		twist.rotation_degrees = Vector3(12.0 + float(i % 3) * 8.0, -rad_to_deg(angle), cos(angle) * 18.0)

func _add_short_hair(root: Node3D, center: Vector3, scale_value: float) -> void:
	for x in range(-3, 4):
		for z in range(-2, 3):
			if abs(x) + abs(z) > 4:
				continue
			var curl := _add_sphere(root, "RéférenceBoucle", Vector3.ONE * 0.075 * scale_value, center + Vector3(float(x) * 0.07, 0.03 * abs(z), float(z) * 0.06), Color("181411"))
			curl.scale.y = 1.25

func _add_arm_wrap(root: Node3D, center: Vector3, scale_value: float) -> void:
	for i in range(4):
		_add_box(root, "RéférenceBandage", Vector3(0.20, 0.055, 0.20) * scale_value, center + Vector3(0.0, float(i) * 0.07, 0.0), Color("e8dfcf"))

func _add_curved_saber(root: Node3D, origin: Vector3, scale_value: float, color: Color) -> void:
	_add_box(root, "RéférencePoignéeSabre", Vector3(0.12, 0.52, 0.12) * scale_value, origin, Color("3e261c"), Vector3(0.0, 0.0, -0.58))
	_add_box(root, "RéférenceGardeSabre", Vector3(0.44, 0.08, 0.12) * scale_value, origin + Vector3(-0.15, 0.22, 0.0), Color("c99b42"), Vector3(0.0, 0.0, -0.58), 0.35)
	for i in range(7):
		var t: float = float(i) / 6.0
		var position := origin + Vector3(-0.24 - t * 0.95, 0.36 + t * 0.46 - t * t * 0.18, 0.0)
		_add_box(root, "RéférenceLameSabre", Vector3(0.28, 0.075, 0.055) * scale_value, position, color, Vector3(0.0, 0.0, -0.24 + t * 0.24), 0.24)

func _add_slingshot(root: Node3D, origin: Vector3, scale_value: float) -> void:
	_add_box(root, "RéférenceFrondePoignée", Vector3(0.12, 0.48, 0.12) * scale_value, origin, Color("70462c"), Vector3(0.0, 0.0, -0.22))
	for side in [-1.0, 1.0]:
		_add_box(root, "RéférenceFrondeBranche", Vector3(0.10, 0.42, 0.10) * scale_value, origin + Vector3(side * 0.15, 0.31, 0.0), Color("70462c"), Vector3(0.0, 0.0, side * -0.52))
		_add_box(root, "RéférenceÉlastique", Vector3(0.025, 0.38, 0.025) * scale_value, origin + Vector3(side * 0.10, 0.48, -0.04), Color("24201d"), Vector3(0.0, 0.0, side * 0.28))

func _add_box(root: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, roughness: float = 0.78) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(root, node_name, mesh, position, color, rotation, roughness)

func _add_sphere(root: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var node := _add_mesh(root, node_name, mesh, position, color)
	node.scale = size * 2.0
	return node

func _add_capsule(root: Node3D, node_name: String, radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return _add_mesh(root, node_name, mesh, position, color)

func _add_mesh(root: Node3D, node_name: String, mesh: PrimitiveMesh, position: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, roughness: float = 0.78) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.22 if roughness < 0.40 else 0.02
	node.material_override = material
	root.add_child(node)
	return node
