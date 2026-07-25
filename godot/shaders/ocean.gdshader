shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.004, 0.052, 0.115, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.015, 0.255, 0.455, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.10, 0.46, 0.62, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.96, 1.0, 1.0);
uniform float wave_height : hint_range(0.05, 2.0) = 0.42;
uniform float wave_scale : hint_range(0.02, 1.0) = 0.105;
uniform float wave_speed : hint_range(0.05, 4.0) = 0.62;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.14;
uniform float normal_strength : hint_range(0.1, 3.0) = 0.88;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.42;
uniform float foam_amount : hint_range(0.0, 1.5) = 0.72;
uniform float storm_strength : hint_range(0.0, 1.0) = 0.18;

varying float wave_value;
varying float secondary_wave;
varying vec3 wave_normal_world;
varying vec3 displaced_world_position;

float waves(vec2 p, float t) {
    float a = sin(p.x * 0.92 + t * 0.92);
    float b = sin(p.y * 1.16 - t * 0.68);
    float c = sin((p.x + p.y) * 0.58 + t * 1.05);
    float d = sin(length(p) * 0.46 - t * 0.52);
    float cross_wave = sin((p.x * 1.45 - p.y * 1.12) + t * 1.62);
    float storm_chop = cross_wave * mix(0.055, 0.16, storm_strength);
    return a * 0.35 + b * 0.28 + c * 0.20 + d * 0.10 + storm_chop;
}

void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float t = TIME * wave_speed;
    vec2 p = world_vertex.xz * wave_scale;
    float epsilon = 0.10;
    float height_center = waves(p, t);
    float height_x = waves(p + vec2(epsilon, 0.0), t);
    float height_z = waves(p + vec2(0.0, epsilon), t);

    wave_value = height_center;
    secondary_wave = sin(world_vertex.x * 0.052 - world_vertex.z * 0.044 + t * 1.9);
    float safe_height = clamp(wave_height, 0.08, 1.18) * 0.38;
    VERTEX.y += height_center * safe_height;

    vec3 local_wave_normal = normalize(vec3(
        (height_center - height_x) * safe_height * normal_strength / epsilon,
        1.0,
        (height_center - height_z) * safe_height * normal_strength / epsilon
    ));
    wave_normal_world = normalize(MODEL_NORMAL_MATRIX * local_wave_normal);
    displaced_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float t = TIME * wave_speed;
    vec2 detail_uv = displaced_world_position.xz;
    float ripple_x = cos(detail_uv.x * 0.46 + detail_uv.y * 0.17 + t * 2.2) * 0.16;
    ripple_x += cos(detail_uv.x * 0.83 - detail_uv.y * 0.31 - t * 1.7) * 0.09;
    float ripple_z = sin(detail_uv.y * 0.52 - detail_uv.x * 0.21 - t * 2.0) * 0.15;
    ripple_z += sin(detail_uv.y * 0.91 + detail_uv.x * 0.26 + t * 1.45) * 0.08;
    vec3 detail_normal_world = normalize(vec3(-ripple_x, 1.0, -ripple_z));

    vec3 wave_normal_view = normalize((VIEW_MATRIX * vec4(wave_normal_world, 0.0)).xyz);
    vec3 detail_normal_view = normalize((VIEW_MATRIX * vec4(detail_normal_world, 0.0)).xyz);
    NORMAL = normalize(mix(wave_normal_view, detail_normal_view, detail_strength));

    float facing = max(dot(NORMAL, normalize(VIEW)), 0.0);
    float fresnel = pow(1.0 - facing, 3.2);
    float moving_breakup = sin(detail_uv.x * 0.31 + detail_uv.y * 0.23 + t * 1.55) * 0.5 + 0.5;
    float crest = smoothstep(0.60, 1.02, wave_value + moving_breakup * 0.08);
    float broken_foam = smoothstep(0.72, 1.08, wave_value + secondary_wave * 0.13 + moving_breakup * 0.09);
    float foam = clamp((crest * 0.48 + broken_foam * 0.34) * foam_amount, 0.0, 1.0);

    float depth_mix = clamp(0.16 + wave_value * 0.09 + fresnel * 0.78, 0.0, 1.0);
    vec3 water = mix(deep_color.rgb, shallow_color.rgb, depth_mix);
    water = mix(water, horizon_color.rgb, fresnel * 0.30);
    water = mix(water, vec3(0.035, 0.060, 0.090), storm_strength * 0.42);

    float sun_glitter = pow(max(0.0, 1.0 - abs(secondary_wave)), 10.0) * fresnel;
    water += vec3(0.22, 0.30, 0.34) * sun_glitter * mix(0.34, 0.10, storm_strength);

    ALBEDO = mix(water, foam_color.rgb, foam * mix(0.38, 0.66, storm_strength));
    ROUGHNESS = mix(roughness_value, 0.48, foam);
    METALLIC = 0.015;
    SPECULAR = mix(0.82, 0.46, foam);
}
