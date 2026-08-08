extends Node

# Finition visuelle du bateau. Le contrôleur joueur reste désormais l'unique
# autorité de position du héros au gouvernail afin d'éviter les corrections
# contradictoires et les micro-saccades observées sur Android.

var player: PlayerController
var adjusted_boat_id := 0
var check_timer := 0.0
var last_boat_mode := false

func _ready() -> void:
	process_priority = 1950
	process_physics_priority = 1950
	set_process(false)
	set_physics_process(true)
	set_meta("single_pilot_authority_v8", true)

func _physics_process(delta: float) -> void:
	check_timer -= delta
	var mode_changed := is_instance_valid(player) and player.boat_mode != last_boat_mode
	if check_timer > 0.0 and not mode_changed:
		return
	check_timer = 0.25
	_update_presentation()
	if is_instance_valid(player):
		last_boat_mode = player.boat_mode

func _update_presentation() -> void:
	if not is_instance_valid(player):
		player = _find_player(get_tree().root)
		adjusted_boat_id = 0
		if not is_instance_valid(player):
			return

	if is_instance_valid(player.boat_visual):
		var boat_id := player.boat_visual.get_instance_id()
		if boat_id != adjusted_boat_id:
			adjusted_boat_id = boat_id
			_adjust_boat_once(player.boat_visual)

	if not player.boat_mode:
		return

	player.boat_visual.visible = true
	if is_instance_valid(player.hero_visual):
		player.hero_visual.visible = true
		var sprite := player.hero_visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
		if sprite != null:
			sprite.visible = true
			sprite.modulate = Color.WHITE
			sprite.no_depth_test = false
			sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			sprite.render_priority = 10

func _adjust_boat_once(boat: Node3D) -> void:
	var helm_station := boat.get_node_or_null("PosteDePilotage") as Node3D
	if helm_station != null:
		helm_station.position.z = 0.42

	var cabin := boat.get_node_or_null("Cabine") as Node3D
	if cabin != null:
		var body := cabin.get_node_or_null("CorpsCabine") as MeshInstance3D
		if body != null:
			body.scale.y = 0.74
			body.position.y = 1.76
		var roof := cabin.get_node_or_null("ToitCabine") as MeshInstance3D
		if roof != null:
			roof.scale = Vector3(0.92, 0.72, 0.90)
			roof.position.y = 2.58
		for window in cabin.find_children("FenêtreCabine", "MeshInstance3D", false, false):
			(window as MeshInstance3D).position.y = 1.78
		var door := cabin.get_node_or_null("PorteCabine") as MeshInstance3D
		if door != null:
			door.scale.y = 0.78
			door.position.y = 1.64

	var voilure := boat.get_node_or_null("Voilure") as Node3D
	if voilure != null:
		for node in voilure.get_children():
			if not node is Node3D:
				continue
			var part := node as Node3D
			var label := String(part.name)
			if label.begins_with("BandeVoile_"):
				part.position.x *= 0.80
				part.position.y += 1.02
				part.position.z = -1.42
				part.scale = Vector3(part.scale.x * 0.80, part.scale.y * 0.66, part.scale.z)
			elif label == "GrandeVergue":
				part.position.y += 0.82
				part.position.z = -1.36
			elif label == "EmblèmeQuinet":
				part.position.y += 1.02
				part.position.z = -1.47
				part.scale = Vector3.ONE * 0.72
			elif label == "VoileHaute":
				part.position.y += 0.42
				part.scale = Vector3(0.82, 0.72, 1.0)

	var stern := boat.get_node_or_null("Coque/Poupe") as MeshInstance3D
	if stern != null:
		stern.scale = Vector3(0.96, 0.82, 0.80)

	print("CHK_BOAT_PRESENTATION_V8_READY sail_clear=1 pilot_authority=player")

func _find_player(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player(child)
		if is_instance_valid(found):
			return found
	return null
