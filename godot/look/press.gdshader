// The press. Prints what his eyes see in five inks on cream stock, every frame:
//
//   night  the key block, blue-black. Solid in the dark, cut away in the light. Its mid-tones are
//          strokes that follow the surfaces (the mask camera draws where they run), and its lines
//          are the room's edges: printed in ink where it's light, cut out of the ink where it's dark.
//   lamp   amber, for every warm light: the pendants, the lamp over the door, the lot's sodium.
//   neon   red, for the sign, the jukebox, tail lights. And blood. Nothing else is red.
//   cold   green-white, for the tubes in the back and the screens: the back hall, the kitchen, the
//          washrooms, the Esso's canopy, the television's light.
//   earth  brick and sepia, for the warm things the light falls on: skin, wood, leather, beer.
//
// Light is paper: where the light is brightest, nothing prints. The colour of the light picks the
// ink (press/separation.png and separation_b.png, from tools/press.py), never more than two colours
// on one spot besides the night. The grain, the paper and the plates' wander are pinned to
// directions round his head, not to the screen, so they hold still as he looks round.
shader_type canvas_item;

uniform sampler2D scene : filter_linear;              // the eye's picture
uniform sampler2D cut_mask : filter_linear;          // r the key block's cut, g line weight, b lines
uniform sampler2D separation : filter_linear;         // rendered colour -> night, lamp, neon coverage
uniform sampler2D separation_b : filter_linear;       // rendered colour -> cold, earth coverage
uniform sampler2D grain : filter_linear, repeat_enable;
uniform sampler2D paper_tex : filter_linear, repeat_enable;

uniform vec3 paper : source_color = vec3(0.918, 0.886, 0.812);
uniform vec3 ink_night : source_color = vec3(0.106, 0.129, 0.188);
uniform vec3 ink_lamp : source_color = vec3(0.941, 0.635, 0.235);
uniform vec3 ink_neon : source_color = vec3(0.851, 0.220, 0.173);
uniform vec3 ink_cold : source_color = vec3(0.561, 0.780, 0.722);
uniform vec3 ink_earth : source_color = vec3(0.604, 0.353, 0.235);

uniform vec2 view_px = vec2(1258.0, 1080.0);
uniform vec2 levels_in = vec2(0.0, 0.92);            // the render's black and white points
uniform float lift = 0.72;                           // opens up the shadows: the room is darker than a print wants
uniform float tints = 4.0;                           // steps of tint on the colour plates
uniform vec2 reg_lamp = vec2(0.9, -0.6);             // the press's own misregistration, in pixels
uniform vec2 reg_neon = vec2(-0.7, 0.8);
uniform vec2 reg_cold = vec2(0.6, 0.9);
uniform vec2 reg_earth = vec2(-0.8, -0.5);
uniform float slip = 0.0;                            // drink: the plates wander, in pixels
uniform float time = 0.0;

// his body, in the print (game/view.gd): nothing here is a meter; it's how the picture is printed
uniform float bleed = 0.0;                           // nerves: the red comes up in the dark
uniform float hurt = 0.0;                            // hurt: red thickens at the edges of his sight
uniform float pulse = 0.0;                           // his heart, 0..1 on each beat: the ink swells
uniform float starve = 0.0;                          // late: the ink runs thin and the strokes break
uniform float flash = 0.0;                           // a cut between places: the page goes blank
uniform float pull = 1.0;                            // a cut coming in: how far the press has got with the new
                                                     // print, the plates laid one after another (lightest
                                                     // first, the key block last, as a printer pulls a proof)
// the style of print, for choosing between looks (see bible/05_LOG.md, "the look, five ways"):
// 0 the press as it is, 1 clean cut, 2 the black plate, 3 painted, 4 pulp halftone; and the render
// brought forward (round two): 5 painted heavy, 6 painted light, 7 night stock, 8 super 8, 9 bodycam,
// 10 the bar's camera, 11 anamorphic, 12 painted on night stock
uniform int style = 0;
uniform float film_grain = 1.0;                      // the film looks' own dials (the Look menu): grain,
uniform float film_halation = 1.0;                   // the red round the lights,
uniform float film_glow = 1.0;                       // the lights' soft glow,
uniform float film_vignette = 1.0;                   // and the lens's falloff at the corners
uniform float halo = 0.0;                            // the bulbs' halation: old incandescent glass blooms into the lamp ink
uniform float print_k = 1.0;                         // the Print setting: 1 the cut strokes, 0 a flat wash of the night ink
uniform vec2 band = vec2(0.16, 0.84);                // the key block's tone: below this, bare paper; above, solid ink; strokes between

