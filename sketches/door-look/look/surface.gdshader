// A surface in the room. It draws twice. For the eye it's an ordinary lit surface. For the press
// (the mask camera, which sees visual layer 20) it draws how the key block is cut here: a
// threshold for the night ink that makes strokes stuck to the surface, the way a lino cutter
// follows a form, and how strongly its edges take a line.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform int mapping = 0;              // 0 the mesh's own UVs, 1 projected from the world (walls, floors)
uniform float tex_size = 1.0;         // metres per repeat of the texture when projected
uniform float roughness = 0.9;
uniform float metallic = 0.0;
uniform float specular = 0.5;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform sampler2D emission_tex : source_color, hint_default_white, filter_linear_mipmap;   // a screen's picture
// below split_y (world metres) a second surface: the wainscot under the plaster, with a rail on top
uniform float split_y = -1000.0;
uniform vec4 albedo2 : source_color = vec4(1.0);
uniform sampler2D albedo_tex2 : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 rail : source_color = vec4(0.25, 0.16, 0.1, 1.0);
uniform float rail_h = 0.07;
// the floor's wear: a map of the room from above, 0 where the pile is whole, 1 where it's walked
// down to the backing
uniform sampler2D wear_tex : hint_default_black, filter_linear;
uniform vec4 wear_rect = vec4(0.0);   // the map's corner (x, z) and its width and depth in metres; 0 wide: none
uniform vec4 worn : source_color = vec4(0.4, 0.35, 0.29, 1.0);
// a cut-out (tape with torn ends): the texture's alpha below this is a hole, to the eye and the press
uniform float alpha_scissor = 0.0;

// the cut: 0 strokes at a constant height (walls, people), 1 strokes along the floor in cut_dir,
// 2 strokes across the object's own cut_dir (it turns with the object), 3 no strokes: the key
// block is solid or cut away, nothing between (lights, signs, screens)
uniform int cut = 0;
uniform vec3 cut_dir = vec3(0.0, 1.0, 0.0);
uniform float cut_px = 7.0;           // how far apart the strokes are on the screen, in pixels
uniform float lines = 1.0;            // how strongly this surface's edges and creases draw

const uint MASK_LAYER = 524288u;      // visual layer 20: only the mask camera sees it

varying vec3 world_pos;
varying vec3 world_nrm;
varying vec3 local_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_pos = VERTEX;
}

vec3 mask_out(vec3 v) {
	// the mask camera stores what we emit; Compatibility keeps it linear, the others encode it
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return v;
#else
	return mix(v / 12.92, pow((v + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), v));
#endif
}

float tri(float x) {
	return abs(fract(x) - 0.5) * 2.0;     // 0 on the stroke's spine, 1 halfway to the next
}

void fragment() {
	if (alpha_scissor > 0.0 && texture(albedo_tex, UV).a < alpha_scissor) {
		discard;
	}
	if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u) {
		float t = 0.5;
		if (cut < 3) {
			vec3 d = normalize(cut_dir);
			float f;
			if (cut == 0 && abs(world_nrm.y) < 0.75) {
				f = world_pos.y;
			} else if (cut == 0) {
				f = dot(world_pos, vec3(0.958, 0.0, 0.287));    // tops and seats: strokes like the floor's
			} else if (cut == 1) {
				f = dot(world_pos, d);
			} else {
				f = dot(local_pos, d);
			}
			// keep the strokes cut_px apart on the screen at any distance: pick the two nearest
			// octaves of spacing and blend them, the way an engraver adds a line between two
			float fw = max(length(vec2(dFdx(f), dFdy(f))), 1e-6);
			float l = log2(fw * cut_px);
			float s0 = exp2(floor(l));
			t = mix(tri(f / s0), tri(f / (2.0 * s0)), fract(l));
		}
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		EMISSION = mask_out(vec3(t, lines, 0.0));
	} else {
		vec3 col;
		if (mapping == 1) {
			// projected from the world three ways, blended by which way the surface faces; the
			// picture's up is the world's up on walls
			vec3 w = pow(abs(world_nrm), vec3(4.0));
			w /= w.x + w.y + w.z;
			vec3 p = world_pos / tex_size;
			vec2 uz = vec2(p.z, -p.y), uy = p.xz, ux = vec2(p.x, -p.y);
			bool low = world_pos.y < split_y && abs(world_nrm.y) < 0.75;
			if (low) {
				col = albedo2.rgb * (texture(albedo_tex2, uz).rgb * w.x + texture(albedo_tex2, uy).rgb * w.y + texture(albedo_tex2, ux).rgb * w.z);
			} else {
				col = albedo.rgb * (texture(albedo_tex, uz).rgb * w.x + texture(albedo_tex, uy).rgb * w.y + texture(albedo_tex, ux).rgb * w.z);
			}
			// the rail along the top of the wainscot: a moulding, lit on its top, shaded under
			float r = (world_pos.y - split_y) / rail_h;
			if (r > 0.0 && r < 1.0 && abs(world_nrm.y) < 0.75) {
				col = rail.rgb * mix(0.55, 1.25, smoothstep(0.1, 0.9, r)) * (r > 0.85 ? 1.3 : 1.0);
			}
			// walked flat, the pile goes pale and loses its colour; walked through, it's the
			// backing, with a ghost of the pattern
			if (wear_rect.z > 0.0 && world_nrm.y > 0.75) {
				float k = texture(wear_tex, (world_pos.xz - wear_rect.xy) / wear_rect.zw).r;
				float lum = dot(col, vec3(0.3, 0.59, 0.11));
				col = mix(col, mix(vec3(lum), col, 0.55) * vec3(1.25, 1.15, 1.05), smoothstep(0.0, 0.45, k));
				col = mix(col, worn.rgb * (0.85 + lum), smoothstep(0.45, 0.95, k));
			}
		} else {
			col = albedo.rgb * texture(albedo_tex, UV).rgb;
		}
		ALBEDO = col;
		ROUGHNESS = roughness;
		METALLIC = metallic;
		SPECULAR = specular;
		EMISSION = emission.rgb * emission_energy * texture(emission_tex, UV).rgb;
	}
}
