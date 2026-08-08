extends Node

# Ce directeur ne crée aucun ennemi et ne modifie aucun gameplay.
# Il remplace seulement le modèle procédural du boss déjà généré par GameWorld
# par un Sprite3D utilisant exactement le même principe de rendu que les héros.
const SCAN_INTERVAL := 0.20

var world: GameWorld
var scan_timer := 0.0

func _ready() -> void:
	process_priority = 1250
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(world):
		world = _find_world(get_tree().root)
	scan_timer -= delta
	if scan_timer > 0.0:
		return
	scan_timer = SCAN_INTERVAL
	_apply_visual_to_existing_bosses()

func _apply_visual_to_existing_bosses() -> void:
	for node in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(node) or not node is EnemyAI:
			continue
		var boss := node as EnemyAI
		if not boss.boss or boss.has_meta("boss_25d_visual_attached"):
			continue
		var fallback_zone := world.current_zone if is_instance_valid(world) else 0
		var zone_index := clampi(int(boss.profile.get("zone", fallback_zone)), 0, Enemy25DCatalog.ISLANDS.size() - 1)
		var visual_profile := Enemy25DCatalog.boss_for_zone(zone_index)
		# Le profil du gameplay n'est jamais remplacé : vie, dégâts, IA et collisions
		# restent ceux du boss 3D de la version fonctionnelle.
		if Enemy25DVisual.apply(boss, visual_profile):
			boss.set_meta("boss_25d_visual_attached", true)
			print("CHK_BOSS_HERO_STYLE_READY zone=%d gameplay=%s visual=%s" % [
				zone_index,
				String(boss.profile.get("name", boss.name)),
				String(visual_profile.get("name", "Boss"))
			])

func _find_world(node: Node) -> GameWorld:
	if node is GameWorld:
		return node as GameWorld
	for child in node.get_children():
		var result := _find_world(child)
		if is_instance_valid(result):
			return result
	return null
