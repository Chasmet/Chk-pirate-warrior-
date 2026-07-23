shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.005, 0.12, 0.22, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.02, 0.48, 0.62, 1.0);
uniform vec4 foam_color : source_color = vec4(0.78, 0.95, 1.0, 1.0);
uniform float wave_height : hint_range(0.05, 2.0) = 0.55;
uniform float wave_scale : hint_range(0.02, 1.0) = 0.16;
uniform float wave_speed : hint_range(0.05, 4.0) = 0.75;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.12;

varying float wave_value;
varying vec3 world_position;

float waves(vec2 p, float t) {
    float a = sin(p.x * 1.00 + t * 1.10);
    float b = sin(p.y * 1.35 - t * 0.82);
    float c = sin((p.x + p.y) * 0.72 + t * 1.47);
    float d = sin(length(p) * 0.58 - t * 0.67);
    return (a * 0.36 + b * 0.28 + c * 0.22 + d * 0.14);
}

void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float t = TIME * wave_speed;
    wave_value = waves(world_vertex.xz * wave_scale, t);
    VERTEX.y += wave_value * wave_height;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.2);
    float foam = smoothstep(0.55, 0.95, abs(wave_value));
    vec3 water = mix(deep_color.rgb, shallow_color.rgb, clamp(fresnel + wave_value * 0.16 + 0.22, 0.0, 1.0));
    ALBEDO = mix(water, foam_color.rgb, foam * 0.42);
    ROUGHNESS = mix(roughness_value, 0.34, foam);
    METALLIC = 0.08;
    SPECULAR = 0.9;
}
