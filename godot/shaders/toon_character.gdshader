shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.7, 0.35, 0.2, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.08, 0.06, 0.08, 1.0);
uniform vec4 rim_color : source_color = vec4(0.95, 0.78, 0.32, 1.0);
uniform float shade_steps : hint_range(2.0, 6.0) = 3.0;
uniform float rim_power : hint_range(1.0, 8.0) = 3.6;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.28;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.68;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.02;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec3 color = mix(base_color.rgb, vec3(1.0, 0.18, 0.08), hit_flash * 0.72);
    ALBEDO = color;
    ROUGHNESS = roughness_value;
    METALLIC = metallic_value;
    SPECULAR = 0.42;
}

void light() {
    float ndl = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
    float steps = max(shade_steps - 1.0, 1.0);
    float band = floor(ndl * steps + 0.5) / steps;
    vec3 lit_color = mix(shadow_color.rgb, base_color.rgb, band);
    lit_color = mix(lit_color, vec3(1.0, 0.18, 0.08), hit_flash * 0.72);
    DIFFUSE_LIGHT += lit_color * LIGHT_COLOR * ATTENUATION;

    float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
    SPECULAR_LIGHT += rim_color.rgb * rim * rim_strength * LIGHT_COLOR * ATTENUATION;
}
