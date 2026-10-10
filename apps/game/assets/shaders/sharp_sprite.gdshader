// Character sprites drawn far below their texture size: sample the mipmap chain half a level finer
// than the GPU would pick, so outlines stay crisp without the shimmer of plain linear filtering.
// The project setting rendering/textures/default_filters/texture_mipmap_bias does nothing in the
// GL Compatibility 2D renderer, so the bias lives here. Needs a mipmapped texture and a
// linear-with-mipmaps filter on the node. FloorReflection copies lod_bias to the sprite's reflection.
shader_type canvas_item;

uniform float lod_bias = -0.5;

varying vec4 tint;

void vertex() {
	// The vertex colour carries the node's modulate; the fragment's COLOR already holds the default sample.
	tint = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV, lod_bias) * tint;
}
