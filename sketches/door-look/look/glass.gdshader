// Glass, and anything else see-through (the rain on the door, drinks). The eye sees it; the press
// doesn't cut it, so the mask camera looks straight through.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.7, 0.75, 0.8, 0.15);
uniform float roughness = 0.06;
uniform float metallic = 0.3;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap;   // lettering on the glass

const uint MASK_LAYER = 524288u;

void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u) {
		discard;
	}
	vec4 t = texture(albedo_tex, UV);
	ALBEDO = albedo.rgb * t.rgb;
	ALPHA = albedo.a * t.a;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission.rgb * emission_energy;
}
