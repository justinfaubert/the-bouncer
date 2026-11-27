// Retroreflective: the reflector on a post, the cat's eyes down the middle, a sign's face. Dull
// till a pair of headlamps finds it, then it gives the light straight back at them, brightest
// near the beam's middle and the nearer the brighter. game/truck.gd keeps the lamps' place and
// aim in the globals each frame (lamp_eye: where, w 1 when they're on; lamp_fwd: the aim, w 1 on
// high beam).
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

global uniform vec4 lamp_eye;
global uniform vec4 lamp_fwd;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float base = 0.03;       // what it is in the dark: just there
uniform float gain = 4.0;        // what it gives back in the middle of the beam, close

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 to = wpos - lamp_eye.xyz;
	float d = max(length(to), 0.5);
	float high = lamp_fwd.w;
	float spread = mix(0.82, 0.9, high);                 // the cone: about 35 degrees low, 25 high
	float cone = smoothstep(spread, 1.0, dot(to / d, lamp_fwd.xyz));
	float reach = mix(55.0, 120.0, high);
	float fall = 1.0 / (1.0 + (d / reach) * (d / reach) * 3.0);
	float k = base + lamp_eye.w * cone * fall * gain;
	ALBEDO = tint.rgb * k;
}
