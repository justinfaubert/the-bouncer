# The look of the page: the paper, the three inks, the type, and how each voice speaks.
#
# The world is printed in three inks on cream stock (look/press.gdshader). The column beside it is a
# solid of the night ink with the words knocked out of it, so the words are the paper showing
# through, and the voices print in their own colours and faces, as they do in the browser build
# (prototype/web/style.css, .v-<style>).
class_name Look
extends RefCounted

# the stock and the three inks (the same as sketches/door-look/tools/press.py)
const STOCK := Color("eae2cf")
const NIGHT := Color("1b2130")
const LAMP := Color("f0a23c")
const NEON := Color("d9382c")

# the column's type: knocked out of the night ink, or printed in the voices' colours
const INK := Color("eae2cf")
const INK_2 := Color("cec4b4")
const MUTED := Color("8f8a82")
const FAINT := Color("5f5d5a")
const RED := Color("ec5a47")
const GOOD := Color("8cc79b")
const BAD := Color("ff7b68")
const RULE := Color("3a3d47")

# the receipt paper of the till tape and the incident log's form
const RECEIPT := Color("dcd7cb")
const RECEIPT_INK := Color("1b1a17")
const RECEIPT_RED := Color("a8231b")

# The voices: their colour, their face, how big against the reading size, and anything else
# about how they talk (prototype/web/style.css).
const VOICES := {
	"father": {"color": Color("dcab5e"), "font": "zilla", "size": 1.0},
	"fighter": {"color": Color("e68aac"), "font": "anton", "size": 0.96},
	"manual": {"color": Color("94b7df"), "font": "mono", "size": 0.86},
	"wrongman": {"color": Color("a5c2a6"), "font": "cormorant", "size": 1.14},
	"table": {"color": Color("dac45f"), "font": "archivo", "size": 0.9},
	"kid": {"color": Color("80d1db"), "font": "work", "size": 1.0, "lower": true},
}

const FONT_FILES := {
	"read": "newsreader-400.woff2",
	"read_i": "newsreader-400-italic.woff2",
	"ui": "barlow-condensed-500.woff2",
	"ui_r": "barlow-condensed-400.woff2",
	"ui_b": "barlow-condensed-600.woff2",
	"display": "big-shoulders-display-300.woff2",
	"zilla": "zilla-slab-400.woff2",
	"zilla_b": "zilla-slab-600.woff2",
	"anton": "anton-400.woff2",
	"mono": "ibm-plex-mono-400.woff2",
	"cormorant": "cormorant-garamond-400-italic.woff2",
	"archivo": "archivo-black-400.woff2",
	"work": "work-sans-300.woff2",
	"receipt": "courier-prime-400.woff2",
	"receipt_b": "courier-prime-700.woff2",
	"hand": "kalam-400.woff2",
	"hand_l": "kalam-300.woff2",
}

const PLACE := {
	"door": "On the door", "floor": "On the floor", "t28": "At table 28", "pool": "By the pool table",
	"bar": "At the bar", "hall": "In the back hall", "kitchen": "In the kitchen", "keg": "In the keg room",
	"deck": "Out on the deck", "lot": "Out in the lot", "upstairs": "Upstairs",
}
# what a place is called in a caption, and on the ways out
const CAPTION := {
	"door": "The door", "floor": "The floor", "t28": "Table 28", "pool": "The pool table", "bar": "The bar",
	"hall": "The back hall", "kitchen": "The kitchen", "keg": "The keg room", "deck": "The deck",
	"lot": "The lot", "upstairs": "Upstairs",
}
const DAY_NAMES := {1: "Wednesday", 2: "Thursday", 3: "Friday"}
const HURT_WORDS := ["", "Knocked about", "Hurt", "Badly hurt"]
const TENSION_WORDS := ["Settled", "Uneasy", "Arguing", "Shouting", "At war"]

# the shift clock
const CLOSE_TIME := 1560
const BUSY_FROM := 1350
const LAST_CALL := 1530
const MIDNIGHT := 1440

static var fonts := {}


static func load_fonts() -> void:
	if not fonts.is_empty():
		return
	for k in FONT_FILES:
		var f := FontFile.new()
		var err := f.load_dynamic_font("res://fonts/" + FONT_FILES[k])
		if err != OK:
			push_warning("font " + FONT_FILES[k] + ": " + str(err))
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		fonts[k] = f


static func font(k: String) -> Font:
	load_fonts()
	return fonts.get(k, fonts["read"])


static func voice(style: String) -> Dictionary:
	return VOICES.get(style, VOICES["father"])


static func voice_color(style: String) -> Color:
	return voice(style).color


# the light of the night by the shift clock
static func phase_of(clock: int) -> String:
	if clock >= CLOSE_TIME + 30:
		return "after"
	if clock >= LAST_CALL:
		return "lights"
	if clock >= MIDNIGHT:
		return "late"
	if clock >= BUSY_FROM:
		return "busy"
	return "early"


static func clock_text(clock: int) -> String:
	return BUtil.fmt_clock(clock)


static func tally(n: int) -> String:
	if n <= 0:
		return "none"
	var out := ""
	for i in n / 5:
		out += "||||  "
	out += "|".repeat(n % 5)
	return out.strip_edges()


# BBCode-safe text
static func esc(s) -> String:
	return str(s).replace("[", "[lb]")
