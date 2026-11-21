// The Listener: the sphere that rises out of the strait. Look tests (tests/shots_listener.gd).
//
// It's drawn exactly: the mesh is only a shell a little bigger than it, and each pixel traces its
// ray to the true sphere, so its outline is a perfect circle and its depth is the sphere's own (the
// press finds its edge from that), however close he is. The only perfect thing in the world.
//
// Like every surface it draws twice. For the eye, one of its looks; for the press (the mask
// camera, visual layer 20), how the key block is cut on it:
//   look 0  black: flat, no light on it at all (the one that loses its impact; for comparison)
//   look 1  the point: black glass, and far down inside it a single light with nine rings round
//           it, each deeper than the last, so it's a well that goes down past the sphere's own back
//           (Paradiso XXVIII: the point, and the circles of fire round it, the nearest the fastest)
//   look 2  the world inside: a ball of glass with another place in it, upside down, the way a
//           glass ball shows what's behind it; here the place is the Sov's own room
//   look 3  the tiles: black glass over a Penrose tiling. The whole infinite tiling is inside it,
//           drawn smaller and smaller toward the edge so it never ends, its centre always the side
//           facing him, and its tiles flip (a phason: the tiling stays a Penrose tiling as it
//           changes). The tiles about to flip light up first
//   look 4  the black mirror: a perfect black-chrome mirror. It shows the world round it, exactly,
//           and one thing that isn't there (the test puts a man on the seawall that only the
//           reflection sees)
//   look 5  the waves: standing waves under the glass, five at once at the Penrose angles, their
//           still lines bright, the way sand gathers on a plate that's sung to
//   look 6  the eye: the tiles for an iris, and in the middle, where a pupil would be, the world
//           inside. Far off it's one white light on the water; near, the tiles; narrowed on, the room
//   look 7  the Listener (second pass, from Hutch's notes on look 6): obsidian, black glass lit by
//           lights that aren't in the world, so its form comes from what it gives back, not from a
//           line round it. The room grows inside it from the nexus at its heart (grown, 0 a point
//           of light, 1 the whole ball), in a glass ball of its own. The tiles are ghosts of lines,
//           packed toward the nexus, smaller and smaller forever, and what it hears runs in along
//           them. And polish takes it to the full mirror: the mirror comes in from the rim, the
//           black drawing back into the nexus ahead of it
// and how the press cuts it:
//   cut 3   solid or clean away, nothing between (like the lights)
//   cut 4   strokes wrapped round it, level with the strait (like the people)
//   cut 5   printed clean: its own picture straight onto the paper, no strokes, no grain, no inks
// and with twice, its body (the black of it) printed twice: the press's second hit of the night ink,
// the only black in the game with no paper showing through it, so it's blacker than the night round
// it, and the dark strait doesn't swallow it
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always;

uniform int look = 0;
uniform int cut = 3;
uniform float cut_px = 7.0;
uniform float lines = 1.0;
uniform float radius = 4.0;              // the sphere's own radius (the mesh is a shell a little bigger)
uniform float t = 0.0;                   // its clock, in seconds (the tests step it)
uniform float hear = 0.0;                // what it's hearing: 0 quiet, 1 the jukebox flat out
uniform vec3 glow : source_color = vec3(0.62, 1.0, 0.86);
uniform float glow_energy = 1.6;
uniform float shell = 0.9;               // how much the glass gives back of the world round it
// the point
uniform vec3 deep_dir = vec3(0.0, -0.5, 1.0);
uniform float deep = 16.0;               // how far down the light is, in radii
// the world inside
uniform sampler2D inside_tex : source_color, filter_linear;
uniform float inside_fov = 100.0;
uniform float inside_energy = 1.0;
uniform float pupil = 0.24;              // the eye: how much of it across is the window
// the tiles
uniform float tile_scale = 2.6;          // tiles across its middle, roughly
uniform float flip_speed = 1.0;
uniform float tile_edges = 0.16;         // how bright the tiles' edges are when nothing's happening
uniform float phase = 0.0;               // the eye's tiles: how far their flipping has gone (the script
                                         // runs it on, faster while it hears)
