// Mirrored floor reflection: fades away from the contact line and wobbles slightly, as on a wet floor.
// Cheap enough for mobile: one texture read, no screen copy.
// Every reflection draws through one shared material (floor_reflection.tres), so the four values that
// differ per sprite are instance uniforms, set on each FloorReflection node with
// set_instance_shader_parameter: one material means the shader is drawn once at the logo screen
// (StudioLogo's warm-up) instead of each reflection building its own material at run time (SMOOTH-6).
shader_type canvas_item;

instance uniform float strength : hint_range(0.0, 1.0) = 0.28;
// Horizontal wobble in texture pixels; the owner sets it so it is about one world pixel.
instance uniform float wobble_px = 20.0;
// The UV rows this sprite shows, so region sprites fade across their own height.
instance uniform vec2 uv_span = vec2(0.0, 1.0);
// Mipmap LOD bias, matching the source sprite's (sharp_sprite.gdshader) so a character and its reflection agree.
instance uniform float lod_bias = 0.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	// The sprite is drawn flipped, so t is 1.0 at the contact line and 0.0 at the far end.
	float t = clamp((UV.y - uv_span.x) / max(uv_span.y - uv_span.x, 0.0001), 0.0, 1.0);
	vec2 uv = UV;
	uv.x += sin(TIME * 2.2 + t * 28.0) * TEXTURE_PIXEL_SIZE.x * wobble_px * (1.0 - t);
	COLOR = texture(TEXTURE, uv, lod_bias) * tint;
	COLOR.a *= strength * pow(t, 1.4);
}
