extends SceneTree

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
	else:
		failures += 1
		push_error("ÉCHEC  " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var target := Node3D.new()
	target.name = "CibleTest"
	root.add_child(target)

	var official_texture := Boss25DEmbeddedAssets.texture_for_zone(0)
	_check(official_texture != null, "l’asset officiel de Brakor est décodé depuis le dépôt")
	if official_texture != null:
		_check(official_texture.get_width() >= 150 and official_texture.get_height() >= 190, "Brakor conserve une définition adaptée au rendu mobile")

	var gameplay_profile := EnemyFactory.boss_for_zone(0).duplicate(true)
	gameplay_profile["difficulty"] = "intermediaire"
	gameplay_profile["zone"] = 0
	var boss := EnemyFactory.create_enemy(gameplay_profile, target)
	root.add_child(boss)

	var original_health := boss.max_health
	var original_damage := boss.attack_damage
	var original_collision := boss.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var visual_profile := Enemy25DCatalog.boss_for_zone(0)
	var applied := Enemy25DVisual.apply(boss, visual_profile)
	var sprite := boss.get_node_or_null("Visual25D/Character25D") as Sprite3D

	_check(applied, "le véritable visuel de Brakor est appliqué au boss existant")
	_check(boss is CharacterBody3D, "Brakor reste un CharacterBody3D dans le monde ouvert")
	_check(original_collision != null and original_collision.shape != null, "la collision 3D de Brakor est conservée")
	_check(is_equal_approx(boss.max_health, original_health), "la vie du boss n'est pas modifiée par son apparence")
	_check(is_equal_approx(boss.attack_damage, original_damage), "les dégâts du boss ne sont pas modifiés par son apparence")
	_check(sprite != null and sprite.texture != null, "Brakor possède un Sprite3D réel")
	if sprite != null:
		_check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "Brakor reste vertical pendant la rotation caméra 360°")
		_check(not sprite.no_depth_test, "Brakor respecte la profondeur du monde 3D")
		var visual_height := float(sprite.texture.get_height()) * sprite.pixel_size
		_check(visual_height >= 2.60 and visual_height <= 3.50, "Brakor reste massif sans devenir un géant disproportionné")
	_check(boss.get_meta("visual_pipeline", "") == "boss_2d_realistic_in_3d", "le pipeline personnage 2.5D / monde 3D est actif")
	_check(boss.get_meta("visual_asset_source", "") == "embedded_official", "aucun cube ou atlas externe ne remplace Brakor")

	var ordinary_profile := EnemyFactory.profile_for_index(0).duplicate(true)
	ordinary_profile["difficulty"] = "intermediaire"
	ordinary_profile["zone"] = 0
	var ordinary := EnemyFactory.create_enemy(ordinary_profile, target)
	root.add_child(ordinary)
	var ordinary_rejected := not Enemy25DVisual.apply(ordinary, visual_profile)
	_check(ordinary_rejected, "le pipeline boss ne modifie pas un ennemi ordinaire")
	_check(ordinary.get_node_or_null("Visual25D") == null, "aucun visuel de Brakor n'est copié sur les autres ennemis")

	boss.queue_free()
	ordinary.queue_free()
	target.queue_free()
	Boss25DEmbeddedAssets.clear_cache()
	await process_frame
	if failures == 0:
		print("BRAKOR 2.5D DANS MONDE 3D RÉUSSI")
	else:
		push_error("%d vérification(s) Brakor ont échoué" % failures)
	quit(failures)
