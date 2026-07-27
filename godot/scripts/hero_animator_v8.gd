class_name QuinetHeroAnimatorV8
extends QuinetHeroAnimator

# Animation bateau alignée sur le poste de pilotage V8. Elle ajoute le roulis
# et la respiration autour de la position du gouvernail au lieu de ramener le
# héros vers l'origine du joueur.
func _update_boat_pose(visual: CharacterBody3D, delta: float) -> void:
	var speed_ratio := clampf(absf(controller.boat_speed) / PlayerController.BOAT_MAX_SPEED, 0.0, 1.0)
	var turn_ratio := clampf(controller.boat_turn_rate / 1.8, -1.0, 1.0)
	var sea_roll := sin(animation_time * (1.6 + speed_ratio * 1.2)) * (0.010 + controller.sea_state * 0.018)
	var base_position := PlayerControllerV8.BOAT_HELM_POSITION_V8 if controller is PlayerControllerV8 else Vector3(0.0, 0.72, 1.48)
	var target_position := base_position + Vector3(0.0, sin(animation_time * 2.6) * 0.008, 0.0)
	var target_rotation := Vector3(-speed_ratio * 0.035, 0.0, -turn_ratio * 0.075 + sea_roll)
	var target_scale := Vector3.ONE * PlayerControllerV8.BOAT_HERO_SCALE_V8 if controller is PlayerControllerV8 else Vector3.ONE
	var blend := 1.0 - exp(-7.5 * delta)
	visual.position = visual.position.lerp(target_position, blend)
	visual.rotation = visual.rotation.lerp(target_rotation, blend)
	visual.scale = visual.scale.lerp(target_scale, 1.0 - exp(-8.0 * delta))
	var pilot_sprite := visual.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if pilot_sprite != null:
		pilot_sprite.position.y = lerpf(pilot_sprite.position.y, float(HeroFactory.HEROES[controller.hero_id]["sprite_y"]) + sin(animation_time * 2.6) * 0.008, blend)
		pilot_sprite.rotation.z = lerpf(pilot_sprite.rotation.z, -turn_ratio * 0.035, blend)
		pilot_sprite.scale = pilot_sprite.scale.lerp(Vector3.ONE, blend)
		pilot_sprite.modulate = pilot_sprite.modulate.lerp(Color.WHITE, blend)
		pilot_sprite.flip_h = turn_ratio > 0.10
		pilot_sprite.render_priority = 10