uniform mat3 cam_basis = mat3(1.0);                  // his head, for pinning the grain to directions
uniform float tan_half_fov = 0.55;
uniform float px_per_rad = 900.0;
uniform float grain_px = 1.5;                        // size of a grain texel, in pixels
uniform float paper_px = 1.5;

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

// how much of each ink prints for a rendered colour: a 33 x 33 x 33 table, laid out in slices
// (separation: the night, the lamp and the neon; separation_b: the cold and the earth)
vec3 separate(vec3 c) {
	const float n = 33.0;
	c = pow(clamp((c - levels_in.x) / (levels_in.y - levels_in.x), 0.0, 1.0), vec3(lift)) * (n - 1.0);
	float b0 = floor(c.b);
	float b1 = min(b0 + 1.0, n - 1.0);
	vec2 a = vec2((b0 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	vec2 b = vec2((b1 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	return mix(texture(separation, a).rgb, texture(separation, b).rgb, c.b - b0);
}

vec2 separate_b(vec3 c) {
	const float n = 33.0;
	c = pow(clamp((c - levels_in.x) / (levels_in.y - levels_in.x), 0.0, 1.0), vec3(lift)) * (n - 1.0);
	float b0 = floor(c.b);
	float b1 = min(b0 + 1.0, n - 1.0);
	vec2 a = vec2((b0 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	vec2 b = vec2((b1 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	return mix(texture(separation_b, a).rg, texture(separation_b, b).rg, c.b - b0);
}

// How much of a plate has gone down on the paper, pull of the way through the proof: it starts at
// a and is down by b, laid in grainy, the way ink comes off a roller that hasn't quite got it all
// yet. Past b it's all there.
float laid(float a, float b, float g) {
	float k = clamp((pull - a) / (b - a), 0.0, 1.0);
	return smoothstep(g - 0.18, g + 0.18, k * 1.36 - 0.18);
}

// a painter's smoothing (Kuwahara): of the four quarters round a pixel, the calmest one's mean, so
// flat areas go to strokes of one colour and edges stay hard
vec3 painted(vec2 uv, vec2 px, float r) {
	vec3 mean[4];
	vec3 sq[4];
	for (int q = 0; q < 4; q++) { mean[q] = vec3(0.0); sq[q] = vec3(0.0); }
	for (int j = 0; j <= 3; j++) {
		for (int i = 0; i <= 3; i++) {
			vec2 o = vec2(float(i), float(j)) * r / 3.0;
			vec3 a = texture(scene, uv + vec2(-o.x, -o.y) * px).rgb;
			vec3 b = texture(scene, uv + vec2(o.x, -o.y) * px).rgb;
			vec3 c = texture(scene, uv + vec2(-o.x, o.y) * px).rgb;
			vec3 d = texture(scene, uv + vec2(o.x, o.y) * px).rgb;
			mean[0] += a; sq[0] += a * a;
			mean[1] += b; sq[1] += b * b;
			mean[2] += c; sq[2] += c * c;
			mean[3] += d; sq[3] += d * d;
		}
	}
	vec3 best = mean[0] / 16.0;
	float least = 1e9;
	for (int q = 0; q < 4; q++) {
		vec3 m = mean[q] / 16.0;
		vec3 v = abs(sq[q] / 16.0 - m * m);
		float s = v.r + v.g + v.b;
		if (s < least) { least = s; best = m; }
	}
	return best;
}

// a halftone screen: round dots at an angle, pitch pixels apart, covering cov of the paper
float dots(vec2 p, float ang, float pitch, float cov) {
	vec2 q = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * p / pitch;
	vec2 c = fract(q) - 0.5;
	float d = length(c);
	float r = sqrt(clamp(cov, 0.0, 1.0)) * 0.72;
	float aa = 0.9 / pitch;
	return smoothstep(r + aa, r - aa, d);
}

// the bulbs' bloom: how much hot light lies round this pixel, out to rad pixels (a), and its colour (rgb)
vec4 bloom_at(vec2 uv, vec2 px, float rad, float jit, float lo) {
	float s = 0.0;
	vec3 hue = vec3(0.0);
	for (int k = 0; k < 16; k++) {
		float a = (float(k) + jit) * 0.3927;
		for (int r = 1; r <= 4; r++) {
			vec3 c = texture(scene, uv + vec2(cos(a), sin(a)) * rad * (float(r) - jit * 0.5) / 4.0 * px).rgb;
			float l = max(c.r, max(c.g, c.b));
			float w = smoothstep(lo, 0.97, l) * (1.25 - float(r) * 0.25);
			s += w;
			hue += c * w;
		}
	}
	return vec4(hue / max(s, 0.001), clamp(s / 10.0, 0.0, 1.0));
}

vec4 bloom(vec2 uv, vec2 px, float rad, float jit) {
	return bloom_at(uv, px, rad, jit, 0.6);
}

// ---- the render brought forward (styles 5 to 12): film stocks and lenses

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// a lens's barrel: k bends the edges out, zoom crops back in so the corners stay filled
vec2 barrel(vec2 uv, float k, float zoom, float aspect) {
	vec2 c = (uv - 0.5) * vec2(aspect, 1.0);
	c *= zoom * (1.0 + k * dot(c, c));
	return c / vec2(aspect, 1.0) + 0.5;
}

// the render as it comes, opened up the way the press opens it, in linear light
vec3 rendered(vec2 uv) {
	vec3 c = texture(scene, uv).rgb;
	c = pow(clamp((c - levels_in.x) / (levels_in.y - levels_in.x), 0.0, 1.0), vec3(lift * 0.95));
	return to_linear(c);
}

// a soft look through a cheap lens: the render blurred a little
vec3 soft(vec2 uv, vec2 px, float r) {
	vec3 s = vec3(0.0);
	for (int j = -1; j <= 1; j++)
		for (int i = -1; i <= 1; i++)
			s += rendered(uv + vec2(float(i), float(j)) * r * px);
	return s / 9.0;
}

// a horizontal streak through anything burning, as an anamorphic lens draws it
float streak(vec2 uv, vec2 px) {
	float s = 0.0;
	for (int k = 1; k <= 14; k++) {
		float d = float(k) * 18.0;
		vec3 a = texture(scene, uv + vec2(d, 0.0) * px).rgb;
		vec3 b = texture(scene, uv - vec2(d, 0.0) * px).rgb;
		float w = 1.0 - float(k) / 15.0;
		s += (smoothstep(0.85, 1.0, max(a.r, max(a.g, a.b))) + smoothstep(0.85, 1.0, max(b.r, max(b.g, b.b)))) * w * w;
	}
	return s / 6.0;
}

vec3 sat(vec3 c, float k) {
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	return max(mix(vec3(l), c, k), vec3(0.0));
}

// value noise, smooth between its points
float vnoise(vec2 p, float seed) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i + seed);
	float b = hash12(i + vec2(1.0, 0.0) + seed);
	float c = hash12(i + vec2(0.0, 1.0) + seed);
	float d = hash12(i + vec2(1.0, 1.0) + seed);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// silver grain: crystals that clump at a few sizes at once, not one speck per pixel; about zero
// mean and unit spread
float crystals(vec2 p, float seed) {
	float n = (vnoise(p, seed) - 0.5) * 0.62
		+ (vnoise(p * 0.47 + 3.1, seed + 11.0) - 0.5) * 0.3
		+ (vnoise(p * 0.21 + 7.7, seed + 23.0) - 0.5) * 0.18;
	return n * 4.2;
}

// Night stock: a tungsten negative pushed in a dark room, printed. The light goes through the
// emulsion, off the film's base and back into the red layer (the halation), the lens softens and
// splits a little toward its edge, the stock has a toe that holds the blacks and a shoulder that
// rolls the bulbs off warm, and the grain is in the dye layers, three clouds of different sizes,
// made in density so it rides on the picture rather than over it. A new frame of grain every
// 1/24 s, whatever the game's frame rate.
vec3 night_stock(vec2 uv, vec2 px, float jit, vec2 frag, float frame, float rr, float hungry) {
	float k = view_px.y / 1080.0;
	vec3 c = rendered(uv);
	c = mix(c, soft(uv, px, 0.8 * k), 0.4 + 0.45 * smoothstep(0.35, 1.1, rr));
	vec2 d = (uv - 0.5) * px * 2.2 * k * smoothstep(0.25, 1.1, rr) / max(rr, 0.05);
	c.r = mix(c.r, rendered(uv + d).r, 0.7);
	c.b = mix(c.b, rendered(uv - d).b, 0.7);
	// exposure: the halation, tight and orange at the core, wide and red further out, and the glow
	vec4 tight = bloom_at(uv, px, 9.0 * k, jit, 0.8);
	vec4 wide = bloom_at(uv, px, 44.0 * k, jit, 0.74);
	c += (vec3(1.0, 0.34, 0.1) * tight.a * 0.34 + vec3(0.8, 0.12, 0.04) * wide.a * 0.5) * film_halation;
	c += wide.rgb * wide.a * 0.06 * film_glow;
	c *= 1.0 + (hash12(vec2(frame, 5.0)) - 0.5) * 0.012;              // the shutter's flicker
	// the stock's curve: a toe per layer (the blue's shorter, so the shadows go a touch cool) and
	// a shoulder (the red's longer, so the bulbs roll off warm)
	c = c * c / (c + vec3(0.008, 0.007, 0.0055));
	vec3 w = vec3(0.66, 0.6, 0.56);
	c = c / (c + w) * (1.0 + w) * 1.05;
	float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(c, c * vec3(0.84, 0.96, 1.1), (1.0 - smoothstep(0.0, 0.22, lum)) * 0.75);
	c = sat(c, 1.08 - 0.3 * smoothstep(0.55, 1.0, lum));             // rich in the mids, paler in the bulbs
	c = c * 0.985 + vec3(0.0028, 0.0034, 0.0044);                     // the print's base: no black is quite black
	// the grain, in density: most in the mid-tones, least in the deepest dark and the burnt light
	float l = sqrt(max(lum, 0.0));
	float amp = (0.3 + 0.7 * smoothstep(0.03, 0.32, l) * (1.0 - smoothstep(0.6, 1.0, l))) * 0.15 * film_grain * (1.0 + hungry);
	vec2 gp = frag / (1.1 * k) + vec2(hash12(vec2(frame, 1.0)), hash12(vec2(frame, 2.0))) * 997.0;
	float mono = crystals(gp, 0.0);
	vec3 dye = vec3(crystals(gp * 1.12 + 17.0, 31.0), crystals(gp * 0.96 + 41.0, 57.0), crystals(gp * 0.78 + 73.0, 83.0));
	vec3 gr = mono * 0.78 + dye * 0.4 * vec3(0.8, 0.9, 1.3);
	c *= exp2(-gr * amp * 2.0);
	c *= 1.0 - smoothstep(0.3, 1.3, rr) * 0.45 * film_vignette;       // the lens's falloff
	return max(c, vec3(0.0));
}

void fragment() {
	vec2 uv = UV;
	float asp0 = view_px.x / view_px.y;
	float frame24 = floor(time * 24.0);
	if (style == 7) uv = UV + (vec2(hash12(vec2(frame24, 7.0)), hash12(vec2(frame24, 9.0))) - 0.5) * 0.4 / view_px;   // the gate's weave
	else if (style == 8) uv = barrel(UV, 0.06, 0.97, asp0) + vec2(sin(time * 13.0) * 0.0006, cos(time * 9.0) * 0.0009 + 0.0004);
	else if (style == 9) uv = barrel(UV, 0.42, 0.82, asp0);
	else if (style == 10) uv = barrel(UV, 0.18, 0.92, asp0);
	else if (style == 11) uv = barrel(UV, 0.04, 0.98, asp0);
	vec2 px = 1.0 / view_px;

	// where this pixel looks, as a direction round his head: the grain and the paper live there
	vec2 ndc = vec2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
	float aspect = view_px.x / view_px.y;
	vec3 ray = cam_basis * normalize(vec3(ndc.x * tan_half_fov * aspect, ndc.y * tan_half_fov, -1.0));
	vec2 sph = vec2(atan(ray.x, ray.z), asin(clamp(ray.y, -1.0, 1.0))) * px_per_rad;
	vec3 g = texture(grain, sph / (128.0 * grain_px)).rgb;          // one grain screen per ink
	vec3 g2 = texture(grain, sph / (128.0 * grain_px) + vec2(0.29, 0.48)).rgb;   // and the other two's
	vec3 pp = texture(paper_tex, sph / (512.0 * paper_px)).rgb;     // r tooth and fibre, g and b mottle
	vec2 pp2 = texture(paper_tex, sph / (512.0 * paper_px) + vec2(0.41, 0.19)).gb;

	// the plates, each where the press put it
	vec2 wander = slip * vec2(sin(time * 0.61 + 1.7), cos(time * 0.47 + 0.3));
	vec2 o_k = wander * 0.35;
	vec2 o_l = reg_lamp + slip * vec2(sin(time * 0.37 + 4.1), cos(time * 0.71 + 2.2));
	vec2 o_r = reg_neon + slip * vec2(cos(time * 0.53 + 0.9), sin(time * 0.29 + 5.0));
	vec2 o_c = reg_cold + slip * vec2(sin(time * 0.43 + 2.6), sin(time * 0.67 + 1.1));
	vec2 o_e = reg_earth + slip * vec2(cos(time * 0.31 + 3.3), cos(time * 0.59 + 4.4));
	// a plate still coming down is out of register, and settles as it lands
	if (pull < 1.0) {
		float off = 1.0 - pull;
		o_l += vec2(7.0, -4.0) * off * off;
		o_e += vec2(-5.0, 6.0) * off * off;
		o_c += vec2(4.0, 7.0) * off * off;
		o_r += vec2(-8.0, -3.0) * off * off;
		o_k += vec2(3.0, -2.0) * off * off * off;
	}
	float cn = separate(texture(scene, uv + o_k * px).rgb).r;
	float cl = separate(texture(scene, uv + o_l * px).rgb).g;
	float cr = separate(texture(scene, uv + o_r * px).rgb).b;
	float cc = separate_b(texture(scene, uv + o_c * px).rgb).r;
	float ce = separate_b(texture(scene, uv + o_e * px).rgb).g;
	vec4 m = texture(cut_mask, uv + o_k * px);
	// a story object, printed clean: its own picture straight onto the paper, no strokes or grain
	float clean = step(0.97, m.r);
	// printed twice: a second hit of the night, no paper left in it (the Listener's body,
	// look/listener.gdshader, marks it in the mask's red, between the cuts and the clean)
	float twice = step(0.925, m.r) * (1.0 - clean);

	// the key block: strokes whose width is the tone, cut with a slightly wandering hand. The tone
	// is pressed into a band first, the way a cutter works: the light left bare, the deep shadow
	// left solid, and strokes only in the half-tones between, where the form turns
	const float aa = 0.14;
	vec2 bd = band;
	float jit = 0.18;
	if (style == 1) { bd = vec2(0.13, 0.72); jit = 0.05; }
	float tone = clamp((cn - bd.x) / (bd.y - bd.x), 0.0, 1.0);
	tone = tone * tone * (1.5 - 0.5 * tone);   // eased into the light only: the deep end stays open
	float T = clamp(m.r / 0.9 + (g.r - 0.5) * jit - pulse * 0.07, 0.0, 1.0);
	T = aa + T * (1.0 - 2.0 * aa);
	float key = smoothstep(T - aa, T + aa, tone);
	// the Print setting: towards 0, the strokes give way to a flat wash of the same ink
	key = mix(tone * 0.8, key, print_k);

	// its lines: left standing in the light, cut out of the block in the dark
	vec3 around = texture(scene, uv + (o_k + vec2(3.0, 2.0)) * px).rgb + texture(scene, uv + (o_k + vec2(-3.0, -2.0)) * px).rgb
		+ texture(scene, uv + (o_k + vec2(-2.0, 3.0)) * px).rgb + texture(scene, uv + (o_k + vec2(2.0, -3.0)) * px).rgb;
	float dark = separate(around * 0.25).r;
	// the gouge skips now and then
	float line = m.b * smoothstep(0.08, 0.3, m.b * (0.75 + 0.5 * g.b));
	// one side or the other, never a grey that's neither: a line that half prints and half cuts
	// loses the figure against what's behind it
	float cut_out = smoothstep(0.56, 0.64, dark);
	key = mix(max(key, line), key * (1.0 - line), cut_out);

	// the colour plates: flat tints in a few steps, the edges between steps grainy, the ink a
	// little uneven
	float tn = tints;
	float gj = 0.9;
	float mott = 0.24;
	if (style == 1) { tn = 6.0; gj = 0.3; mott = 0.1; }
	float kl = clamp(floor(cl * tn + 0.5 + (g.g - 0.5) * gj) / tn, 0.0, 1.0);
	float kr = clamp(floor(cr * tn + 0.5 + (g.b - 0.5) * gj) / tn, 0.0, 1.0);
	float kc = clamp(floor(cc * tn + 0.5 + (g2.g - 0.5) * gj) / tn, 0.0, 1.0);
	float ke = clamp(floor(ce * tn + 0.5 + (g2.b - 0.5) * gj) / tn, 0.0, 1.0);
	kl *= 1.0 - mott * 0.5 + mott * pp.g;
	kr *= 1.0 - mott * 0.5 + mott * pp.b;
	kc *= 1.0 - mott * 0.5 + mott * pp2.x;
	ke *= 1.0 - mott * 0.5 + mott * pp2.y;
	if (style == 1) {
		// clean cut: the solid black stays solid (no static in the dark); only the half-tones show the paper
		key *= 1.0 - smoothstep(0.82, 0.95, pp.r) * 0.35 * (1.0 - smoothstep(0.7, 0.95, tone));
	} else if (style == 2) {
		// the black plate: one cut, black or paper, a narrow run of strokes only where the form turns
		float hard = smoothstep(0.47, 0.53, tone + (g.r - 0.5) * 0.04);
		float turn = 1.0 - smoothstep(0.0, 0.12, abs(tone - 0.42));
		key = max(hard, key * turn);
		key = mix(max(key, line), key * (1.0 - line), cut_out);
		kl = step(0.42, cl); kr = step(0.35, cr); kc = step(0.42, cc); ke = step(0.58, ce);
	} else if (style == 4) {
		// pulp: the half-tones are screened in dots, each ink at its own angle, as a cheap press does
		float pitch = 5.0;
		float solid = smoothstep(0.86, 0.96, tone);
		key = max(solid, dots(sph, 0.785, pitch, tone * 1.05));
		key = mix(max(key, line), key * (1.0 - line), cut_out);
		kl = dots(sph, 0.262, pitch, cl * 1.1);
		kr = dots(sph, 1.309, pitch, cr * 1.1);
		kc = dots(sph, 0.0, pitch, cc);
		ke = dots(sph, 1.047, pitch, ce * 1.1);
	} else {
		key *= 0.94 + 0.12 * pp.g;
		// where the paper's tooth is deep, solid ink skips it
		key *= 1.0 - smoothstep(0.78, 0.92, pp.r) * 0.6;
	}
	if (halo > 0.0) {
		// the bulbs bloom: a warm haze of lamp ink round anything burning, laid on the paper and the dark alike
		vec4 bl = bloom(uv, px, 46.0, g.r);
		float h = bl.a * halo * (1.0 - smoothstep(0.85, 1.0, max(texture(scene, uv).r, texture(scene, uv).g)));
		// the haze takes the light's own ink: amber round a bulb, the cold round a tube, red round neon
		float warm = smoothstep(-0.05, 0.12, bl.r - bl.b);
		float red = smoothstep(0.25, 0.45, bl.r - bl.g);
		kl = max(kl, h * warm * (1.0 - red) * 0.85);
		kr = max(kr, h * red * 0.8);
		kc = max(kc, h * (1.0 - warm) * 0.85);
		key *= 1.0 - h * 0.55;
	}
	// late in the night the ink starves: the strokes break up where the paper's rough
	key *= 1.0 - starve * smoothstep(0.35, 0.75, pp.r * 0.6 + g.g * 0.6);

	// nerves: the red comes up in the dark parts, on its own grain
	kr = max(kr, bleed * smoothstep(0.45, 0.9, cn) * (0.55 + 0.45 * g.b));
	// hurt: red at the edges of his sight, thicker with each beat
	vec2 cv = (uv - 0.5) * vec2(aspect, 1.0);
	float rim = smoothstep(0.42, 0.95, length(cv) + (g.b - 0.5) * 0.08);
	kr = max(kr, hurt * rim * (0.75 + 0.25 * pulse));
	key = max(key, hurt * rim * rim * 0.5);

	// a cut coming in: the lamp's plate first, then the earth, the cold, the neon, and the key
	// block last of all, so the place arrives as a printer's proof does
	float fresh = 1.0;
	if (pull < 1.0) {
		kl *= laid(0.0, 0.34, g.g);
		ke *= laid(0.12, 0.46, g2.b);
		kc *= laid(0.24, 0.58, g2.g);
		kr *= laid(0.36, 0.7, g.b);
		fresh = laid(0.62, 0.9, g.r * 0.6 + pp.r * 0.4);
		key *= fresh;
	}

	vec3 col = to_linear(paper) * (0.95 + 0.08 * pp.r);
	col *= 1.0 - kl * (1.0 - to_linear(ink_lamp));
	col *= 1.0 - kr * (1.0 - to_linear(ink_neon));
	col *= 1.0 - kc * (1.0 - to_linear(ink_cold));
	col *= 1.0 - ke * (1.0 - to_linear(ink_earth));
	col *= 1.0 - key * (1.0 - to_linear(ink_night));

	bool paint = style == 3 || style == 5 || style == 6 || style == 12;
	float p_r = style == 5 ? 9.0 : (style == 6 ? 3.0 : 6.0);        // the brush
	float p_ink = style == 5 ? 0.45 : (style == 6 ? 0.12 : 0.3);    // how far towards the inks
	float p_tooth = style == 5 ? 0.26 : (style == 6 ? 0.06 : 0.14);
	float p_line = style == 6 ? 0.45 : 0.8;
	float p_brush = style == 5 ? 0.2 : (style == 6 ? 0.0 : 0.1);
	if (paint && fresh > 0.5) {
		// painted: the room's own colour, smoothed into strokes of paint, pulled towards the press's inks
		// and laid on the same stock; the key block's lines and its deepest dark stay on top
		vec3 sc = painted(uv + o_k * px, px, p_r);
		sc = pow(clamp((sc - levels_in.x) / (levels_in.y - levels_in.x), 0.0, 1.0), vec3(lift * 0.95));
		vec3 lin = to_linear(sc);
		float lum = dot(lin, vec3(0.2126, 0.7152, 0.0722));
		lin = mix(vec3(lum), lin, 1.25);                           // a little richer than the render
		vec3 cp = mix(lin * 1.5, col, p_ink);                    // and leaning to the inks
		cp *= 1.0 - p_tooth * 0.7 + p_tooth * pp.r;               // the board's tooth
		cp *= 1.0 - p_brush * key * (1.0 - smoothstep(0.8, 1.0, tone));   // the brush follows the cutter's strokes
		float shade = smoothstep(0.8, 1.0, tone);
		cp *= 1.0 - shade * 0.6 * (1.0 - to_linear(ink_night));  // the dark goes to the night ink, not grey
		float ln = line * (0.55 + 0.45 * cut_out);
		cp *= 1.0 - ln * p_line * (1.0 - to_linear(ink_night));
		col = cp;
	}
	// film and lenses: the render itself, no ink, graded as a stock or a camera would
	float fg = hash12(floor(FRAGCOORD.xy / 1.5) + vec2(floor(time * 24.0) * 17.0, 3.0));   // grain, a new frame every 1/24 s
	float fg2 = hash12(floor(FRAGCOORD.xy / 1.5) + vec2(7.0, floor(time * 24.0) * 29.0));
	vec2 cv0 = (UV - 0.5) * vec2(asp0, 1.0);
	float rr = length(cv0);
	bool film = style >= 7 && style <= 11;
	if (film) {
		vec3 c = rendered(uv);
		if (style == 7) {
			c = night_stock(uv, px, g.r, FRAGCOORD.xy, frame24, rr, starve);
		} else if (style == 8) {
			// super 8 at night: soft, warm, the blacks gone brown, coarse grain, the gate's round corners
			c = soft(uv, px, 1.6);
			vec4 bl = bloom(uv, px, 40.0, g.r);
			c = sat(c, 1.25) * vec3(1.08, 0.98, 0.82);
			c = c * 0.92 + vec3(0.022, 0.014, 0.008);
			c += vec3(1.0, 0.35, 0.1) * bl.a * 0.38;
			float lg = (fg - 0.5) * 0.16 + (fg2 - 0.5) * 0.06;
			c += lg * (0.1 + 0.9 * sqrt(max(dot(c, vec3(0.33)), 0.0)));
			c *= 1.0 - smoothstep(0.35, 0.95, rr) * 0.7;
			c += vec3(0.9, 0.3, 0.05) * smoothstep(0.55, 1.1, UV.x + (UV.y - 0.5) * 0.3) * 0.06;   // a leak at the edge
			vec2 q = abs(UV - 0.5) * 2.0;
			float gate = smoothstep(1.0, 0.965, max(q.x * 0.985, q.y) + 0.06 * pow(min(q.x, q.y), 6.0));
			c *= gate;
		} else if (style == 9) {
			// a bodycam on his chest: a fisheye, the colour splitting at the edges, the sensor's noise
			// in the dark, the light clipped and the dark crushed by a camera exposing for the street
			vec2 ur = barrel(UV, 0.45, 0.82, asp0);
			vec2 ub = barrel(UV, 0.39, 0.82, asp0);
			c = vec3(rendered(ur).r, c.g, rendered(ub).b);
			c = sat(c, 0.78) * vec3(0.96, 1.0, 1.04);
			c = clamp((c - 0.012) * 1.45, 0.0, 1.0);
			float dark = 1.0 - smoothstep(0.0, 0.18, dot(c, vec3(0.33)));
			c += (vec3(fg, fg2, hash12(FRAGCOORD.xy + time)) - 0.5) * 0.09 * dark;
			c = floor(c * 48.0 + 0.5) / 48.0;                                 // the compression's steps
			c *= 1.0 - smoothstep(0.6, 1.2, rr) * 0.5;
		} else if (style == 10) {
			// the bar's camera over the till: low, grey-green, lines, a frame every so often
			vec2 cell = vec2(3.0) * px;
			vec3 lo = rendered((floor(uv / cell) + 0.5) * cell);
			float l = dot(lo, vec3(0.2126, 0.7152, 0.0722));
			l = smoothstep(0.0, 0.7, pow(l, 0.8));
			c = vec3(l) * vec3(0.78, 0.92, 0.8) + 0.015;
			c *= 0.86 + 0.14 * sin(FRAGCOORD.y * 1.6);
			c += (fg - 0.5) * 0.08;
			c *= 1.0 - smoothstep(0.45, 1.05, rr) * 0.75;
		} else {
			// anamorphic: the frame letterboxed wide, a blue streak through every light, teal and amber
			c += vec3(0.25, 0.55, 1.0) * streak(uv, px) * 0.18;
			vec4 bl = bloom(uv, px, 22.0, g.r);
			c += bl.rgb * bl.a * 0.12;
			float lum = dot(c, vec3(0.33));
			c = mix(c * vec3(0.85, 1.0, 1.1), c * vec3(1.1, 0.98, 0.85), smoothstep(0.05, 0.5, lum));
			c *= 1.0 - smoothstep(0.6, 1.2, rr) * 0.4;
			c += (fg - 0.5) * 0.02;
			float bars = max(0.0, 1.0 - asp0 / max(2.39 * min(asp0 / 1.6, 1.0), asp0 * 1.38)) * 0.5;   // 2.39 when the picture has the whole screen; narrower beside the page
			c *= step(bars, UV.y) * step(UV.y, 1.0 - bars);
		}
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) c = vec3(0.0);
		// drink: the picture doubles, the second image drifting with the plates
		vec3 ghost = rendered(uv + o_l * px * 2.5);
		c = mix(c, ghost / (ghost + 0.6) * 1.6, 0.35 * clamp(slip / 3.0, 0.0, 1.0));
		// nerves: red comes up in the dark; hurt: red at the edge of his sight, thicker on each beat
		float lumc = dot(c, vec3(0.33));
		c = mix(c, c * vec3(1.6, 0.55, 0.5) + vec3(0.012, 0.0, 0.0), bleed * (1.0 - smoothstep(0.0, 0.2, lumc)) * 0.8);
		c = mix(c, vec3(0.2, 0.008, 0.008), clamp(hurt * rim * (0.75 + 0.25 * pulse), 0.0, 1.0) * 0.85);
		c *= 1.0 + pulse * 0.035;
		c = sat(c, 1.0 - 0.35 * starve);
		// a cut: the film fades up from black, and goes to black for the cut
		c *= smoothstep(0.0, 1.0, pull) * (1.0 - smoothstep(0.1, 0.9, flash));
		col = max(c, vec3(0.0));
	}
	if (style == 12 && fresh > 0.5) {
		// painted on night stock: the paint, then the film's halation and grain over it
		vec4 bl = bloom(uv, px, 30.0, g.r);
		col += vec3(1.0, 0.22, 0.06) * bl.a * 0.22;
		col = mix(col, col * vec3(0.86, 0.97, 1.1), 1.0 - smoothstep(0.0, 0.2, dot(col, vec3(0.33))));
		col += (fg - 0.5) * 0.035 * (0.4 + sqrt(max(dot(col, vec3(0.33)), 0.0)));
		col *= 1.0 - smoothstep(0.6, 1.2, rr) * 0.35;
	}
	if (twice > 0.5 && fresh > 0.5) {
		vec3 k = to_linear(ink_night);
		col = to_linear(paper) * k * k * 5.0;
	}
	if (clean > 0.5 && fresh > 0.5 && !film) {
		// printed clean: the thing's colours as they are, on the same paper, its outline still cut
		vec3 sc = to_linear(clamp(texture(scene, uv).rgb * 1.08, 0.0, 1.0));
		vec3 cc = to_linear(paper) * (0.96 + 0.05 * pp.r) * mix(vec3(1.0), sc / max(to_linear(paper), vec3(0.2)), 0.97);
		float ln = line * 0.85;
		cc *= 1.0 - ln * (1.0 - to_linear(ink_night));
		col = cc;
	}
	// the page going blank: the paper comes up through the ink, through its tooth first
	float blank = smoothstep(pp.r * 0.5 + g.g * 0.5 - 0.22, pp.r * 0.5 + g.g * 0.5 + 0.02, flash * 1.3 - 0.25);
	if (!film) col = mix(col, to_linear(paper) * (0.95 + 0.08 * pp.r), blank);
	COLOR = vec4(to_srgb(col), 1.0);
}
