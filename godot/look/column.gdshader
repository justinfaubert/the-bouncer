// The text column: one even solid of the night ink, with the words knocked out of it.
//
// A solid prints flat on good stock, so the words read clean against it. The paper's tooth and
// grain belong to the room's print (look/press.gdshader) and stay out of here: under a letter
// they read as dirt. All that comes through is the paper's slowest mottle, broader than a
// paragraph and too faint to sit under a word, and the edge of the block where it meets the room,
// where the ink lies a little heavier, the way a solid does at its edge.
shader_type canvas_item;

uniform sampler2D paper_tex : filter_linear, repeat_enable;
uniform vec3 paper : source_color = vec3(0.918, 0.886, 0.812);
uniform vec3 ink_night : source_color = vec3(0.106, 0.129, 0.188);
uniform float paper_px = 1.5;
uniform float cover = 0.997;        // how much of the stock the ink covers: all but a breath of it
uniform float mottle = 0.005;       // how far the cover drifts, across the column

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void fragment() {
	// the paper's mottle (its g and b), magnified until one patch is a paragraph across
	vec2 q = FRAGCOORD.xy / (512.0 * paper_px * 11.0);
	float m = texture(paper_tex, q).g * 0.6 + texture(paper_tex, q * 0.43 + vec2(0.31, 0.57)).b * 0.4;
	float key = cover + mottle * (m - 0.5);
	// the block's edge against the room: a hair heavier, over the first few pixels
	key = min(1.0, key + 0.003 * (1.0 - smoothstep(0.0, 0.012, UV.x)));
	vec3 col = to_linear(paper) * (1.0 - key * (1.0 - to_linear(ink_night)));
	COLOR = vec4(to_srgb(col), 1.0);
}
