shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_alpha_prepass;

uniform sampler2D albedo_texture : source_color;
uniform vec3 key_color = vec3(1.0, 0.0, 1.0);
uniform float key_inner : hint_range(0.0, 0.5) = 0.08;
uniform float key_outer : hint_range(0.05, 0.8) = 0.30;
uniform float contrast : hint_range(0.8, 1.4) = 1.06;
uniform float saturation : hint_range(0.0, 1.5) = 1.08;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 source = texture(albedo_texture, UV);
	float key_distance = distance(source.rgb, key_color);
	float alpha = smoothstep(key_inner, key_outer, key_distance) * source.a * tint.a;
	if (alpha < 0.045) {
		discard;
	}

	vec3 graded = (source.rgb - vec3(0.5)) * contrast + vec3(0.5);
	float luminance = dot(graded, vec3(0.2126, 0.7152, 0.0722));
	graded = mix(vec3(luminance), graded, saturation) * tint.rgb;

	ALBEDO = clamp(graded, vec3(0.0), vec3(1.0));
	ALPHA = alpha;
}