// the world round it, from its centre: six views (tests/shots_listener.gd)
uniform sampler2D cube_px : source_color, filter_linear;
uniform sampler2D cube_nx : source_color, filter_linear;
uniform sampler2D cube_py : source_color, filter_linear;
uniform sampler2D cube_ny : source_color, filter_linear;
uniform sampler2D cube_pz : source_color, filter_linear;
uniform sampler2D cube_nz : source_color, filter_linear;
uniform bool has_cube = false;
uniform float mirror = 0.82;
uniform bool twice = false;              // its body printed twice (look/press.gdshader)
// look 7
uniform float grown = 0.12;              // how much of it across the room fills: 0 a point, 1 all of it
uniform float polish = 0.0;              // 0 obsidian, 1 the full mirror
uniform float pack = 0.0;                // how far the packing's gone, in octaves (the script runs it
                                         // on, faster while it hears)
uniform float light_energy = 22.0;       // the hidden lights, before the obsidian gives back its share
uniform float ghost = 1.0;               // the tiles' strength while it's quiet, as a share of hearing
uniform float tile_k = 4.0;              // how big the packed tiles are at its rim
uniform float mirror_gain = 1.0;         // look 7's mirror: how much brighter than the world it gives it back

const uint MASK_LAYER = 524288u;
const vec2 D5[5] = {vec2(1.0, 0.0), vec2(0.309017, 0.951057), vec2(-0.809017, 0.587785),
	vec2(-0.809017, -0.587785), vec2(0.309017, -0.951057)};
const float PHI2 = 2.6180340;            // the golden ratio, squared: one octave of the packing

global uniform float cut_scale;

vec3 mask_out(vec3 v) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return v;
#else
	return mix(v / 12.92, pow((v + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), v));
#endif
}

