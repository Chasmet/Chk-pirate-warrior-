shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.005, 0.10, 0.20, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.018, 0.48, 0.65, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.18, 0.72, 0.82, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.97, 1.0, 1.0);
uniform float wave_height : hint_range(0.05, 2.0) = 0.58;
uniform float wave_scale : hint_range(0.02, 1.0) = 0.16;
uniform float wave_speed : hint_range(0.05, 4.0) = 0.78;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.10;
uniform float normal_strength : hint_range(0.1, 3.0) = 1.35;

varying float wave_value;
varying float secondary_wave;
varying vec3 world_position;
varying vec3 wave_normal_world;

float waves(vec2 p, float t) {
    float a = sin(p.x * 1.00 + t * 1.10);
    float b = sin(p.y * 1.35 - t * 0.82);
    float c = sin((p.x + p.y) * 0.72 + t * 1.47);
    float d = sin(length(p) * 0.58 - t * 0.67);
    float e = sin((p.x * 1.9 - p.y * 1.35) + t * 2.15) * 0.10;
    return a * 0.34 + b * 0.27 + c * 0.21 + d * 0.12 + e;
}

void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float t = TIME * wave_speed;
    vec2 p = world_vertex.xz * wave_scale;
    float epsilon = 0.085;
    float height_center = waves(p, t);
    float height_x = waves(p + vec2(epsilon, 0.0), t);
    float height_z = waves(p + vec2(0.0, epsilon), t);

    wave_value = height_center;
    secondary_wave = sin(world_vertex.x * 0.075 - world_vertex.z * 0.055 + t * 2.6);
    VERTEX.y += height_center * wave_height;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    vec3 local_wave_normal = normalize(vec3(
        (height_center - height_x) * wave_height * normal_strength / epsilon,
        1.0,
        (height_center - height_z) * wave_height * normal_strength / epsilon
    ));
    wave_normal_world = normalize(MODEL_NORMAL_MATRIX * local_wave_normal);
}

void fragment() {
    vec3 wave_normal_view = normalize((VIEW_MATRIX * vec4(wave_normal_world, 0.0)).xyz);
    NORMAL = normalize(mix(NORMAL, wave_normal_view, 0.84));

    float fresnel = pow(1.0 - max(dot(NORMAL, normalize(VIEW)), 0.0), 3.5);
    float crest = smoothstep(0.54, 0.93, wave_value);
    float broken_foam = smoothstep(0.64, 0.94, wave_value + secondary_wave * 0.16);
    float foam = clamp(crest * 0.72 + broken_foam * 0.45, 0.0, 1.0);
    float depth_mix = clamp(0.24 + wave_value * 0.15 + fresnel * 0.92, 0.0, 1.0);
    vec3 water = mix(deep_color.rgb, shallow_color.rgb, depth_mix);
    water = mix(water, horizon_color.rgb, fresnel * 0.28);

    ALBEDO = mix(water, foam_color.rgb, foam * 0.58);
    ROUGHNESS = mix(roughness_value, 0.40, foam);
    METALLIC = 0.06;
    SPECULAR = mix(0.94, 0.62, foam);
}
