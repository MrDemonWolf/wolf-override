// Full-screen grade for the world canvas only: a mild cold tint and an edge vignette.
// Multiply blending means no screen copy, so it costs one quad on mobile.
shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform vec3 grade : source_color = vec3(0.93, 0.975, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.46;

void fragment() {
	vec2 d = (UV - vec2(0.5)) * vec2(1.0, 1.2);
	float v = smoothstep(vignette_start, 1.0, length(d) * 1.3);
	COLOR = vec4(grade * (1.0 - v * vignette_strength), 1.0);
}
