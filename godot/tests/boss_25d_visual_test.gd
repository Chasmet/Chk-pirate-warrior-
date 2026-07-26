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

	_check(applied, "le visuel de Brakor est appliqué au boss existant")
	_check(boss is CharacterBody3D, "le boss reste un CharacterBody3D dans le monde")
	_check(original_collision != null and original_collision.shape != null, "la collision 3D du boss est conservée")
	_check(is_equal_approx(boss.max_health, original_health), "la vie du boss n'est pas modifiée par son apparence")
	_check(is_equal_approx(boss.attack_damage, original_damage), "les dégâts du boss ne sont pas modifiés par son apparence")
	_check(sprite != null and sprite.texture != null, "le boss possède un Sprite3D réel")
	if sprite != null:
		_check(sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y, "le boss reste vertical pendant la rotation caméra 360°")
		_check(not sprite.no_depth_test, "le boss respecte la profondeur du monde 3D")
		_check(sprite.pixel_size <= 0.0185, "le boss reste massif sans devenir géant")
	_check(boss.get_meta("visual_pipeline", "") == "boss_2d_realistic_in_3d", "le pipeline boss 2D réaliste / monde 3D est actif")

	var ordinary_profile := EnemyFactory.profile_for_index(0).duplicate(true)
	ordinary_profile["difficulty"] = "intermediaire"
	ordinary_profile["zone"] = 0
	var ordinary := EnemyFactory.create_enemy(ordinary_profile, target)
	root.add_child(ordinary)
	var ordinary_rejected := not Enemy25DVisual.apply(ordinary, visual_profile)
	_check(ordinary_rejected, "un ennemi ordinaire reste en 3D")
	_check(ordinary.get_node_or_null("Visual25D") == null, "aucun sprite de boss n'est ajouté aux ennemis ordinaires")

	boss.queue_free()
	ordinary.queue_free()
	target.queue_free()
	await process_frame
	if failures == 0:
		print("BOSS 2.5D DANS MONDE 3D RÉUSSI")
	else:
		push_error("%d vérification(s) boss ont échoué" % failures)
	quit(failures)
