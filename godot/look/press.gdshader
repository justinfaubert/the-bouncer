// The press. Prints what his eyes see in three inks on cream stock, every frame:
//
//   night  the key block, blue-black. Solid in the dark, cut away in the light. Its mid-tones are
//          strokes that follow the surfaces (the mask camera draws where they run), and its lines
//          are the room's edges: printed in ink where it's light, cut out of the ink where it's dark.
//   lamp   amber, for every warm light: the pendants, the lamp over the door, the lot's sodium.
//   neon   red, for the sign, the jukebox, tail lights. And blood.
//
// Light is paper: where the light is brightest, nothing prints. The colour of the light picks the
// ink (press/separation.png, from tools/press.py). The grain, the paper and the plates' wander
// are pinned to directions round his head, not to the screen, so they hold still as he looks round.
shader_type canvas_item;

uniform sampler2D scene : filter_linear;              // the eye's picture
uniform sampler2D cut_mask : filter_nearest;          // r the key block's cut, g line weight, b lines
uniform sampler2D separation : filter_linear;         // rendered colour -> ink coverage
uniform sampler2D grain : filter_linear, repeat_enable;
uniform sampler2D paper_tex : filter_linear, repeat_enable;

uniform vec3 paper : source_color = vec3(0.918, 0.886, 0.812);
uniform vec3 ink_night : source_color = vec3(0.106, 0.129, 0.188);
uniform vec3 ink_lamp : source_color = vec3(0.941, 0.635, 0.235);
uniform vec3 ink_neon : source_color = vec3(0.851, 0.220, 0.173);

uniform vec2 view_px = vec2(1258.0, 1080.0);
uniform vec2 levels_in = vec2(0.0, 0.92);            // the render's black and white points
uniform float lift = 0.72;                           // opens up the shadows: the room is darker than a print wants
uniform float tints = 4.0;                           // steps of tint on the colour plates
uniform vec2 reg_lamp = vec2(0.9, -0.6);             // the press's own misregistration, in pixels
uniform vec2 reg_neon = vec2(-0.7, 0.8);
uniform float slip = 0.0;                            // drink: the plates wander, in pixels
uniform float time = 0.0;

