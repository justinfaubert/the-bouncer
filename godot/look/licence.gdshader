// The face of a licence in his hand. It draws twice, like every surface (look/surface.gdshader):
// for the press it asks to be printed clean, its own colours straight onto the paper; for the eye
// it's the card, and over it the laminate and the hologram.
//
// The hologram is a picture drawn once in the darkroom (game/props.gd, _card_holo): a field of
// small waves, the seal over the corner of the photo, the face again, and the birthday in a line of
// tiny print. Under the laminate it's a foil that splits the light. Away from the lamp it's only a
// paler outline in the laminate. Tip the card toward the lamp and the foil wakes: each part of it
// sends the light back as a colour that depends on the angle between the lamp, the card and his
// eye, so the colours run through the spectrum as the card tips, and a bright band crosses the card
// where the foil sits at the mirror angle. A printed one is ink, not foil: its colours are where
// the printer put them, and they sit there however the card is tipped.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform sampler2D face_tex : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
// r how much foil, g which way its grating runs (a turn, 0..1), b where its colours start
uniform sampler2D holo_tex : hint_default_black, filter_linear_mipmap_anisotropic;
uniform float emission_energy = 0.32;
uniform float foil = 1.0;                              // 0 no hologram at all
uniform bool printed = false;                          // a printed hologram: ink that doesn't move
uniform float lines = 1.0;
// the lamp the foil catches, in his eye's space. game/props.gd keeps it where the card meets it at
// the same small tip of the wrist however he's holding it (SWEET there)
uniform vec3 lamp = vec3(-0.15, 0.35, 0.92);

const uint MASK_LAYER = 524288u;                       // visual layer 20: only the mask camera
// the way the bright band crosses the card as it tips (across the card and up it)
const vec2 SWEEP = vec2(0.857, 0.514);

varying vec3 card_x;                                   // the card's own across and up, in his eye's space
varying vec3 card_y;

vec3 mask_out(vec3 v) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return v;
#else
	return mix(v / 12.92, pow((v + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), v));
#endif
}

// a foil's spectrum: not a prism's full saturation; there's silver in it
vec3 spectrum(float x) {
	vec3 c = 0.5 + 0.5 * cos(6.28318 * (x + vec3(0.0, 0.333, 0.667)));
	return mix(vec3(0.8), c, 0.82);
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
		float gloss = pow(max(dot(hv, n), 0.0), 220.0) * 0.12;
		if (printed) {
			// ink: the colours are fixed to the card, flat and a little dull
			vec3 ink = spectrum(hg.g + hg.b + dot(p, vec2(0.6, 0.4)));
			base = mix(base, base * mix(vec3(1.0), ink + 0.25, 0.5), amount);
		} else {
			// the whole foil warms as the card comes round to the lamp
			float glow = exp(-dot(d, d) / (0.24 * 0.24));
			// the band, where the foil is at the mirror angle. The angle already changes a little
			// across the card (his eye is near it); the print makes more of it, so a tip of the
			// wrist carries the band from one edge to the other
			float across = dot(d - p * 0.3, SWEEP);
			float band = exp(-across * across / (0.055 * 0.055));
			// the grating: each part of the foil runs its own way, so one tip lights the seal one
			// colour and the waves another
			float ang = hg.g * 6.28318;
			float phase = dot(d, vec2(cos(ang), sin(ang))) * 4.0 + hg.b + dot(p, vec2(0.25, 0.15));
			float lit = amount * (0.3 * glow + band * (0.35 + 0.65 * glow));
			// where the foil shines it's the foil you see, not the print under it
			cover = clamp(lit * 0.55, 0.0, 0.7);
			shine = spectrum(phase) * lit * 0.9;
			// the laminate itself is foil, thinly, all over: where the band crosses it there's a
			// rainbow over the whole card, under the pictures
			float film = foil * (band * (0.35 + 0.65 * glow) + 0.25 * glow);
			shine += spectrum(dot(d, vec2(0.6, 0.8)) * 4.0 + dot(p, vec2(0.5, 0.3)) + 0.4) * film * 0.2;
			// and away from the lamp the pictures are still there, paler lines in the laminate
			shine += vec3(0.86, 0.89, 0.93) * amount * 0.06;
			gloss += band * 0.02;
		}
		ALBEDO = base * (1.0 - cover);
		ROUGHNESS = 0.3;
		SPECULAR = 0.5;
		EMISSION = base * emission_energy * (1.0 - cover) + shine + vec3(gloss);
	}
}
