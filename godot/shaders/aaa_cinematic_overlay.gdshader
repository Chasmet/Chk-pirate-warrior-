shader_type canvas_item;
render_mode unshaded;

uniform float vignette_strength : hint_range(0.0, 0.8) = 0.18;
uniform float damage_strength : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;
uniform float skill_flash : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_time = 0.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radial = length(centered * vec2(1.0, 0.64));
	float edge = smoothstep(0.29, 0.72, radial);
	float heartbeat = 0.58 + sin(pulse_time * 5.4) * 0.22;
	float health_pulse = low_health * heartbeat;
	float edge_alpha = edge * (vignette_strength + health_pulse * 0.28);
	float full_flash = damage_strength * 0.10 + skill_flash * 0.055;
	vec3 edge_color = mix(vec3(0.0), vec3(0.34, 0.008, 0.004), clamp(damage_strength + health_pulse * 0.62, 0.0, 1.0));
	vec3 skill_color = vec3(0.23, 0.42, 0.66) * skill_flash * 0.22;
	COLOR = vec4(edge_color + skill_color, clamp(edge_alpha + full_flash, 0.0, 0.62));
}
