shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform vec4 ground_color : source_color = vec4(0.16, 0.30, 0.10, 1.0);
uniform vec4 ground_detail : source_color = vec4(0.30, 0.43, 0.14, 1.0);
uniform vec4 shore_color : source_color = vec4(0.70, 0.55, 0.32, 1.0);
uniform vec4 rock_color : source_color = vec4(0.22, 0.20, 0.17, 1.0);
uniform float detail_scale : hint_range(2.0, 80.0) = 26.0;
uniform float shore_start : hint_range(0.45, 0.98) = 0.76;
uniform float wetness : hint_range(0.0, 1.0) = 0.12;
uniform float surface_relief : hint_range(0.0, 1.5) = 0.62;
uniform float macro_contrast : hint_range(0.0, 1.5) = 0.72;

varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float terrain_pattern(vec2 position) {
	float large = value_noise(position * 0.52);
	float medium = value_noise(position * 1.65 + vec2(11.0, 23.0));
	float small = value_noise(position * 5.4 + vec2(37.0, 5.0));
	return large * 0.52 + medium * 0.31 + small * 0.17;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float broad = value_noise(world_position.xz * 0.028);
	float medium = value_noise(world_position.xz * 0.105 + vec2(17.0, 31.0));
	float fine = value_noise(world_position.xz * 0.29 + vec2(3.0, 9.0));
	float micro = value_noise(world_position.xz * 0.86 + vec2(41.0, 13.0));
	float radius = distance(UV, vec2(0.5)) * 2.0;
	float shore = smoothstep(shore_start, 1.03, radius);
	float slope = clamp(1.0 - world_normal.y, 0.0, 1.0);
	float erosion = terrain_pattern(world_position.xz * 0.08);
	float rock = smoothstep(0.12, 0.52, slope + (broad - 0.5) * 0.30 + (erosion - 0.5) * 0.18);

	float color_mix = clamp(broad * 0.46 + medium * 0.34 + fine * 0.20, 0.0, 1.0);
	color_mix = clamp((color_mix - 0.5) * (1.0 + macro_contrast) + 0.5, 0.0, 1.0);
	vec3 ground = mix(ground_color.rgb, ground_detail.rgb, color_mix);
	ground *= 0.80 + micro * 0.29;
	vec3 sand = shore_color.rgb * (0.80 + medium * 0.20 + fine * 0.12);
	vec3 color = mix(ground, sand, shore);
	color = mix(color, rock_color.rgb * (0.70 + medium * 0.34), rock);

	float wet_shore = smoothstep(0.90, 1.025, radius) * wetness;
	float wet_patches = smoothstep(0.72, 0.92, broad) * wetness * (1.0 - shore) * 0.28;
	float wet_mask = clamp(wet_shore + wet_patches, 0.0, 1.0);
	color = mix(color, color * 0.52, wet_mask);

	float relief_scale = mix(0.24, 0.78, surface_relief);
	vec2 normal_uv = world_position.xz * 0.34;
	float center_height = terrain_pattern(normal_uv);
	float x_height = terrain_pattern(normal_uv + vec2(0.055, 0.0));
	float z_height = terrain_pattern(normal_uv + vec2(0.0, 0.055));
	vec3 detail_world_normal = normalize(vec3(
		(center_height - x_height) * relief_scale,
		1.0,
		(center_height - z_height) * relief_scale
	));
	detail_world_normal = normalize(mix(world_normal, detail_world_normal, 0.34 * surface_relief * (1.0 - rock * 0.35)));
	NORMAL = normalize((VIEW_MATRIX * vec4(detail_world_normal, 0.0)).xyz);

	ALBEDO = color;
	ROUGHNESS = mix(0.92, 0.43, wet_mask);
	ROUGHNESS = mix(ROUGHNESS, 0.84, rock);
	SPECULAR = mix(0.14, 0.66, wet_mask);
}
