// Mirrored floor reflection: fades away from the contact line and wobbles slightly, as on a wet floor.
// Cheap enough for mobile: one texture read, no screen copy.
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.28;
// Horizontal wobble in texture pixels; the owner sets it so it is about one world pixel.
uniform float wobble_px = 20.0;
// The UV rows this sprite shows, so region sprites fade across their own height.
uniform vec2 uv_span = vec2(0.0, 1.0);

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	// The sprite is drawn flipped, so t is 1.0 at the contact line and 0.0 at the far end.
	float t = clamp((UV.y - uv_span.x) / max(uv_span.y - uv_span.x, 0.0001), 0.0, 1.0);
	vec2 uv = UV;
	uv.x += sin(TIME * 2.2 + t * 28.0) * TEXTURE_PIXEL_SIZE.x * wobble_px * (1.0 - t);
	COLOR = texture(TEXTURE, uv) * tint;
	COLOR.a *= strength * pow(t, 1.4);
}
