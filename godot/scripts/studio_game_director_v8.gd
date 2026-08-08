extends "res://scripts/studio_game_director_v4.gd"

# La finition studio conserve le sillage et les silhouettes, mais ne déplace
# plus le héros : PlayerControllerV8 et QuinetHeroAnimatorV8 sont les seules
# autorités du poste de pilotage.
func _update_boat_runtime(_delta: float) -> void:
	if not is_instance_valid(player.boat_visual):
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
	var ratio := clampf(absf(player.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	if is_instance_valid(wake_root):
		wake_root.visible = ratio > 0.04
		wake_root.scale.z = lerpf(0.35, 1.55, ratio)
		for material in wake_materials:
			material.albedo_color = Color(0.78, 0.95, 1.0, lerpf(0.0, 0.66, ratio))
