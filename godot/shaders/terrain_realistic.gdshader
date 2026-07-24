shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform vec4 ground_color : source_color = vec4(0.16, 0.30, 0.10, 1.0);
uniform vec4 ground_detail : source_color = vec4(0.30, 0.43, 0.14, 1.0);
uniform vec4 shore_color : source_color = vec4(0.70, 0.55, 0.32, 1.0);
uniform vec4 rock_color : source_color = vec4(0.22, 0.20, 0.17, 1.0);
uniform float detail_scale : hint_range(2.0, 80.0) = 26.0;
uniform float shore_start : hint_range(0.45, 0.98) = 0.76;
uniform float wetness : hint_range(0.0, 1.0) = 0.12;

varying vec3 world_position;

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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float broad = value_noise(world_position.xz * 0.035);
	float fine = value_noise(world_position.xz * 0.19 + vec2(17.0, 31.0));
	float micro = value_noise(world_position.xz * 0.72 + vec2(3.0, 9.0));
	float radius = distance(UV, vec2(0.5)) * 2.0;
	float shore = smoothstep(shore_start, 1.03, radius);
	float slope = clamp(1.0 - NORMAL.y, 0.0, 1.0);
	float rock = smoothstep(0.15, 0.55, slope + (broad - 0.5) * 0.24);
	vec3 ground = mix(ground_color.rgb, ground_detail.rgb, broad * 0.65 + fine * 0.35);
	ground *= 0.84 + micro * 0.24;
	vec3 sand = shore_color.rgb * (0.84 + fine * 0.24);
	vec3 color = mix(ground, sand, shore);
	color = mix(color, rock_color.rgb * (0.78 + fine * 0.30), rock);
	float wet_shore = smoothstep(0.92, 1.02, radius) * wetness;
	color = mix(color, color * 0.54, wet_shore);
	ALBEDO = color;
	ROUGHNESS = mix(0.90, 0.48, wet_shore);
	SPECULAR = mix(0.16, 0.62, wet_shore);
}
