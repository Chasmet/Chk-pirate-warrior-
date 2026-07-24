class_name HeroFactory
extends RefCounted

const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"height": 1.92,
		"skin": Color("70462f"),
		"accent": Color("d4a640"),
		"aura": Color("ef4b32"),
		"role": "Capitaine puissant",
		"weapon": "Sabre courbe",
		"sprite": "res://assets/heroes/cheikh_poses.webp",
		"pixel_size": 0.00305,
		"sprite_y": 0.91
	},
	"yvane": {
		"display_name": "YVANE",
		"height": 1.62,
		"skin": Color("7a4e34"),
		"accent": Color("67bcf2"),
		"aura": Color("31a9f3"),
		"role": "Éclaireur électrique",
		"weapon": "Fronde",
		"sprite": "res://assets/heroes/yvane_poses.webp",
		"pixel_size": 0.00266,
		"sprite_y": 0.80
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"height": 1.34,
		"skin": Color("805238"),
		"accent": Color("e5ba55"),
		"aura": Color("76df72"),
		"role": "Inventeur tactique",
		"weapon": "Gadgets",
		"sprite": "res://assets/heroes/nelvyn_poses.webp",
		"pixel_size": 0.00228,
		"sprite_y": 0.68
	}
}

static func create_hero(hero_id: StringName) -> CharacterBody3D:
	var resolved_id := String(hero_id)
	if not HEROES.has(resolved_id):
		resolved_id = "cheikh"
	var profile: Dictionary = HEROES[resolved_id]
	var hero := CharacterBody3D.new()
	hero.name = String(profile["display_name"])
	hero.set_meta("hero_id", resolved_id)
	hero.set_meta("profile", profile)

	var rig := Node3D.new()
	rig.name = "RigVisuel"
	hero.add_child(rig)
	_build_character_art(rig, profile)
	_build_ground_shadow(rig, profile)
	_build_aura(rig, profile)
	return hero

static func _build_character_art(root: Node3D, profile: Dictionary) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "CharacterArt"
	sprite.texture = load(String(profile["sprite"])) as Texture2D
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = float(profile["pixel_size"])
	sprite.position.y = float(profile["sprite_y"])
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.double_sided = true
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.render_priority = 2
	root.add_child(sprite)

static func _build_ground_shadow(root: Node3D, profile: Dictionary) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "OmbreAuSol"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.52 if String(profile["display_name"]) == "CHEIKH" else 0.42
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 40
	shadow.mesh = mesh
	shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.005, 0.008, 0.012, 0.48)
	shadow.material_override = material
	root.add_child(shadow)

static func _build_aura(root: Node3D, profile: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 180
	aura.lifetime = 0.72
	aura.emitting = false
	aura.visibility_aabb = AABB(Vector3(-2.5, -0.3, -2.5), Vector3(5, 4.5, 5))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.62
	process.direction = Vector3(0, 1, 0)
	process.spread = 44.0
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.6
	process.gravity = Vector3(0, 2.2, 0)
	process.scale_min = 0.035
	process.scale_max = 0.12
	process.color = Color(profile["aura"])
	aura.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.36)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(Color(profile["aura"]), 0.82)
	glow.emission_enabled = true
	glow.emission = Color(profile["aura"])
	glow.emission_energy_multiplier = 5.2
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = float(profile["height"]) * 0.48
	root.add_child(aura)
