class_name BUtil
extends RefCounted
# Small helpers shared by the engine and the game, ported from prototype/web/src/core/util.js,
# plus the handful of JavaScript behaviours the engine leans on (loose ==, Number(), String(),
# Math.imul, parseInt) so the Godot build plays out exactly as the browser build does.

const U32 := 0xFFFFFFFF


# The shift clock counts minutes from the midnight before the shift starts, so 7:40 pm is 1180
# and 1:30 am is 1530. It never wraps.
static func clock_parts(minutes) -> Dictionary:
	var m := posmod(js_round(float(minutes)), 1440)
	var h24 := m / 60
	var mm := m % 60
	var ampm := "am" if h24 < 12 else "pm"
	var h := h24 % 12
	if h == 0:
		h = 12
	return {"h": h, "m": mm, "ampm": ampm, "text": "%d:%02d" % [h, mm]}


static func fmt_clock(minutes) -> String:
	var p := clock_parts(minutes)
	return p.text + " " + p.ampm


# "key: value" tag parsing. A bare tag ("pause") has value true.
static func parse_tag(tag) -> Dictionary:
	var t := js_trim(str(tag))
	var i := t.find(":")
	if i == -1:
		return {"key": t.to_lower(), "value": true}
	return {"key": js_trim(t.substr(0, i)).to_lower(), "value": js_trim(t.substr(i + 1))}


# "door_hoodie.read.0.c-1" -> "door_hoodie"; top-level content ("0") -> ""
static func knot_of(p) -> String:
	var k: String = (str(p) if p != null else "").split(".")[0]
	for i in range(k.length()):
		var c := k.unicode_at(i)
		if c < 48 or c > 57:
			return k
	return ""


# ---------------------------------------------------------------- JavaScript, where it matters

# Math.round: halves go up, -2.5 -> -2
static func js_round(x: float) -> int:
	return int(floor(x + 0.5))


static func js_trim(s: String) -> String:
	var a := 0
	var b := s.length()
	while a < b and _is_js_space(s.unicode_at(a)):
		a += 1
	while b > a and _is_js_space(s.unicode_at(b - 1)):
		b -= 1
	return s.substr(a, b - a)


static func js_trim_end(s: String) -> String:
	var b := s.length()
	while b > 0 and _is_js_space(s.unicode_at(b - 1)):
		b -= 1
	return s.substr(0, b)


static func _is_js_space(c: int) -> bool:
	return c == 32 or (c >= 9 and c <= 13) or c == 0xA0 or c == 0x1680 or (c >= 0x2000 and c <= 0x200A) \
		or c == 0x2028 or c == 0x2029 or c == 0x202F or c == 0x205F or c == 0x3000 or c == 0xFEFF


