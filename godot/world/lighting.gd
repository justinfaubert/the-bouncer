class_name Lighting
# The light done the way a game of this decade does it, where the machine can: occlusion in the
# corners and under things, light bounced off the walls and carrying their colour, haze the lamps
# shine through, shadows soft by how big the lamp is and how far the shadow falls. All of it needs
# the Forward+ renderer (the desktop builds). The browser build stays on Compatibility, which has
# none of it, and keeps the room as it was lit before: everything here asks `rich` first.

# Forward+ or Mobile: the renderer has the screen-space and volumetric passes
static var rich := RenderingServer.get_current_rendering_method() != "gl_compatibility"

# with bounced light doing its work, the flat ambient that stood in for it drops to this share
const AMBIENT_K := 0.15
# and the lamps come up a little, so their pools print in the lamp ink, not the earth (the exposure
# stays: raising it turned the jukebox's red and the balls on the felt to white)
const LAMP_K := 1.1
# the hanging lamps over the tables and the bar: tighter cones, so brighter in them
const SPOT_K := 2.0
const EXPOSURE_K := 1.0
# the press's lift at night (look/press.gdshader, 0.72 on Compatibility): nearer 1 keeps the dark dark
const LIFT := 0.78
# the light from his own eyes on the people (game/view.gd, 0.45 on Compatibility): with it at full,
# the kid at the door printed pale as paper
const EYE_FILL := 0.15

# Old incandescent bulbs, all of them: about 2700 K, amber and a little orange, nothing near white.
# Every warm lamp paler than that is pulled most of the way there (the table lamps' ffb865 already is
# one); the pool lamp's white goes a little warm. Redder than this, and lit wood prints in the
# earth ink instead of the lamp's.
const INCANDESCENT := Color("ffb25e")
const BULB_K := 0.55
const SATURATION := 1.0


# for side-by-sides: LAST_CALL_LIGHT_OFF=ssao,ssil,sdfgi,fog in the environment turns those off
static func _off(what: String) -> bool:
	return what in OS.get_environment("LAST_CALL_LIGHT_OFF").split(",")


static func environment(env: Environment) -> void:
	if not rich:
		return
	# the corners and the undersides: a table's shadow on the carpet, the join of wall and floor,
	# the dark inside a coat's folds
	env.ssao_enabled = not _off("ssao")
	env.ssao_radius = 1.1
	env.ssao_intensity = 2.2
	env.ssao_power = 1.5
	env.ssao_detail = 0.7
	env.ssao_light_affect = 0.15
	# the light off the walls: the jukebox's red on the floor in front of it, the pool lamp's
	# white off the felt and up under the brims, the wood's warmth on faces at the bar
	env.ssil_enabled = not _off("ssil")
	env.ssil_radius = 3.0
	env.ssil_intensity = 1.4
	# (SDFGI was tried: it carries the screens' and the cooler's green over the whole room, and the
	# print turns that into the cold ink everywhere; the flat ambient at AMBIENT_K stands in instead)
	# the press picks its inks by the colour of the light, and was tuned on Compatibility's picture;
	# Forward+'s wider range comes out paler, the jukebox's red salmon, so the colour goes back in
	env.adjustment_enabled = true
	env.adjustment_saturation = SATURATION
	# Forward+ glows harder than Compatibility at the same settings: only what's really bright blooms
	env.glow_hdr_threshold = 1.3
	env.glow_intensity = 0.4
	# the wet: the lot's puddles and the bar top, where the lamps and the sign lie in them
	env.ssr_enabled = not _off("ssr")
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.2
	env.ssr_fade_out = 2.5
	# the air: smoke that isn't allowed any more and still hangs, breath, the fryer
	env.volumetric_fog_enabled = not _off("fog")
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_albedo = Color("e0d6c6")
	env.volumetric_fog_emission = Color(0, 0, 0)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 28.0
	env.volumetric_fog_detail_spread = 1.5
	env.volumetric_fog_ambient_inject = 0.0
	env.volumetric_fog_sky_affect = 0.0

# how far from him a lamp still throws a shadow (Compatibility: 7.5 m, world/pub.gd)
const SHADOW_REACH := 13.0

# By name (world/pub.gd's `lights`): how much each lamp lights the haze, and how big its bulb is,
# in metres, which is how soft its shadows come out. A pool lamp's long tube throws soft shadows,
# a bare bulb hard ones.
const HAZE := {"pool": 2.6, "door_lamp": 0.3, "sodium": 2.4, "sign": 1.2, "roof_sign": 1.0, "keg": 1.3,
	"deck": 1.4, "upstairs": 1.0, "hall": 0.7, "kitchen": 0.7, "juke": 0.3, "tv": 0.8, "back_bar": 0.0,
	"store": 1.2, "desk_lamp": 0.6, "lobby": 0.4, "heat_lamp": 0.8}
const SIZE := {"pool": 0.15, "door_lamp": 0.06, "sodium": 0.15, "sign": 0.5, "keg": 0.03, "deck": 0.04,
	"upstairs": 0.03, "hall": 0.25, "kitchen": 0.25, "back_bar": 0.0, "tv": 0.4, "juke": 0.3}


# haze pockets: [half size, density], hung just under the lamp
const POCKETS := {"pool": [Vector3(1.6, 1.0, 1.0), 0.05],
	"sodium": [Vector3(6.0, 4.0, 6.0), 0.03], "deck": [Vector3(2.0, 1.4, 2.0), 0.035],
	"upstairs": [Vector3(1.6, 1.0, 1.6), 0.02]}