float tri(float x) {
	return abs(fract(x) - 0.5) * 2.0;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// one of the six views round it, by the way it faces and its up
vec3 face(sampler2D tex, vec3 d, vec3 f, vec3 up) {
	vec3 r = normalize(cross(f, up));
	vec3 u = cross(r, f);
	float k = dot(d, f);
	vec2 uv = vec2(0.5 + 0.5 * dot(d, r) / k, 0.5 - 0.5 * dot(d, u) / k);
	return texture(tex, clamp(uv, vec2(0.002), vec2(0.998))).rgb;
}

// the world round it, the way it goes off in direction d
vec3 world(vec3 d) {
	if (!has_cube) {
		return mix(vec3(0.01, 0.012, 0.016), vec3(0.03, 0.035, 0.045), smoothstep(-0.2, 0.4, d.y));
	}
	vec3 a = abs(d);
	if (a.x >= a.y && a.x >= a.z) {
		return d.x > 0.0 ? face(cube_px, d, vec3(1, 0, 0), vec3(0, 1, 0)) : face(cube_nx, d, vec3(-1, 0, 0), vec3(0, 1, 0));
	} else if (a.y >= a.z) {
		return d.y > 0.0 ? face(cube_py, d, vec3(0, 1, 0), vec3(0, 0, -1)) : face(cube_ny, d, vec3(0, -1, 0), vec3(0, 0, 1));
	}
	return d.z > 0.0 ? face(cube_pz, d, vec3(0, 0, 1), vec3(0, 1, 0)) : face(cube_nz, d, vec3(0, 0, -1), vec3(0, 1, 0));
}

// The Penrose tiling (de Bruijn's pentagrid): which rhomb x is in. Returns how far x is from the
// rhomb's nearest edge (edges are 1 long), whether it's a fat one, how near it is to flipping, and a
// number for the tile. The pentagrid's offsets sum to nothing, so it's always a true Penrose tiling;
// moving them in the perpendicular space (ph) flips tiles in place without moving the rest.
vec4 penrose(vec2 x, vec2 ph) {
	float G[5];
	G[0] = 0.0 + dot(ph, D5[0]);
	G[1] = 0.18 + dot(ph, D5[2]);
	G[2] = -0.02 + dot(ph, D5[4]);
	G[3] = 0.09 + dot(ph, D5[1]);
	G[4] = -0.25 + dot(ph, D5[3]);
	vec2 sg = vec2(0.0);
	for (int i = 0; i < 5; i++) {
		sg += G[i] * D5[i];
	}
	vec2 zc = (x - sg) / 2.5;
	vec4 best = vec4(-9.0, 0.0, 9.0, 0.0);
	for (int j = 0; j < 4; j++) {
		for (int k = j + 1; k < 5; k++) {
			vec2 a = D5[j];
			vec2 b = D5[k];
			float det = a.x * b.y - a.y * b.x;
			float nj0 = ceil(dot(zc, a) + G[j] - 1.42);
			float nk0 = ceil(dot(zc, b) + G[k] - 1.42);
			for (int p = 0; p < 3; p++) {
				for (int q = 0; q < 3; q++) {
					float nj = nj0 + float(p);
					float nk = nk0 + float(q);
					float u = nj - G[j];
					float v = nk - G[k];
					vec2 z0 = vec2(b.y * u - a.y * v, -b.x * u + a.x * v) / det;
					vec2 V = nj * a + nk * b;
					float prox = 9.0;
					for (int i = 0; i < 5; i++) {
						if (i != j && i != k) {
							float f = dot(z0, D5[i]) + G[i];
							V += ceil(f) * D5[i];
							prox = min(prox, abs(f - round(f)));
						}
					}
					vec2 d = x - V;
					float s = (d.x * b.y - d.y * b.x) / det;
					float tt = (a.x * d.y - a.y * d.x) / det;
					float e = min(min(s, 1.0 - s), min(tt, 1.0 - tt)) * abs(det);
					if (e > best.x) {
						best = vec4(e, (k - j == 1 || k - j == 4) ? 1.0 : 0.0, prox, hash12(V * 7.31 + 0.5));
					}
				}
			}
		}
	}
	return best;
}

// the tiles, lit: dsk is where on the disc facing him (its edge at 1), from offset out
float tiles(vec2 dsk, float from) {
	float rho = length(dsk);
	// the whole infinite tiling inside the circle, smaller and smaller toward its edge
	float rr = min(rho, 0.9995);
	float rt = tile_scale * 0.5 * log((1.0 + rr) / (1.0 - rr)) + from;
	float spin = t * 0.021;
	vec2 dir = rho > 1e-5 ? dsk / rho : vec2(1.0, 0.0);
	dir = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * dir;
	vec2 xt = dir * rt;
	vec2 ph = vec2(cos(t * 0.11 * flip_speed), sin(t * 0.083 * flip_speed)) * (0.32 + 0.25 * hear);
	vec4 tl = penrose(xt, ph);
	float px = max(length(fwidth(xt)), 1e-4);
	float lw = 0.026;
	float edge = 1.0 - smoothstep(lw, lw + px * 1.2, tl.x);
	// where the tiles get too small to see, they go to their average
	float fade = smoothstep(0.08, 0.35, px);
	edge = mix(edge, 0.18, fade);
	float about = 1.0 - smoothstep(0.0, 0.06, tl.z);
	// a ping going out from the middle now and then: what it's heard
	float ring = exp(-pow((rt - mod(t * 0.9, 9.0)) * 1.6, 2.0)) * (0.3 + hear);
	float fill = (tl.y > 0.5 ? 0.02 : 0.045) * (0.6 + 0.8 * tl.w) * (1.0 - fade);
	return edge * (tile_edges + 1.1 * about + ring) + fill + about * 0.4 * (1.0 - fade);
}

// The eye's tiles: nothing at all while it's quiet. When it hears something they come up from the
// window outward, hairlines, as far as it's hearing; rings go out through them; and the tiles
// about to flip fill with light first.
float surfaced(vec2 dsk, float from) {
	float rho = length(dsk);
	float rr = min(rho, 0.9995);
	float rt = tile_scale * 0.5 * log((1.0 + rr) / (1.0 - rr)) + from;
	float spin = t * 0.021;
	vec2 dir = rho > 1e-5 ? dsk / rho : vec2(1.0, 0.0);
	dir = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * dir;
	vec2 xt = dir * rt;
	vec2 ph = vec2(cos(phase * 0.11), sin(phase * 0.083)) * 0.4;
	vec4 tl = penrose(xt, ph);
	float px = max(length(fwidth(xt)), 1e-4);
	float edge = 1.0 - smoothstep(px * 0.45, px * 1.35, tl.x);
	float fade = smoothstep(0.1, 0.3, px);
	edge *= 1.0 - fade;
	float about = 1.0 - smoothstep(0.0, 0.05, tl.z);
	// as far out from the window as it's hearing, and never the whole of it: the rest stays black
	float reach = hear * 3.2;
	float shown = (1.0 - smoothstep(reach - 1.6, reach, rt - from)) * smoothstep(0.0, 0.15, hear);
	// a ring going out through the rest every couple of seconds, while it hears
	float ping = exp(-pow((rt - from - mod(t * 1.6, 10.0)) * 1.3, 2.0)) * smoothstep(0.1, 0.6, hear) * 0.9;
	float lit = max(shown, ping);
	return edge * lit + about * lit * (0.22 + 0.14 * tl.w) * (1.0 - fade);
}

// the world inside, through a round window: q on the window's disc (its edge at 1). It's seen as a
// glass ball sees what's behind it: upside down and wrapped round
vec3 window(vec2 q) {
	float rq = length(q);
	float th = rq * radians(inside_fov) * 0.5;
	vec2 dir = rq > 1e-5 ? q / rq : vec2(0.0);
	vec2 sc = -dir * tan(min(th, 1.45)) / tan(radians(inside_fov) * 0.5);
	vec2 uv = vec2(0.5 + 0.5 * sc.x, 0.5 - 0.5 * sc.y);
	return texture(inside_tex, clamp(uv, vec2(0.0), vec2(1.0))).rgb * inside_energy;
}

float lum(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// The strokes round its form for the press (cut 4): level with the water, pushed along where it
// turns away, a set distance apart on the screen however near it is
float strokes(vec3 P, vec3 C, vec3 N) {
	float hh = dot(P - C, vec3(0.0, 1.0, 0.0)) / radius;
	float nd = N.y;
	float fs = hh + 0.018 * nd - 0.012 * (1.0 - abs(nd));
	float px_apart = cut_px * max(cut_scale, 0.25);
	float fw = max(length(vec2(dFdx(fs), dFdy(fs))), 1e-6);
	float l = log2(fw * px_apart);
	float s0 = exp2(floor(l));
	return mix(tri(fs / s0), tri(fs / (2.0 * s0)), fract(l));
}

// The hidden lights (look 7). They light it for whoever's looking, the way a film lights a face,
// and they're nowhere in the world: a four-pane window behind him, up and to his left, that it
// gives back as the catchlight a painter puts in an eye to make it look back, and a big dim soft
// box behind it on his right, so its edge comes up out of the dark there without a line. v is the
// reflected ray in his frame (x his right, y up, z toward him); vpx how much v turns across a pixel.
float hidden(vec3 v, float vpx) {
	float s = 0.0;
	vec3 L = normalize(vec3(-0.55, 0.6, 0.58));
	float d = dot(v, L);
	if (d > 0.2) {
		vec3 lr = normalize(cross(vec3(0.0, 1.0, 0.0), L));
		vec3 lu = cross(L, lr);
		vec2 p = vec2(dot(v, lr), dot(v, lu)) / d;
		float aa = vpx / d;
		vec2 q = abs(p) - vec2(0.17, 0.22) + 0.025;
		float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 0.025;
		float pane = 1.0 - smoothstep(-aa, aa, sd);
		float mb = 0.016;
		float bar = max(1.0 - smoothstep(mb - aa, mb + aa, abs(p.x)), 1.0 - smoothstep(mb - aa, mb + aa, abs(p.y)));
		s += pane * (1.0 - bar);
	}
	vec3 S = normalize(vec3(0.8, 0.25, -0.55));
	float d2 = dot(v, S);
	if (d2 > 0.1) {
		vec3 sr = normalize(cross(vec3(0.0, 1.0, 0.0), S));
		vec3 su = cross(S, sr);
		vec2 p = vec2(dot(v, sr), dot(v, su)) / d2;
		float sd = length(max(abs(p) - vec2(0.35, 0.6), vec2(0.0)));
		s += 0.08 * exp(-sd * sd / 0.18);
	}
	return s;
}

// The room in a glass ball of its own, Rr across, at its heart (look 7): the ray from P along I1.
// Upside down and wrapped round, the way a glass ball shows a place; its edge goes soft, the room
// fading into the black, not ringed. dc: how near the ray passes the middle, for the glow round it
vec3 room(vec3 P, vec3 I1, vec3 C, float Rr, vec3 f, vec3 r, vec3 u, out float dc) {
	vec3 o = P - C;
	float b = dot(o, I1);
	float c2 = max(dot(o, o) - b * b, 0.0);
	dc = sqrt(c2);
	float h = Rr * Rr - c2;
	if (h <= 0.0) {
		return vec3(0.0);
	}
	vec3 Q1 = P + I1 * (-b - sqrt(h));
	vec3 N1 = (Q1 - C) / Rr;
	vec3 J = refract(I1, N1, 1.0 / 1.5);
	vec3 P2 = Q1 + J * (-2.0 * dot(J, N1) * Rr);
	vec3 N2 = (P2 - C) / Rr;
	vec3 I2 = refract(J, -N2, 1.5);
	if (dot(I2, I2) < 0.01) {
		I2 = reflect(J, -N2);
	}
	vec3 lp = vec3(dot(I2, r), dot(I2, u), dot(I2, -f));
	vec3 col = vec3(0.0);
	if (lp.z > 0.05) {
		vec2 sc = lp.xy / lp.z / tan(radians(inside_fov) * 0.5);
		vec2 uv = vec2(0.5 + 0.5 * sc.x, 0.5 - 0.5 * sc.y);
		if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
			col = texture(inside_tex, uv).rgb * inside_energy;
			col *= smoothstep(0.0, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
		}
	}
	return col * (1.0 - smoothstep(0.6, 1.0, dc / Rr));
}

// The tiles packed toward the nexus (look 7): ghosts of lines. The tiling's far reaches are folded
// into the middle (an inversion), so the tiles get smaller toward its heart and never end, and the
// packing runs them in: the tiling at two sizes an octave apart, one fading up as the other packs
// away into the middle, so it runs in forever. What it's hearing runs in along the lines, a spiral,
// a needle in a groove.
float packed(vec2 dsk, float hearing) {
	float rho = max(length(dsk), 1e-4);
	float spin = t * 0.021;
	vec2 dir = dsk / rho;
	dir = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * dir;
	vec2 ph = vec2(cos(phase * 0.11), sin(phase * 0.083)) * 0.4;
	float z = fract(pack);
	float sum = 0.0;
	for (int k = 0; k < 2; k++) {
		float o = z + float(k);
		float wgt = sin(PI * 0.5 * o);
		wgt *= wgt;
		vec2 X = dir * (tile_k / (pow(PHI2, o) * rho));
		vec4 tl = penrose(X, ph);
		float px = max(length(fwidth(X)), 1e-4);
		float w = max(0.026, px * 1.1);
		float core = exp(-(tl.x * tl.x) / (w * w));
		float haze = exp(-tl.x / (w * 3.0)) * 0.08;
		float fade = smoothstep(0.045, 0.16, px);
		float ln = mix(core + haze, 0.02, fade);
		float about = (1.0 - smoothstep(0.0, 0.06, tl.z)) * (1.0 - fade);
		float flick = 0.7 + 0.3 * sin(t * 1.3 + tl.w * 40.0);
		// the brighter of the two sizes, not both: where they cross they don't build up into thorns
		sum = max(sum, wgt * (ln * flick + about * 0.18));
	}
	// they come in from short of the rim, so its edge stays clean black glass
	sum *= smoothstep(0.97, 0.72, rho);
	float zeta = log(rho);
	float th = atan(dsk.y, dsk.x);
	float g = fract(zeta * 1.3 + th / TAU + t * 0.7);
	float run = exp(-pow((g - 0.5) * 5.0, 2.0));
	return sum * (ghost * 0.1 + 0.25 * smoothstep(0.0, 0.6, hearing) + run * hearing * 1.1);
}

// Look 7 whole, for the eye and the press alike: its colour; how bright what its surface gives
// back is (sheen) and what comes from inside it (inner); and how far the mirror's come in (mir)
vec3 listener7(vec3 P, vec3 N, vec3 I, vec3 C, vec3 f, vec3 r, vec3 u, out float sheen, out float inner, out float mir) {
	// inside: the tiles' shell, a little in, and the room at the heart
	vec3 I1 = refract(I, N, 1.0 / 1.25);
	float rin = 0.86 * radius;
	vec3 o2 = P - C;
	float b2 = dot(o2, I1);
	float h2 = b2 * b2 - (dot(o2, o2) - rin * rin);
	float tl = 0.0;
	if (h2 > 0.0) {
		vec3 q = (P + I1 * (-b2 - sqrt(h2)) - C) / rin;
		tl = packed(vec2(dot(q, r), dot(q, u)), hear);
	}
	float Rr = max(grown, 0.03) * radius * 0.97;
	float dc = 0.0;
	vec3 rm = room(P, I1, C, Rr, f, r, u, dc);
	float pxw = max(fwidth(dc), 1e-4);
	float in_room = 1.0 - smoothstep(Rr * 0.85, Rr * 1.02, dc);
	// while it's small the room's a light: a glow round it never smaller than a few pixels. Grown,
	// it has none, or the glow would pile up on its rim into the line it doesn't have
	float halo = exp(-max(dc - Rr, 0.0) / max(pxw * 2.0, Rr * 0.16)) * (1.0 - in_room)
		* (1.0 - smoothstep(0.2, 0.45, grown));
	vec3 white = vec3(1.0, 0.95, 0.86) * inside_energy;
	vec3 interior = rm + white * halo * 0.45 + glow * glow_energy * tl * mix(1.0, 0.45, in_room);
	// and while the room's only a few pixels across (far off, or the first days) it's one white
	// light, the light the Esso kid points at on day 1, not doing anything
	float far_light = 1.0 - smoothstep(8.0, 24.0, Rr / pxw);
	float core = 1.0 - smoothstep(Rr * 0.55, Rr * 1.1, dc);
	interior += white * far_light * (core * 1.4 + halo * 0.6);
	// the surface: black glass, what it gives back of the world and of the hidden lights
	float cosv = clamp(dot(N, -I), 0.0, 1.0);
	float F = 0.04 + 0.96 * pow(1.0 - cosv, 5.0);
	vec3 R = reflect(I, N);
	vec3 v = vec3(dot(R, r), dot(R, u), dot(R, f));
	float hl = hidden(v, max(length(fwidth(v)), 1e-4));
	vec3 env = world(R);
	vec3 lc = vec3(0.96, 0.97, 1.0);
	vec3 surf_o = F * (env + lc * hl * light_energy);
	vec3 surf_m = env * mirror * mirror_gain + lc * hl * light_energy * 0.05;
	// the mirror coming in from the rim, and the tiles flaring along the front of it
	float rs = length(vec2(dot(N, r), dot(N, u)));
	float e0 = 1.0 - polish * 1.15;
	mir = smoothstep(e0, e0 + 0.15, rs);
	float front = exp(-pow((rs - e0 - 0.075) / 0.04, 2.0)) * step(0.001, polish) * step(polish, 0.999);
	vec3 obs = interior * (1.0 - F) * (1.0 + 2.5 * front) + surf_o;
	sheen = lum(mix(surf_o, surf_m, mir));
	inner = lum(interior * (1.0 - F) * (1.0 + 2.5 * front)) * (1.0 - mir);
	return mix(obs, surf_m, mir);
}

void fragment() {
	// the ray from his eye through this pixel, and where it meets the true sphere
	vec3 eye = CAMERA_POSITION_WORLD;
	vec3 frag = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 I = normalize(frag - eye);
	vec3 C = NODE_POSITION_WORLD;
	vec3 oc = eye - C;
	float b = dot(oc, I);
	float h = b * b - (dot(oc, oc) - radius * radius);
	if (h < 0.0) {
		discard;
	}
	float th = -b - sqrt(h);
	if (th < 0.0) {
		discard;
	}
	vec3 P = eye + I * th;
	vec3 N = (P - C) / radius;
	vec4 clip = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(P, 1.0));
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = clip.z / clip.w * 0.5 + 0.5;
#else
	DEPTH = clip.z / clip.w;
#endif
	// a frame that faces him: f toward his eye, r his right, u his up
	vec3 f = normalize(eye - C);
	vec3 r = normalize(cross(-f, vec3(0.0, 1.0, 0.0)));
	vec3 u = cross(r, -f);

	if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u && look == 7) {
		// the obsidian, cut: the room and the tiles take their picture solid or clean away; and
		// the black, obsidian or mirror, is printed twice where it gives back nothing, breaking
		// into strokes where the hidden lights and the world come up on it: the second hit going
		// to lines first, then the lines thinning to the paper. So by night the mirror's a black
		// disc with the town's lights in it, and by day it holds the whole town
		float sheen = 0.0;
		float inner = 0.0;
		float mir = 0.0;
		listener7(P, N, I, C, f, r, u, sheen, inner, mir);
		float tms = strokes(P, C, N);
		float red = tms * 0.9;
		if (cut == 5) {
			red = 1.0;
		} else if (inner > 0.05) {
			red = 0.45;
		} else if (twice) {
			float w = smoothstep(0.025, 0.16, sheen);
			if (tms < 1.0 - w) {
				red = 0.95;
			}
		}
		ALBEDO = mask_out(vec3(red, lines, 0.0));
	} else if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u) {
		float tm = 0.5;
		if (cut == 5) {
			tm = 1.0 / 0.9;
		} else if (cut == 4) {
			// round the form, level with the water, pushed along where it turns away
			float hh = dot(P - C, vec3(0.0, 1.0, 0.0)) / radius;
			float nd = N.y;
			float fs = hh + 0.018 * nd - 0.012 * (1.0 - abs(nd));
			float px_apart = cut_px * max(cut_scale, 0.25);
			float fw = max(length(vec2(dFdx(fs), dFdy(fs))), 1e-6);
			float l = log2(fw * px_apart);
			float s0 = exp2(floor(l));
			tm = mix(tri(fs / s0), tri(fs / (2.0 * s0)), fract(l));
		}
		float red = tm * 0.9;
		// printed twice: a second hit of the night on its body, so its black is the only one in
		// the game with no paper in it (look/press.gdshader). Not where the glass catches the
		// light at its rim, the window at its heart, or the tiles while they're up
		if (twice && cut != 5) {
			float fres_m = 0.04 + 0.96 * pow(1.0 - clamp(dot(N, -I), 0.0, 1.0), 5.0);
			bool body = fres_m < 0.3;
			if (body && look == 6) {
				vec3 I1 = refract(I, N, 1.0 / 1.25);
				float rin = 0.86 * radius;
				vec3 o2 = P - C;
				float b2 = dot(o2, I1);
				float h2 = b2 * b2 - (dot(o2, o2) - rin * rin);
				if (h2 > 0.0) {
					vec3 q = (P + I1 * (-b2 - sqrt(h2)) - C) / rin;
					vec2 dsk = vec2(dot(q, r), dot(q, u));
					float rho = length(dsk);
					float pr = pupil * (1.0 + 0.1 * hear + 0.025 * sin(t * 0.7));
					float px = max(fwidth(rho), 1e-4);
					if (rho < pr + max(px * 6.0, pr * 0.35)) {
						body = false;
					} else if (hear > 0.01) {
						vec2 id = dsk / rho * clamp((rho - pr) / (1.0 - pr), 0.0, 1.0);
						body = surfaced(id, 1.6) < 0.04;
					}
				}
			}
			if (body) {
				red = 0.95;
			}
		}
		ALBEDO = mask_out(vec3(red, lines, 0.0));
	} else {
		float cosv = clamp(dot(N, -I), 0.0, 1.0);
		float fres = 0.04 + 0.96 * pow(1.0 - cosv, 5.0);
		vec3 refl = world(reflect(I, N));
		vec3 col = vec3(0.0);
		if (look == 1) {
			// the point: inside, the ray goes on as if the sphere were a hole, down a well whose
			// rings are each further down than the last, to the light at the bottom
			vec3 ax = normalize(deep_dir);
			vec3 L = C + ax * deep * radius;
			vec3 dl = normalize(L - P);
			float ang = acos(clamp(dot(I, dl), -1.0, 1.0));
			float px_ang = max(fwidth(ang), 1e-5);
			float core = exp(-pow(ang / (px_ang * 2.2), 2.0));
			float halo = exp(-ang / (px_ang * 14.0));
			vec3 ra = normalize(cross(ax, vec3(0.0, 1.0, 0.0)));
			vec3 rb = cross(ra, ax);
			float rings = 0.0;
			float den = dot(I, ax);
			for (int i = 0; i < 9; i++) {
				float fi = float(i);
				float k = fi / 8.0;
				// down the well: the first ring just inside the glass, the last near the light
				float z = mix(0.2, deep * 0.85, k * k);
				float ring_r = mix(0.92, 0.18, k);
				if (abs(den) > 1e-4) {
					float s = dot(C + ax * z * radius - P, ax) / den;
					if (s > 0.0) {
						vec3 X = P + I * s - (C + ax * z * radius);
						vec2 q = vec2(dot(X, ra), dot(X, rb)) / radius;
						float rr = length(q);
						float az = atan(q.y, q.x);
						float px_r = max(fwidth(rr), 1e-5);
						float band = 1.0 - smoothstep(px_r * 0.6, px_r * 1.8, abs(rr - ring_r));
						// each ring is beaded, so its turning shows; the deeper, the faster
						float speed = (0.15 + k * 1.1) * (1.0 + hear * 2.0) * (mod(fi, 2.0) < 0.5 ? 1.0 : -1.0);
						float beads = smoothstep(0.1, 0.7, sin(az * (11.0 + fi * 2.0) + t * speed));
						rings += band * (0.35 + 0.65 * beads) * mix(0.35, 1.0, k);
					}
				}
			}
			vec3 inner = glow * glow_energy * (core * 5.0 + halo * 0.5 + rings * 0.9);
			col = inner * (1.0 - fres) + refl * fres * shell;
		} else if (look == 2) {
			// a ball of glass: the ray bends in, crosses, bends out, and finds the other place
			vec3 I1 = refract(I, N, 1.0 / 1.5);
			float ch = -2.0 * dot(I1, N) * radius;
			vec3 P2 = P + I1 * ch;
			vec3 N2 = (P2 - C) / radius;
			vec3 I2 = refract(I1, -N2, 1.5);
			if (dot(I2, I2) < 0.01) {
				I2 = reflect(I1, -N2);
			}
			vec3 lp = vec3(dot(I2, r), dot(I2, u), dot(I2, -f));
			vec3 inside = vec3(0.0);
			if (lp.z > 0.05) {
				vec2 sc = lp.xy / lp.z / tan(radians(inside_fov) * 0.5);
				vec2 uv = vec2(0.5 + 0.5 * sc.x, 0.5 - 0.5 * sc.y);
				if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
					inside = texture(inside_tex, uv).rgb * inside_energy;
					float vig = smoothstep(0.0, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
					inside *= vig;
				}
			}
			col = inside * (1.0 - fres) + refl * fres * shell;
		} else if (look == 3 || look == 5 || look == 6) {
			// under the glass: the ray bends in a little and meets an inner sphere
			vec3 I1 = refract(I, N, 1.0 / 1.25);
			float rin = 0.86 * radius;
			vec3 o2 = P - C;
			float b2 = dot(o2, I1);
			float h2 = b2 * b2 - (dot(o2, o2) - rin * rin);
			vec3 under = vec3(0.0);
			if (h2 > 0.0) {
				vec3 Q = P + I1 * (-b2 - sqrt(h2));
				vec3 q = (Q - C) / rin;
				vec2 dsk = vec2(dot(q, r), dot(q, u));
				float rho = length(dsk);
				if (look == 3) {
					under = glow * glow_energy * tiles(dsk, 0.0);
				} else if (look == 6) {
					// the window at its heart, which breathes a little with what it hears
					float pr = pupil * (1.0 + 0.1 * hear + 0.025 * sin(t * 0.7));
					float px = max(fwidth(rho), 1e-4);
					float in_pupil = 1.0 - smoothstep(pr - px, pr + px, rho);
					float rim = 1.0 - smoothstep(px * 0.5, px * 1.6, abs(rho - pr));
					// from far off the window is a light: a glow round it, never smaller than a few
					// pixels across
					float halo = exp(-max(rho - pr, 0.0) / max(px * 2.0, pr * 0.12)) * (1.0 - in_pupil);
					vec2 id = rho > 1e-5 ? dsk / rho * clamp((rho - pr) / (1.0 - pr), 0.0, 1.0) : vec2(0.0);
					vec3 iris = glow * glow_energy * surfaced(id, 1.6);
					// white, like the light the Esso kid points at on the first day: one light, not doing anything
					vec3 warm = vec3(1.0, 0.95, 0.86) * inside_energy;
					under = mix(iris + warm * halo * 0.55, window(dsk / pr), in_pupil) + warm * rim * 0.9;
				} else {
					// the waves: stereographic, so it reads as a skin, centred on him
					vec2 xs = dsk / (1.0 + sqrt(max(1.0 - rho * rho, 0.0))) * 26.0 * (1.0 + 0.15 * sin(t * 0.07));
					float w = 0.0;
					for (int i = 0; i < 5; i++) {
						w += cos(dot(xs, D5[i]) + t * (0.55 + 0.13 * float(i)) * (1.0 + hear * 2.0));
					}
					float px = max(fwidth(w), 1e-4);
					float nodal = 1.0 - smoothstep(px * 0.6, px * 1.8 + 0.08, abs(w));
					under = glow * glow_energy * nodal * (0.8 + 0.6 * hear) * smoothstep(1.0, 0.75, rho);
				}
			}
			col = under * (1.0 - fres) + refl * fres * shell;
		} else if (look == 4) {
			col = refl * mirror;
		} else if (look == 7) {
			float sheen = 0.0;
			float inner = 0.0;
			float mir = 0.0;
			col = listener7(P, N, I, C, f, r, u, sheen, inner, mir);
		}
		ALBEDO = col;
	}
}
