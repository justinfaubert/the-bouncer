// A sheet of the stock, bare: his notebook's page, the floor sketch, a licence's back. Printed on
// the same paper as everything else, with its tooth and mottle.
shader_type canvas_item;

uniform sampler2D paper_tex : filter_linear, repeat_enable;
uniform vec3 paper : source_color = vec3(0.918, 0.886, 0.812);
uniform float paper_px = 1.5;
uniform float shade = 1.0;            // a little darker for a page held in the dark

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void fragment() {
	vec3 pp = texture(paper_tex, FRAGCOORD.xy / (512.0 * paper_px)).rgb;
	vec3 col = to_linear(paper) * (0.93 + 0.1 * pp.r) * (0.96 + 0.06 * pp.g) * shade;
	COLOR = vec4(to_srgb(col), COLOR.a);
}