# lamps that run hot with the exposure up and nothing flat to hide them: the back bar's lamp, close
# over the bottles, burnt the top shelf to bare paper
const ENERGY_K := {"back_bar": 0.4, "juke": 0.75, "door_lamp": 0.6, "pool": 1.6}
# the vestibule's second lamp has no name; anything this near the door is turned down with it
# the lights out of doors keep their reach: a sodium lamp lights the whole lot
const OUTDOORS := ["sodium", "sign", "roof_sign", "store"]
const DOOR := Vector3(2.3, 2.0, 8.6)


static func _haze(pub: Node, li: Light3D, half: Vector3, density: float) -> void:
	var v := FogVolume.new()
	v.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	v.size = half * 2.0
	var fm := FogMaterial.new()
	fm.density = density
	fm.albedo = Color("e8e0d2")
	fm.edge_fade = 0.6
	v.material = fm
	pub.add_child(v)
	v.global_position = li.global_position - Vector3(0, half.y * 0.85, 0)


# the reds that glow: in Forward+'s wider range a bright red goes pink and then white before the
# press sees it, and the press only prints red for a deep red. These glow at this share instead.
const GLOW_CAP := 1.6
const RED_GLOW := {"neon": 0.45, "juke": 0.45, "tail": 0.5, "exit": 0.5}


static func dress(pub: Node) -> void:
	if not rich or _off("dress"):
		return
	# Compatibility clips a glowing bulb at white; Forward+ keeps all of it and the glow blooms it
	# into a ball the size of a shelf, so the brightest glows are pressed down towards white
	for k in pub.M:
		var g = pub.M[k]
		if g is ShaderMaterial and g.get_shader_parameter("emission_energy") != null:
			var e := float(g.get_shader_parameter("emission_energy"))
			if e > GLOW_CAP:
				g.set_shader_parameter("emission_energy", GLOW_CAP + (e - GLOW_CAP) * 0.15)
	# the bulbs and shades themselves glow amber
	for k in ["lamp", "bulb", "shade", "window_lit", "far"]:
		var gm: ShaderMaterial = pub.M.get(k)
		if gm != null:
			var ev = gm.get_shader_parameter("emission")
			if not ev is Color:
				continue
			var ec: Color = ev
			gm.set_shader_parameter("emission", ec.lerp(INCANDESCENT, 0.55))
			gm.set_shader_parameter("albedo", ec.lerp(INCANDESCENT, 0.55))
	for k in RED_GLOW:
		var m: ShaderMaterial = pub.M.get(k)
		if m != null:
			m.set_shader_parameter("emission_energy", float(m.get_shader_parameter("emission_energy")) * RED_GLOW[k])
	var named := {}
	for k in pub.lights:
		named[pub.lights[k]] = k
	for l in pub.find_children("*", "Light3D", true, false):
		var li := l as Light3D
		if li is DirectionalLight3D:
			li.light_angular_distance = 1.5   # the sun behind cloud: soft
			continue
		var n: String = named.get(li, "")
		if li.has_meta("fill"):
			# the fills over the room's middle lit every square inch; the room keeps its dark now
			li.light_energy = 0.0
			li.visible = false
			li.set_meta("base", 0.0)
			li.set_meta("tint", li.light_color)
			continue
		# pools, not washes: the light falls off fast, and a lamp's cone has a hard enough edge
		# that the floor between two tables is dark
		var c := li.light_color
		if n == "pool":
			# the felt stays green: the pool lamp's tube only warms a little
			li.light_color = c.lerp(INCANDESCENT, 0.25)
		elif c.r > c.b + 0.08 and c.g / c.r > 0.74 and n != "sodium" and n != "sign" and n != "roof_sign" and n != "juke":
			li.light_color = c.lerp(INCANDESCENT, BULB_K)
		if li is OmniLight3D and n not in OUTDOORS:
			(li as OmniLight3D).omni_attenuation = maxf((li as OmniLight3D).omni_attenuation, 1.9)
		elif li is SpotLight3D:
			(li as SpotLight3D).spot_attenuation = 1.8
			(li as SpotLight3D).spot_angle_attenuation = 3.2
		var built := li.light_energy
		li.light_energy *= ENERGY_K.get(n, SPOT_K if li is SpotLight3D else LAMP_K)
		if n == "" and li.global_position.distance_to(DOOR) < 1.6:
			li.light_energy *= 0.4
		li.light_volumetric_fog_energy = HAZE.get(n, 0.9 if li is SpotLight3D else 0.5)
		li.light_size = SIZE.get(n, 0.08 if li is SpotLight3D else 0.05)
		li.shadow_blur = 1.0
		li.shadow_normal_bias = 1.2
		# haze hangs where the lamps are, thicker under them, so their light shows as a cone and the
		# rest of the room stays clear (a veil over everything grey the blacks, and the print loses
		# its lines against them)
		var pocket: Array = POCKETS.get(n, [])
		# (the table lamps, not the bar's pendants: haze between him and the back bar burnt the
		# shelves to paper)
		if pocket.is_empty() and li is SpotLight3D and built >= 2.9:
			pocket = [Vector3(1.3, 1.2, 1.3), 0.03]
		if not pocket.is_empty():
			_haze(pub, li, pocket[0], pocket[1])
		# the table lamps throw shadows too: the people at them, on the tables
		if li is SpotLight3D and not li.shadow_enabled and n == "" and built >= 2.5:
			pub.shadowed.append([li, li.global_position])
