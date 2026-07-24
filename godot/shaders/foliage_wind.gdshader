shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley;

uniform vec4 foliage_color : source_color = vec4(0.10, 0.42, 0.16, 1.0);
uniform vec3 wind_direction = vec3(0.82, 0.0, 0.34);
uniform float wind_strength : hint_range(0.0, 1.2) = 0.22;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.35;
uniform float detail_gust : hint_range(0.0, 1.0) = 0.28;
uniform float weather_gust : hint_range(0.0, 1.0) = 0.08;

varying float sun_variation;

void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float slow_gust = sin(TIME * wind_speed + world.x * 0.115 + world.z * 0.08);
    float fast_gust = sin(TIME * wind_speed * 2.35 + world.x * 0.31 - world.z * 0.27) * detail_gust;
    float height_mask = clamp(VERTEX.y * 0.22 + 0.55, 0.12, 1.0);
    float storm_pulse = sin(TIME * 3.7 + world.x * 0.047 - world.z * 0.063) * weather_gust;
    float bend = (slow_gust + fast_gust + storm_pulse) * wind_strength * (1.0 + weather_gust * 1.35) * height_mask;
    vec2 wind = normalize(wind_direction.xz);
    VERTEX.xz += wind * bend;
    VERTEX.y += abs(fast_gust) * wind_strength * 0.08 * height_mask;
    sun_variation = slow_gust * 0.05 + height_mask * 0.06;
}

void fragment() {
    ALBEDO = foliage_color.rgb * (0.92 + sun_variation);
    ROUGHNESS = 0.82;
    SPECULAR = 0.18;
}
