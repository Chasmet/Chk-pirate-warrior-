extends "res://scripts/gameplay_repair.gd"

# Le système de secours historique connaissait seulement six îles. Cette
# variante replace désormais le héros sur l’île active, y compris la
# Citadelle du Crâne et le Royaume Céleste suspendu.
func _repair_land_position(delta: float, world: Node) -> void:
	if not _resolve_player_from_world(world):
		return
	var zone_index := _current_zone_index(world)
	var zone: Dictionary = GameWorldV4.ZONES_V4[zone_index]
	var elevation := float(zone.get("elevation", 0.0))
	var fall_limit := elevation - (18.0 if zone_index == 8 else 4.0)
	if player.global_position.y < fall_limit:
		_rescue_to_zone(world)
		return
	if player.global_position.y >= elevation + 0.32 or player.is_on_floor():
		rescue_delay = 0.0
		return
	rescue_delay += delta
	if rescue_delay < 0.55:
		return
	rescue_delay = 0.0

	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 18.0,
		player.global_position + Vector3.DOWN * 30.0
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
	if not _resolve_player_from_world(world):
		push_warning("Secours V4 impossible : joueur introuvable")
		return
	var zone_index := _current_zone_index(world)
	player.teleport_to_world_position(Vector3(GameWorldV4.ZONES_V4[zone_index]["spawn"]))
	player.velocity = Vector3.ZERO
	print("CHK_PLAYER_RESCUED_V4 zone=%d" % zone_index)

func _resolve_player_from_world(world: Node) -> bool:
	if is_instance_valid(player):
		return true
	if is_instance_valid(world) and world.has_method("get_player"):
		var candidate = world.call("get_player")
		if candidate is PlayerController:
			player = candidate as PlayerController
	return is_instance_valid(player)

func _current_zone_index(world: Node) -> int:
	if is_instance_valid(world):
		var value = world.get("current_zone")
		if value != null:
			return clampi(int(value), 0, GameWorldV4.ZONES_V4.size() - 1)
	return 0
