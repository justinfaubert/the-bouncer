// Rain streaks: lit by whatever's near, drawn for the eye only.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.9, 0.9, 0.95, 0.5);

const uint MASK_LAYER = 524288u;

void vertex() {
	// upright, turned to face the camera
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & MASK_LAYER) != 0u) {
		discard;
	}
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
	ROUGHNESS = 0.2;
}