// his body, in the print (game/view.gd): nothing here is a meter; it's how the picture is printed
uniform float bleed = 0.0;                           // nerves: the red comes up in the dark
uniform float hurt = 0.0;                            // hurt: red thickens at the edges of his sight
uniform float pulse = 0.0;                           // his heart, 0..1 on each beat: the ink swells
uniform float starve = 0.0;                          // late: the ink runs thin and the strokes break
uniform float flash = 0.0;                           // a cut between places: the page goes blank

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
vec3 separate(vec3 c) {
	const float n = 33.0;
	c = pow(clamp((c - levels_in.x) / (levels_in.y - levels_in.x), 0.0, 1.0), vec3(lift)) * (n - 1.0);
	float b0 = floor(c.b);
	float b1 = min(b0 + 1.0, n - 1.0);
	vec2 a = vec2((b0 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	vec2 b = vec2((b1 * n + c.r + 0.5) / (n * n), (c.g + 0.5) / n);
	return mix(texture(separation, a).rgb, texture(separation, b).rgb, c.b - b0);
}

void fragment() {
	vec2 uv = UV;
	vec2 px = 1.0 / view_px;

	// where this pixel looks, as a direction round his head: the grain and the paper live there
	vec2 ndc = vec2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
	float aspect = view_px.x / view_px.y;
	vec3 ray = cam_basis * normalize(vec3(ndc.x * tan_half_fov * aspect, ndc.y * tan_half_fov, -1.0));
	vec2 sph = vec2(atan(ray.x, ray.z), asin(clamp(ray.y, -1.0, 1.0))) * px_per_rad;
	vec3 g = texture(grain, sph / (128.0 * grain_px)).rgb;          // one grain screen per ink
	vec3 pp = texture(paper_tex, sph / (512.0 * paper_px)).rgb;     // r tooth and fibre, g and b mottle

	// the plates, each where the press put it
	vec2 wander = slip * vec2(sin(time * 0.61 + 1.7), cos(time * 0.47 + 0.3));
	vec2 o_k = wander * 0.35;
	vec2 o_l = reg_lamp + slip * vec2(sin(time * 0.37 + 4.1), cos(time * 0.71 + 2.2));
	vec2 o_r = reg_neon + slip * vec2(cos(time * 0.53 + 0.9), sin(time * 0.29 + 5.0));
	float cn = separate(texture(scene, uv + o_k * px).rgb).r;
	float cl = separate(texture(scene, uv + o_l * px).rgb).g;
	float cr = separate(texture(scene, uv + o_r * px).rgb).b;
	vec4 m = texture(cut_mask, uv + o_k * px);
	// a story object, printed clean: its own picture straight onto the paper, no strokes or grain
	float clean = step(0.97, m.r);

	// the key block: strokes whose width is the tone, cut with a slightly wandering hand
	const float aa = 0.1;
	float T = clamp(m.r / 0.9 + (g.r - 0.5) * 0.18 - pulse * 0.07, 0.0, 1.0);
	T = aa + T * (1.0 - 2.0 * aa);
	float key = smoothstep(T - aa, T + aa, cn);

	// its lines: left standing in the light, cut out of the block in the dark
	vec3 around = texture(scene, uv + (o_k + vec2(3.0, 2.0)) * px).rgb + texture(scene, uv + (o_k + vec2(-3.0, -2.0)) * px).rgb
		+ texture(scene, uv + (o_k + vec2(-2.0, 3.0)) * px).rgb + texture(scene, uv + (o_k + vec2(2.0, -3.0)) * px).rgb;
	float dark = separate(around * 0.25).r;
	// the gouge skips now and then
	float line = m.b * smoothstep(0.08, 0.3, m.b * (0.75 + 0.5 * g.b));
	key = max(key, line * (1.0 - smoothstep(0.45, 0.7, dark)));
	key *= 1.0 - line * smoothstep(0.55, 0.8, dark);

	// the colour plates: flat tints in a few steps, the edges between steps grainy, the ink a
	// little uneven
	float kl = clamp(floor(cl * tints + 0.5 + (g.g - 0.5) * 0.9) / tints, 0.0, 1.0);
	float kr = clamp(floor(cr * tints + 0.5 + (g.b - 0.5) * 0.9) / tints, 0.0, 1.0);
	kl *= 0.88 + 0.24 * pp.g;
	kr *= 0.88 + 0.24 * pp.b;
	key *= 0.94 + 0.12 * pp.g;
	// where the paper's tooth is deep, solid ink skips it
	key *= 1.0 - smoothstep(0.78, 0.92, pp.r) * 0.6;
	// late in the night the ink starves: the strokes break up where the paper's rough
	key *= 1.0 - starve * smoothstep(0.35, 0.75, pp.r * 0.6 + g.g * 0.6);

	// nerves: the red comes up in the dark parts, on its own grain
	kr = max(kr, bleed * smoothstep(0.45, 0.9, cn) * (0.55 + 0.45 * g.b));
	// hurt: red at the edges of his sight, thicker with each beat
	vec2 cv = (uv - 0.5) * vec2(aspect, 1.0);
	float rim = smoothstep(0.42, 0.95, length(cv) + (g.b - 0.5) * 0.08);
	kr = max(kr, hurt * rim * (0.75 + 0.25 * pulse));
	key = max(key, hurt * rim * rim * 0.5);

	vec3 col = to_linear(paper) * (0.95 + 0.08 * pp.r);
	col *= 1.0 - kl * (1.0 - to_linear(ink_lamp));
	col *= 1.0 - kr * (1.0 - to_linear(ink_neon));
	col *= 1.0 - key * (1.0 - to_linear(ink_night));

	if (clean > 0.5) {
		// printed clean: the thing's colours as they are, on the same paper, its outline still cut
		vec3 sc = to_linear(clamp(texture(scene, uv).rgb * 1.08, 0.0, 1.0));
		vec3 cc = to_linear(paper) * (0.96 + 0.05 * pp.r) * mix(vec3(1.0), sc / max(to_linear(paper), vec3(0.2)), 0.97);
		float ln = line * 0.85;
		cc *= 1.0 - ln * (1.0 - to_linear(ink_night));
		col = cc;
	}
	col = mix(col, to_linear(paper) * (0.95 + 0.08 * pp.r), flash);
	COLOR = vec4(to_srgb(col), 1.0);
}
