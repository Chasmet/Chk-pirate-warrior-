shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.005, 0.075, 0.15, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.02, 0.28, 0.48, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.12, 0.48, 0.62, 1.0);
uniform vec4 foam_color : source_color = vec4(0.78, 0.94, 0.98, 1.0);
uniform float wave_height : hint_range(0.05, 2.0) = 0.42;
uniform float wave_scale : hint_range(0.02, 1.0) = 0.105;
uniform float wave_speed : hint_range(0.05, 4.0) = 0.62;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.16;
uniform float normal_strength : hint_range(0.1, 3.0) = 0.82;
uniform float storm_strength : hint_range(0.0, 1.0) = 0.18;

varying float wave_value;
varying float secondary_wave;
varying vec3 wave_normal_world;

float waves(vec2 p, float t) {
    float a = sin(p.x * 0.92 + t * 0.92);
    float b = sin(p.y * 1.16 - t * 0.68);
    float c = sin((p.x + p.y) * 0.58 + t * 1.05);
    float d = sin(length(p) * 0.46 - t * 0.52);
    float e = sin((p.x * 1.45 - p.y * 1.12) + t * 1.62) * mix(0.06, 0.14, storm_strength);
    return a * 0.36 + b * 0.29 + c * 0.20 + d * 0.10 + e;
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
    float safe_height = clamp(wave_height, 0.08, 1.15) * 0.38;
    VERTEX.y += height_center * safe_height;

    vec3 local_wave_normal = normalize(vec3(
        (height_center - height_x) * safe_height * normal_strength / epsilon,
        1.0,
        (height_center - height_z) * safe_height * normal_strength / epsilon
    ));
    wave_normal_world = normalize(MODEL_NORMAL_MATRIX * local_wave_normal);
}

void fragment() {
    vec3 wave_normal_view = normalize((VIEW_MATRIX * vec4(wave_normal_world, 0.0)).xyz);
    NORMAL = normalize(mix(NORMAL, wave_normal_view, 0.70));

    float fresnel = pow(1.0 - max(dot(NORMAL, normalize(VIEW)), 0.0), 3.0);
    float crest = smoothstep(0.68, 0.98, wave_value);
    float broken_foam = smoothstep(0.77, 1.05, wave_value + secondary_wave * 0.10);
    float foam = clamp(crest * 0.52 + broken_foam * 0.26, 0.0, 1.0);
    float depth_mix = clamp(0.18 + wave_value * 0.08 + fresnel * 0.72, 0.0, 1.0);
    vec3 water = mix(deep_color.rgb, shallow_color.rgb, depth_mix);
    water = mix(water, horizon_color.rgb, fresnel * 0.20);
    water = mix(water, vec3(0.045, 0.075, 0.105), storm_strength * 0.38);

    ALBEDO = mix(water, foam_color.rgb, foam * mix(0.34, 0.58, storm_strength));
    ROUGHNESS = mix(roughness_value, 0.46, foam);
    METALLIC = 0.02;
    SPECULAR = mix(0.72, 0.50, foam);
}
