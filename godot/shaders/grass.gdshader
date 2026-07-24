shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley;

uniform vec4 grass_dark : source_color = vec4(0.035, 0.19, 0.055, 1.0);
uniform vec4 grass_light : source_color = vec4(0.18, 0.62, 0.16, 1.0);
uniform vec3 wind_direction = vec3(0.8, 0.0, 0.35);
uniform float wind_strength : hint_range(0.0, 1.5) = 0.42;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.6;
uniform float weather_gust : hint_range(0.0, 1.0) = 0.08;

varying float blade_height;

void vertex() {
    blade_height = UV.y;
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float gust = sin(TIME * wind_speed + world.x * 0.24 + world.z * 0.17);
    gust += sin(TIME * wind_speed * 0.43 + world.z * 0.41) * 0.45;
    gust += sin(TIME * 4.1 + world.x * 0.083 - world.z * 0.052) * weather_gust;
    float bend = (1.0 - UV.y) * (1.0 - UV.y);
    VERTEX.xz += normalize(wind_direction.xz) * gust * wind_strength * (1.0 + weather_gust * 1.45) * bend;
}

void fragment() {
    float edge = abs(UV.x - 0.5) * 2.0;
    if (edge > mix(0.12, 1.0, UV.y)) discard;
    ALBEDO = mix(grass_light.rgb, grass_dark.rgb, UV.y * 0.75 + edge * 0.18);
    ROUGHNESS = 0.78;
    NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.28));
}
