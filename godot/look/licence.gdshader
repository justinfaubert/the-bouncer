// The face of a licence in his hand. It draws twice, like every surface (look/surface.gdshader):
// for the press it asks to be printed clean, its own colours straight onto the paper; for the eye
// it's the card, and over it the laminate and the hologram.
//
// The hologram is a picture drawn once in the darkroom (game/props.gd, _card_holo): a field of
// waves, the seal over the corner of the photo, the face again, and the birthday in a line of tiny
// print. Under the laminate it's foil, ruled as a grating, and only the foil lights: the card
// between its lines stays the card. Away from the lamp it's a pale outline in the laminate. Tip
// the card toward the lamp and the foil wakes, and each part of it sends the lamp back as a colour
// that depends on the tip: its grating runs its own way and catches at its own point in the tip
// (game/props.gd sets both), so the seal's rings light one after another and a light runs round
// them as the card turns, the waves ripple down the card, the face comes and goes, and the colours
// slide through the spectrum. Right at the lamp's angle the foil is a mirror for a moment.
//
// Bright, but not past the press: the foil's lines stay under what the eye blooms and what the
// press prints as bare paper (game/view.gd, look/press.gdshader), or the detail washes out to a
// gleam, which is what it did before.
//
// A printed one is ink, not foil: its colours are where the printer put them, flat, and they sit
// there however the card is tipped.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform sampler2D face_tex : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
// r how much foil, g which way its grating runs (a turn, 0..1), b where in a tip it catches
uniform sampler2D holo_tex : hint_default_black, filter_linear_mipmap_anisotropic;
uniform float emission_energy = 0.32;
uniform float foil = 1.0;                              // 0 no hologram at all
uniform bool printed = false;                          // a printed hologram: ink that doesn't move
uniform float lines = 1.0;
// the lamp the foil catches, in his eye's space. game/props.gd keeps it where the card meets it at
// the same small tip of the wrist however he's holding it (SWEET there)
uniform vec3 lamp = vec3(-0.15, 0.35, 0.92);

const uint MASK_LAYER = 524288u;                       // visual layer 20: only the mask camera
// how far from the lamp's angle the foil still wakes (the tip's half vector, along the card)
const float WAKE = 0.2;

varying vec3 card_x;                                   // the card's own across and up, in his eye's space
varying vec3 card_y;

vec3 mask_out(vec3 v) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return v;
#else
	return mix(v / 12.92, pow((v + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), v));
#endif
}

// the colours a grating sends back, one turn of x round the wheel
vec3 rainbow(float x) {
	return clamp(abs(fract(x + vec3(0.0, 0.6667, 0.3333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void vertex() {
	card_x = (MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	card_y = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}

void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u) {
		// red exactly 1: print clean
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		EMISSION = mask_out(vec3(1.0, lines, 0.0));
	} else {
		vec3 base = texture(face_tex, UV).rgb;
		vec4 hg = texture(holo_tex, UV);
		vec3 v = normalize(VIEW);
		vec3 n = normalize(NORMAL);
		// half way between the lamp and his eye, laid along the card: nothing where this point of
		// the foil is at the mirror angle, and more the further it's tipped from it
		vec3 hv = normalize(normalize(lamp) + v);
		vec2 d = vec2(dot(hv, normalize(card_x)), dot(hv, normalize(card_y)));
		// where on the card, in card widths from the middle, up positive
		vec2 p = vec2(UV.x - 0.5, (0.5 - UV.y) * 0.631);
		float amount = clamp(hg.r * foil, 0.0, 1.0);
		vec3 shine = vec3(0.0);
		float cover = 0.0;
		float gloss = pow(max(dot(hv, n), 0.0), 220.0) * 0.05;
		if (printed) {
			// ink: the colours are fixed to the card, flat and a little dull
			vec3 ink = mix(rainbow(hg.b * 0.8 + dot(p, vec2(0.6, 0.4))), vec3(0.6), 0.45);
			base = mix(base, base * mix(vec3(1.0), ink, 0.75), amount);
		} else {
			// the eye's angle drifts a little across the card (he's holding it close); the foil
			// makes more of it, so the light moves over the card as well as through it
			vec2 dd = d - p * 0.12;
			// how awake the foil is: the card toward the lamp, give or take a tip of the wrist
			float wake = exp(-dot(dd, dd) / (WAKE * WAKE));
			// this bit of foil's grating: the tip along it is what it answers to
			float ang = hg.g * 6.28318;
			float along = dot(dd, vec2(cos(ang), sin(ang)));
			// it catches at its own point in the tip, so the parts light one after another
			float kin = 0.5 + 0.5 * cos(6.28318 * (along * 2.4 - hg.b));
			float lit = amount * wake * (0.35 + 0.65 * kin);
			// the colour it sends back runs through the spectrum as the card tips; a foil's
			// colours have silver in them
			vec3 col = mix(rainbow(along * 2.8 + hg.b * 0.7 + dot(p, vec2(0.25, 0.15))), vec3(1.0), 0.12);
			// right at the lamp's angle: the mirror, a flash of the lamp itself in the foil
			float flash = exp(-dot(dd, dd) / (0.05 * 0.05));
			col = mix(col, vec3(1.0, 0.97, 0.9), flash * 0.3);
			// where the foil lights it's the foil you see, not the print under it
			cover = lit * 0.75;
			shine = col * lit * 1.1;
			// and the print looks the darker for it, the way a page does beside a light
			base *= 1.0 - 0.12 * wake * foil;
			// the laminate: a faint sheen where the lamp's caught, never enough to hide the print
			shine += vec3(0.9, 0.93, 1.0) * foil * flash * 0.04;
			// and away from the lamp the pictures are still there, paler lines in the laminate
			shine += vec3(0.86, 0.89, 0.93) * amount * 0.08 * (1.0 - wake);
		}
		ALBEDO = base * (1.0 - cover);
		ROUGHNESS = 0.45;
		SPECULAR = 0.35;
		EMISSION = base * emission_energy * (1.0 - cover) + shine + vec3(gloss);
	}
}
