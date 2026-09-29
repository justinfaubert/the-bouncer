// The text column: a solid of the night ink, printed on the same paper, with the words knocked
// out of it.
shader_type canvas_item;

uniform sampler2D paper_tex : filter_linear, repeat_enable;
uniform vec3 paper : source_color = vec3(0.918, 0.886, 0.812);
uniform vec3 ink_night : source_color = vec3(0.106, 0.129, 0.188);
uniform float paper_px = 1.5;

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void fragment() {
	vec3 pp = texture(paper_tex, FRAGCOORD.xy / (512.0 * paper_px)).rgb;
	float key = (0.94 + 0.12 * pp.g) * (1.0 - smoothstep(0.78, 0.92, pp.r) * 0.6);
	vec3 col = to_linear(paper) * (0.95 + 0.08 * pp.r);
	col *= 1.0 - key * (1.0 - to_linear(ink_night));
	COLOR = vec4(to_srgb(col), 1.0);
}
