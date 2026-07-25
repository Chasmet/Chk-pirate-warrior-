class_name HeroFactory
extends RefCounted

# Les trois héros principaux restent volontairement en 2D réaliste.
# Le monde, les collisions, la caméra et le bateau restent en 3D.
const HEROES := {
	"cheikh": {
		"display_name": "CHEIKH",
		"crew_role": "CAPITAINE",
		"height": 1.86,
		"accent": Color("d4a640"),
		"aura": Color("ef4b32"),
		"role": "Capitaine puissant",
		"weapon": "Épée infernale du Cerbère",
		"sprite": "res://assets/heroes/cheikh_poses.png",
		"third_person_sprite": "res://assets/heroes/cheikh_third_person.png",
		"steering_sprite": "res://assets/heroes/cheikh_steering_v24.png",
		# La planche mesure 444 px de haut : le sprite occupe environ 1,86 m.
		"pixel_size": 0.00419,
		"sprite_y": 0.93,
		"shadow_radius": 0.50
	},
	"yvane": {
		"display_name": "YVANE",
		"crew_role": "MATELOT",
		"height": 1.58,
		"accent": Color("67bcf2"),
		"aura": Color("31a9f3"),
		"role": "Matelot éclaireur",
		"weapon": "Éclair Serpentine",
		"sprite": "res://assets/heroes/yvane_poses.png",
		"third_person_sprite": "res://assets/heroes/yvane_third_person.png",
		"steering_sprite": "res://assets/heroes/yvane_steering_v24.png",
		"pixel_size": 0.00356,
		"sprite_y": 0.79,
		"shadow_radius": 0.42
	},
	"nelvyn": {
		"display_name": "NELVYN",
		"crew_role": "JUNIOR MATELOT",
		"height": 1.32,
		"accent": Color("e5ba55"),
		"aura": Color("835dff"),
		"role": "Junior matelot tactique",
		"weapon": "Boule du Big Bang",
		"sprite": "res://assets/heroes/nelvyn_poses.png",
		"third_person_sprite": "res://assets/heroes/nelvyn_third_person.png",
		"steering_sprite": "res://assets/heroes/nelvyn_steering_v24.png",
		"pixel_size": 0.00297,
		"sprite_y": 0.66,
		"shadow_radius": 0.38
	}
}

static func create_hero(hero_id: StringName, third_person: bool = true) -> CharacterBody3D:
	var resolved_id := String(hero_id)
	if not HEROES.has(resolved_id):
		resolved_id = "cheikh"
	var profile: Dictionary = HEROES[resolved_id]
	var hero := CharacterBody3D.new()
	hero.name = String(profile["display_name"])
	hero.set_meta("hero_id", resolved_id)
	hero.set_meta("profile", profile)
	hero.set_meta("visual_pipeline", "2d_realistic_in_3d")

	var rig := Node3D.new()
	rig.name = "RigVisuel"
	hero.add_child(rig)
	_build_character_art(rig, profile, third_person)
	_build_ground_shadow(rig, profile)
	_build_aura(rig, profile)
	return hero

static func _build_character_art(root: Node3D, profile: Dictionary, third_person: bool) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "CharacterArt"
	var texture_path := String(profile["third_person_sprite"]) if third_person else String(profile["sprite"])
	sprite.texture = load(texture_path) as Texture2D
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = float(profile["pixel_size"])
	sprite.position.y = float(profile["sprite_y"])
	# Le héros reste vertical dans le monde 3D et se présente correctement
	# lorsque la caméra tourne autour de lui.
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.double_sided = true
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.055
	sprite.render_priority = 8
	sprite.modulate = Color.WHITE
	sprite.visible = true
	root.add_child(sprite)

static func set_navigation_visual(hero: CharacterBody3D, enabled: bool) -> void:
	if not is_instance_valid(hero):
		return
	var hero_id := String(hero.get_meta("hero_id", "cheikh"))
	var profile: Dictionary = HEROES.get(hero_id, HEROES["cheikh"])
	var sprite := hero.get_node_or_null("RigVisuel/CharacterArt") as Sprite3D
	if sprite == null:
		return
	var path := String(profile["steering_sprite"]) if enabled else String(profile["third_person_sprite"])
	var texture := load(path) as Texture2D
	if texture != null:
		sprite.texture = texture
		sprite.hframes = 1 if enabled else 4
		sprite.vframes = 1
		sprite.frame = 0

static func _build_ground_shadow(root: Node3D, profile: Dictionary) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "OmbreAuSol"
	var mesh := CylinderMesh.new()
	mesh.top_radius = float(profile["shadow_radius"])
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 32
	shadow.mesh = mesh
	shadow.position.y = 0.025
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.005, 0.008, 0.012, 0.45)
	shadow.material_override = material
	root.add_child(shadow)

static func _build_aura(root: Node3D, profile: Dictionary) -> void:
	var aura := GPUParticles3D.new()
	aura.name = "Aura"
	aura.amount = 120
	aura.lifetime = 0.68
	aura.emitting = false
	aura.visibility_aabb = AABB(Vector3(-2.0, -0.3, -2.0), Vector3(4.0, 4.0, 4.0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.56
	process.direction = Vector3(0, 1, 0)
	process.spread = 42.0
	process.initial_velocity_min = 1.5
	process.initial_velocity_max = 3.8
	process.gravity = Vector3(0, 1.8, 0)
	process.scale_min = 0.03
	process.scale_max = 0.10
	process.color = Color(profile["aura"])
	aura.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.10, 0.30)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(Color(profile["aura"]), 0.78)
	glow.emission_enabled = true
	glow.emission = Color(profile["aura"])
	glow.emission_energy_multiplier = 4.0
	quad.material = glow
	aura.draw_pass_1 = quad
	aura.position.y = float(profile["height"]) * 0.48
	root.add_child(aura)