# split(/\s+/) on an already-trimmed string
static func split_ws(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	var in_word := false
	for i in range(s.length()):
		if _is_js_space(s.unicode_at(i)):
			if in_word:
				out.append(cur)
				cur = ""
				in_word = false
		else:
			cur += s[i]
			in_word = true
	if in_word or out.is_empty():
		out.append(cur)
	return out


# Math.imul, on unsigned 32-bit values
static func imul(a: int, b: int) -> int:
	a &= U32
	b &= U32
	var ah := a >> 16
	var al := a & 0xFFFF
	var bh := b >> 16
	var bl := b & 0xFFFF
	return (al * bl + (((ah * bl + al * bh) & 0xFFFF) << 16)) & U32


# FNV-1a over the string's UTF-16 code units, as JavaScript's charCodeAt sees them
static func hash32(s: String) -> int:
	var h := 0x811c9dc5
	for i in range(s.length()):
		var c := s.unicode_at(i)
		if c > 0xFFFF:
			c -= 0x10000
			h = imul(h ^ (0xD800 + (c >> 10)), 0x01000193)
			h = imul(h ^ (0xDC00 + (c & 0x3FF)), 0x01000193)
		else:
			h = imul(h ^ c, 0x01000193)
	return h & U32


# parseInt(s, 10), or null for NaN
static func js_parse_int(v):
	if v == null:
		return null
	var s := js_trim(str(v))
	var i := 0
	var neg := false
	if i < s.length() and (s[i] == "+" or s[i] == "-"):
		neg = s[i] == "-"
		i += 1
	var start := i
	var n := 0
	while i < s.length() and s.unicode_at(i) >= 48 and s.unicode_at(i) <= 57:
		n = n * 10 + (s.unicode_at(i) - 48)
		i += 1
	if i == start:
		return null
	return -n if neg else n


static func is_num(v) -> bool:
	return v is int or v is float


# String(v) for the values the engine sees: null, bools, numbers, strings, Ink lists and paths
static func js_str(v) -> String:
	if v == null:
		return "null"
	if v is bool:
		return "true" if v else "false"
	if v is int:
		return str(v)
	if v is float:
		return num_text(v)
	if v is String:
		return v
	if v is Object and v.has_method("text"):
		return v.text()
	return str(v)


# a number as JavaScript prints it
static func num_text(x: float) -> String:
	if is_nan(x):
		return "NaN"
	if is_inf(x):
		return "Infinity" if x > 0 else "-Infinity"
	if x == floor(x) and absf(x) < 1e21:
		return str(int(x))
	return str(x)


# Number(v)
static func js_num(v) -> float:
	if v == null:
		return 0.0
	if v is bool:
		return 1.0 if v else 0.0
	if v is int or v is float:
		return float(v)
	var s := js_trim(js_str(v))
	if s == "":
		return 0.0
	if s.is_valid_float() and not s.contains(",") and not s.to_lower().begins_with("inf") and not s.to_lower().begins_with("nan"):
		return s.to_float()
	if s == "Infinity" or s == "+Infinity":
		return INF
	if s == "-Infinity":
		return -INF
	if s.begins_with("0x") or s.begins_with("0X"):
		if s.substr(2).is_valid_hex_number():
			return float(s.substr(2).hex_to_int())
	return NAN


# v | 0
static func js_int(v) -> int:
	var x := js_num(v)
	if is_nan(x) or is_inf(x):
		return 0
	return int(x)


# !!v (an Ink list is an object, so even an empty one is true)
static func js_truthy(v) -> bool:
	if v == null:
		return false
	if v is bool:
		return v
	if v is int:
		return v != 0
	if v is float:
		return v != 0.0 and not is_nan(v)
	if v is String:
		return v.length() > 0
	return true


static func _js_type(v) -> String:
	if v is bool:
		return "boolean"
	if v is int or v is float:
		return "number"
	if v is String:
		return "string"
	return "object"


# a == b
static func js_loose_eq(a, b) -> bool:
	if a == null or b == null:
		return a == null and b == null
	var ta := _js_type(a)
	var tb := _js_type(b)
	if ta == tb:
		if ta == "number":
			return float(a) == float(b)
		if ta == "object":
			return is_same(a, b)
		return a == b
	if ta == "number" and tb == "string":
		return float(a) == js_num(b)
	if ta == "string" and tb == "number":
		return js_num(a) == float(b)
	if ta == "boolean":
		return js_loose_eq(1 if a else 0, b)
	if tb == "boolean":
		return js_loose_eq(a, 1 if b else 0)
	if ta == "object":
		return js_loose_eq(js_str(a), b)
	if tb == "object":
		return js_loose_eq(a, js_str(b))
	return false


# x !== y for the values vars() gives
static func js_strict_ne(x, y) -> bool:
	if is_num(x) and is_num(y):
		return float(x) != float(y)
	if typeof(x) != typeof(y):
		return true
	if x is Object:
		return not is_same(x, y)
	return x != y


# a stable sort (JavaScript's Array.prototype.sort is stable; Godot's sort_custom isn't)
static func stable_sort(arr: Array, less: Callable) -> void:
	for i in range(1, arr.size()):
		var v = arr[i]
		var j := i - 1
		while j >= 0 and less.call(v, arr[j]):
			arr[j + 1] = arr[j]
			j -= 1
		arr[j + 1] = v
