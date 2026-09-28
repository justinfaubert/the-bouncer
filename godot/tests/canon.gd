class_name Canon
extends RefCounted
# A canonical JSON form (keys sorted, nulls left out, numbers as JavaScript prints whole ones and
# six places for the rest), written the same way by tools/engine_diff.mjs, so a night played in
# Godot and in the browser build's engine can be compared line for line.

static func quote(s: String) -> String:
	var out := "\""
	for i in range(s.length()):
		var c := s.unicode_at(i)
		match c:
			34: out += "\\\""
			92: out += "\\\\"
			10: out += "\\n"
			13: out += "\\r"
			9: out += "\\t"
			_:
				if c < 32:
					out += "\\u%04x" % c
				else:
					out += s[i]
	return out + "\""


static func of(v) -> String:
	if v == null:
		return "null"
	if v is bool:
		return "true" if v else "false"
	if v is int:
		return str(v)
	if v is float:
		if is_nan(v):
			return "NaN"
		if v == floor(v) and absf(v) < 1e15:
			return str(int(v))
		return "%.6f" % v
	if v is String or v is StringName:
		return quote(str(v))
	if v is Array or v is PackedStringArray:
		var parts := PackedStringArray()
		for x in v:
			parts.append(of(x))
		return "[" + ",".join(parts) + "]"
	if v is Dictionary:
		var keys: Array = []
		for k in v:
			if v[k] != null:
				keys.append(str(k))
		keys.sort()
		var parts := PackedStringArray()
		for k in keys:
			parts.append(quote(k) + ":" + of(v[k]))
		return "{" + ",".join(parts) + "}"
	return "\"<object>\""
