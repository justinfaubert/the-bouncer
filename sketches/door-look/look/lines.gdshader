// The key block's lines, found in the mask camera's picture: where the depth jumps (an edge
// against what's behind it) and where it bends (a crease: a corner, a fold, a facet). A quad that
// covers the mask camera's whole view; it keeps the cut the surfaces drew (red, green) and puts
// the lines in blue.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D mask_tex : hint_screen_texture, filter_nearest;
uniform float px = 1.0;               // how far to look for an edge, in pixels: the line's width
uniform float edge = 0.035;           // a jump in depth of this share of the distance is an edge
uniform float crease = 0.002;         // a bend this sharp is a crease
uniform float crease_far = 45.0;      // no creases past this many metres: the depth gets too coarse

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

float depth_at(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return -v.z / v.w;
}

vec3 mask_out(vec3 v) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return v;
#else
	return mix(v / 12.92, pow((v + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), v));
#endif
}

// The nearest thing in a ring round the pixel: its depth, and whether it wants an outline (its
// line weight, in the mask's green). Eyes, say, don't: an eyeball ringed in white reads as a
// goggle.
vec2 nearest_ring(vec2 uv, vec2 e, mat4 inv_proj) {
	vec2 ring[8] = vec2[8](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
		vec2(0.7071, 0.7071), vec2(-0.7071, -0.7071), vec2(0.7071, -0.7071), vec2(-0.7071, 0.7071));
	vec2 best = vec2(1e9, 1.0);
	for (int i = 0; i < 8; i++) {
		vec2 q = uv + ring[i] * e;
		float z = depth_at(q, inv_proj);
		if (z < best.x) {
			best = vec2(z, texture(mask_tex, q).g);
		}
	}
	return best;
}

void fragment() {
	vec2 e = px / VIEWPORT_SIZE;
	float c = depth_at(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec4 m = texture(mask_tex, SCREEN_UV);
	// an edge: something nearer close by, so the line runs just outside the nearer thing's
	// outline. The bigger the drop behind it, the wider the line: an outline against the far
	// wall is bolder than one against the table it sits on.
	vec2 n1 = nearest_ring(SCREEN_UV, e, INV_PROJECTION_MATRIX);
	vec2 n2 = nearest_ring(SCREEN_UV, e * 2.0, INV_PROJECTION_MATRIX);
	float j1 = (c - n1.x) / c;
	float j2 = (c - n2.x) / c;
	float sil = max(smoothstep(edge, edge * 1.8, j1) * smoothstep(0.05, 0.25, n1.y),
		smoothstep(edge * 4.0, edge * 8.0, j2) * smoothstep(0.05, 0.25, n2.y));
	// a crease: where the inverse depth stops being flat (on a plane it's linear across the screen)
	float l = depth_at(SCREEN_UV - vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	float r = depth_at(SCREEN_UV + vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	float u = depth_at(SCREEN_UV - vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float d = depth_at(SCREEN_UV + vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float wc = 1.0 / c;
	float bend = (abs(1.0 / l + 1.0 / r - 2.0 * wc) + abs(1.0 / u + 1.0 / d - 2.0 * wc)) / wc;
	float cr = smoothstep(crease, crease * 2.5, bend) * (1.0 - smoothstep(crease_far * 0.6, crease_far, c));
	// far off, the lines thin out, the way detail goes in the distance
	float far = 1.0 - 0.5 * smoothstep(8.0, 30.0, c);
	float line = max(sil, cr * m.g * 0.8) * far;
	ALBEDO = mask_out(vec3(m.r, m.g, line));
}
