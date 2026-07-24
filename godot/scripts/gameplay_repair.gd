extends Node

var player: PlayerController
var cleaned_world_id := 0
var rescue_delay := 0.0
var visual_guard_timer := 0.0

func _ready() -> void:
	process_priority = 1600
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player_recursive(get_tree().root)
		cleaned_world_id = 0
		if not is_instance_valid(player):
			return

	var world := player.get_parent()
	if is_instance_valid(world) and world.get_instance_id() != cleaned_world_id:
		cleaned_world_id = world.get_instance_id()
		_stabilize_world_visuals(world)

	visual_guard_timer -= delta
	if visual_guard_timer <= 0.0 and is_instance_valid(world):
		visual_guard_timer = 1.0
		_disable_unstable_overlays_recursive(world)

	if player.boat_mode:
		rescue_delay = 0.0
		return
	_repair_land_position(delta, world)

func _stabilize_world_visuals(root: Node) -> void:
	_cleanup_recursive(root)
	print("CHK_GAMEPLAY_REPAIR_READY world=%s" % root.name)

func _cleanup_recursive(node: Node) -> void:
	if node is Label3D:
		# Les informations utiles sont déjà présentes dans le HUD et la mini-carte.
		node.queue_free()
		return
	if String(node.name) == "BarreDeVie":
		_disable_enemy_health_bar(node)
		return
	if node is GPUParticles3D:
		# Sur plusieurs pilotes OpenGL Android, les quads de particules étaient
		# rendus comme de grands rectangles blancs. Ils sont coupés jusqu'à leur
		# remplacement par des effets mobiles basés sur des meshes/tweens.
		_disable_particle(node as GPUParticles3D)
	elif node is MultiMeshInstance3D and String(node.name) == "HerbeDense":
		# Le MultiMesh de milliers de quads n'est pas assez fiable sur tous les GPU.
		(node as MultiMeshInstance3D).visible = false
	elif node is GeometryInstance3D:
		var geometry := node as GeometryInstance3D
		var label := String(geometry.name)
		if label in ["Palme", "Feuillage", "SousBois"]:
			_apply_safe_foliage_material(geometry, label)
	for child in node.get_children():
		_cleanup_recursive(child)

func _disable_unstable_overlays_recursive(node: Node) -> void:
	if String(node.name) == "BarreDeVie":
		_disable_enemy_health_bar(node)
		return
	if node is GPUParticles3D:
		_disable_particle(node as GPUParticles3D)
	for child in node.get_children():
		_disable_unstable_overlays_recursive(child)

func _disable_enemy_health_bar(bar: Node) -> void:
	# Les deux QuadMesh de chaque ennemi formaient les paires de panneaux blancs
	# et sombres visibles sur l'île. La cible sera affichée dans une jauge 2D.
	if bar is Node3D:
		(bar as Node3D).visible = false
	bar.process_mode = Node.PROCESS_MODE_DISABLED
	for child in bar.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			geometry.visible = false
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _disable_particle(particles: GPUParticles3D) -> void:
	particles.emitting = false
	particles.visible = false
	particles.process_mode = Node.PROCESS_MODE_DISABLED
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _apply_safe_foliage_material(geometry: GeometryInstance3D, label: String) -> void:
	# Le shader de vent déformait certains meshes sur le rendu mobile. Un
	# matériau standard conserve une végétation propre; le mouvement sera animé
	# au niveau des nœuds plutôt que dans le vertex shader.
	var color := Color("276f3b")
	if label == "Palme":
		color = Color("1f7040")
	elif label == "SousBois":
		color = Color("3f7b3b")
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_BACK
	geometry.material_override = material
	geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geometry.visibility_range_end = minf(geometry.visibility_range_end if geometry.visibility_range_end > 0.0 else 150.0, 150.0)

func _repair_land_position(delta: float, world: Node) -> void:
	if player.global_position.y < -1.0:
		_rescue_to_zone(world)
		return
	if player.global_position.y >= 0.32 or player.is_on_floor():
		rescue_delay = 0.0
		return
	rescue_delay += delta
	if rescue_delay < 0.55:
		return
	rescue_delay = 0.0

	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 18.0,
		player.global_position + Vector3.DOWN * 24.0
	)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var collider := hit.get("collider") as Node
		if is_instance_valid(collider) and String(collider.name).contains("CollisionTerrain"):
			var corrected := player.global_position
			corrected.y = (hit.get("position") as Vector3).y + 1.15
			player.teleport_to_world_position(corrected)
			return
	_rescue_to_zone(world)

func _rescue_to_zone(world: Node) -> void:
	var zone_index := 0
	if is_instance_valid(world):
		var value = world.get("current_zone")
		if value != null:
			zone_index = clampi(int(value), 0, GameWorld.ZONES.size() - 1)
	player.teleport_to_world_position(Vector3(GameWorld.ZONES[zone_index]["spawn"]))
	player.velocity = Vector3.ZERO
	print("CHK_PLAYER_RESCUED zone=%d" % zone_index)

func _find_player_recursive(node: Node) -> PlayerController:
	if node is PlayerController:
		return node as PlayerController
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if is_instance_valid(found):
			return found
	return null
