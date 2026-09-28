# The Ink runtime, in GDScript: a port of inkjs 2.3.2, the engine the browser build runs, close
# to line for line so the two play a story the same way. It reads the story the Ink compiler
# writes (data/build/story.json, ink format 21) and plays it: text, tags, choices, variables,
# lists, visit and turn counts, sequences and shuffles, threads, tunnels, functions, externals
# with Ink fallbacks, and saving and loading the story's state.
#
# tools/ink_diff.mjs checks it against inkjs: the same story, seeds and choices on both, and the
# same text, tags and choices out, over thousands of nights.
#
# Where inkjs leans on JavaScript it's copied, not tidied, because the point is the same night on
# both: numbers follow JavaScript's rules (a whole number is an int however it was worked out,
# integer division floors), and lists keep a JavaScript Map's order.
#
# GDScript has no exceptions. Where inkjs throws a StoryException, this records it (_throw), the
# step in hand finishes as best it can, and the Continue loop turns it into an error on the
# state, as inkjs's catch does. A story that's working never gets there.
class_name Ink
extends RefCounted

# ---------------------------------------------------------------- constants

# What each runtime object is, so the hot paths can switch on an int
const K_OBJ := 0
const K_CONT := 1
const K_VAL := 2
const K_CMD := 3
const K_DIVERT := 4
const K_CHOICE_POINT := 5
const K_CHOICE := 6
const K_VAR_REF := 7
const K_VAR_ASSIGN := 8
const K_TAG := 9
const K_GLUE := 10
const K_VOID := 11
const K_NATIVE := 12

# ValueType, numbered as inkjs numbers them (coercion picks the highest)
const VT_BOOL := -1
const VT_INT := 0
const VT_FLOAT := 1
const VT_LIST := 2
const VT_STRING := 3
const VT_DIVERT := 4
const VT_VAR_PTR := 5
const VT_NAMES := {-1: "Bool", 0: "Int", 1: "Float", 2: "List", 3: "String", 4: "DivertTarget", 5: "VariablePointer"}

# ControlCommand.CommandType
const C_EVAL_START := 0
const C_EVAL_OUTPUT := 1
const C_EVAL_END := 2
const C_DUPLICATE := 3
const C_POP_EVALUATED := 4
const C_POP_FUNCTION := 5
const C_POP_TUNNEL := 6
const C_BEGIN_STRING := 7
const C_END_STRING := 8
const C_NOOP := 9
const C_CHOICE_COUNT := 10
const C_TURNS := 11
const C_TURNS_SINCE := 12
const C_READ_COUNT := 13
const C_RANDOM := 14
const C_SEED_RANDOM := 15
const C_VISIT_INDEX := 16
const C_SEQ_SHUFFLE_INDEX := 17
const C_START_THREAD := 18
const C_DONE := 19
const C_END := 20
const C_LIST_FROM_INT := 21
const C_LIST_RANGE := 22
const C_LIST_RANDOM := 23
const C_BEGIN_TAG := 24
const C_END_TAG := 25
const CMD_NAMES := ["ev", "out", "/ev", "du", "pop", "~ret", "->->", "str", "/str", "nop", "choiceCnt", "turn", "turns", "readc", "rnd", "srnd", "visit", "seq", "thread", "done", "end", "listInt", "range", "lrnd", "#", "/#"]

# PushPopType
const PP_TUNNEL := 0
const PP_FUNCTION := 1
const PP_FUNCTION_EVAL_FROM_GAME := 2

# ErrorType, for on_error
const ERROR_AUTHOR := 0
const ERROR_WARNING := 1
const ERROR_ERROR := 2

const INK_VERSION_CURRENT := 21
const INK_VERSION_MIN := 18
const SAVE_VERSION := 10
const SAVE_VERSION_MIN := 8
const DEFAULT_FLOW := "DEFAULT_FLOW"
const MAX_SAFE_INTEGER := 9007199254740991

# ---------------------------------------------------------------- JavaScript's numbers

static func is_whole(f: float) -> bool:
	return not is_nan(f) and not is_inf(f) and f == floorf(f)


# Number.prototype.toString, for the values ink prints
static func num_str(x) -> String:
	if x is int:
		return str(x)
	var f: float = float(x)
	if is_nan(f):
		return "NaN"
	if is_inf(f):
		return "Infinity" if f > 0.0 else "-Infinity"
	if f == floorf(f) and absf(f) < 1e21:
		return str(int(f))
	return str(f)


# Value.Create: a GDScript value as an ink value, by JavaScript's rules
static func create_value(v, preferred: int = -99) -> Val:
	if preferred == VT_FLOAT:
		if v is bool:
			return FloatVal.new(1.0 if v else 0.0)
		if (v is int or v is float) and not is_nan(float(v)):
			return FloatVal.new(float(v))
	if v is bool:
		return BoolVal.new(v)
	if v is String or v is StringName:
		return StrVal.new(String(v))
	if v is int:
		return IntVal.new(v)
	if v is float:
		if is_whole(v) and absf(v) < 9.2e18:
			return IntVal.new(int(v))
		if not is_nan(v):
			return FloatVal.new(v)
		return null
	if v is InkPath:
		return DivertTargetVal.new(v)
	if v is InkList:
		return ListVal.from_list(v)
	if v == null:
		return IntVal.new(0)
	return null


# JSON numbers: Godot reads them all as floats; JavaScript keeps whole ones whole
static func jnum(v) -> Variant:
	if v is float and is_whole(v) and absf(v) < 9.2e18:
		return int(v)
	return v


static func jint(v) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is String:
		return v.to_int()
	if v is bool:
		return 1 if v else 0
	return 0


# ---------------------------------------------------------------- paths

class PathComp extends RefCounted:
	var index: int = -1
	var name = null

	static func of_index(i: int) -> PathComp:
		var c := PathComp.new()
		c.index = i
		return c

	static func of_name(n: String) -> PathComp:
		var c := PathComp.new()
		c.name = n
		return c

	static func to_parent() -> PathComp:
		return PathComp.of_name("^")

	func is_index() -> bool:
		return index >= 0

	func is_parent() -> bool:
		return name == "^"

	func text() -> String:
		return str(index) if index >= 0 else str(name)

	func equals(o: PathComp) -> bool:
		if o != null and o.is_index() == is_index():
			if is_index():
				return index == o.index
			return name == o.name
		return false


class InkPath extends RefCounted:
	var components: Array = []
	var is_relative := false
	var _cs = null

	static func from_string(s) -> InkPath:
		var p := InkPath.new()
		p._set_components_string(s)
		return p

	static func from_components(comps: Array, relative := false) -> InkPath:
		var p := InkPath.new()
		p.components = comps.duplicate()
		p.is_relative = relative
		return p

	static func self_path() -> InkPath:
		var p := InkPath.new()
		p.is_relative = true
		return p

	func length() -> int:
		return components.size()

	func head() -> PathComp:
		return components[0] if components.size() > 0 else null

	func tail() -> InkPath:
		if components.size() >= 2:
			return InkPath.from_components(components.slice(1))
		return InkPath.self_path()

	func last_component() -> PathComp:
		return components[components.size() - 1] if components.size() > 0 else null

	func get_component(i: int) -> PathComp:
		return components[i]

	func contains_named_component() -> bool:
		for c in components:
			if not c.is_index():
				return true
		return false

	func path_by_appending_path(other: InkPath) -> InkPath:
		var p := InkPath.new()
		var upward := 0
		for c in other.components:
			if c.is_parent():
				upward += 1
			else:
				break
		for i in range(components.size() - upward):
			p.components.append(components[i])
		for i in range(upward, other.components.size()):
			p.components.append(other.components[i])
		return p

	func path_by_appending_component(c: PathComp) -> InkPath:
		var p := InkPath.new()
		p.components = components.duplicate()
		p.components.append(c)
		return p

	func components_string() -> String:
		if _cs == null:
			var parts := PackedStringArray()
			for c in components:
				parts.append(c.text())
			_cs = ".".join(parts)
			if is_relative:
				_cs = "." + _cs
		return _cs

	func _set_components_string(value) -> void:
		components.clear()
		_cs = value
		if value == null or value == "":
			return
		var s: String = value
		if s[0] == ".":
			is_relative = true
			s = s.substr(1)
			_cs = s
		for part in s.split("."):
			if part.is_valid_int():
				components.append(PathComp.of_index(part.to_int()))
			else:
				components.append(PathComp.of_name(part))

	func text() -> String:
		return components_string()

	func _to_string() -> String:
		return components_string()

	func equals(o: InkPath) -> bool:
		if o == null:
			return false
		if o.components.size() != components.size():
			return false
		if o.is_relative != is_relative:
			return false
		for i in range(components.size()):
			if not o.components[i].equals(components[i]):
				return false
		return true


# A place in the story. Never changed once made, so pointers are shared rather than copied (in
# inkjs a Pointer is a struct, copied on every assignment; here that would be an allocation each time).
class Pointer extends RefCounted:
	var container: Cont = null
	var index: int = -1
	static var NULL := Pointer.new(null, -1)

	func _init(c: Cont = null, i: int = -1) -> void:
		container = c
		index = i

	static func start_of(c: Cont) -> Pointer:
		return Pointer.new(c, 0)

	static func null_ptr() -> Pointer:
		return NULL

	func resolve() -> Obj:
		if index < 0:
			return container
		if container == null:
			return null
		if container.content.size() == 0:
			return container
		if index >= container.content.size():
			return null
		return container.content[index]

	func is_null() -> bool:
		return container == null

	func path() -> InkPath:
		if container == null:
			return null
		if index >= 0:
			return container.path().path_by_appending_component(PathComp.of_index(index))
		return container.path()

	func copy() -> Pointer:
		return self

	func _to_string() -> String:
		if container == null:
			return "Ink Pointer (null)"
		return "Ink Pointer -> " + container.path().text() + " -- index " + str(index)


class SearchResult extends RefCounted:
	var obj: Obj = null
	var approximate := false

	func correct_obj() -> Obj:
		return null if approximate else obj

	func container() -> Cont:
		return obj if (obj != null and obj.kind == K_CONT) else null


# ---------------------------------------------------------------- runtime objects

class Obj extends RefCounted:
	var kind: int = K_OBJ
	var parent: Cont = null
	var _path: InkPath = null
	var _idx_in_parent := -2

	# where it sits in its parent's content (-1: only named there); content never changes once parsed
	func index_in_parent() -> int:
		if _idx_in_parent == -2:
			_idx_in_parent = parent.content.find(self) if parent != null else -1
		return _idx_in_parent

	func path() -> InkPath:
		if _path == null:
			if parent == null:
				_path = InkPath.new()
			else:
				var comps: Array = []
				var child: Obj = self
				var container: Cont = child.parent
				while container != null:
					if child.kind == K_CONT and child.has_valid_name():
						comps.push_front(PathComp.of_name(child.name))
					else:
						comps.push_front(PathComp.of_index(container.content.find(child)))
					child = container
					container = container.parent
				_path = InkPath.from_components(comps)
		return _path

	func resolve_path(p: InkPath) -> SearchResult:
		if p.is_relative:
			var nearest: Cont = self if kind == K_CONT else null
			if nearest == null:
				nearest = parent
				p = p.tail()
			return nearest.content_at_path(p)
		return root_container().content_at_path(p)

	func convert_path_to_relative(global_path: InkPath) -> InkPath:
		var own := path()
		var min_len := mini(global_path.length(), own.length())
		var last_shared := -1
		for i in range(min_len):
			if own.get_component(i).equals(global_path.get_component(i)):
				last_shared = i
			else:
				break
		if last_shared == -1:
			return global_path
		var up := own.components.size() - 1 - last_shared
		var comps: Array = []
		for i in range(up):
			comps.append(PathComp.to_parent())
		for i in range(last_shared + 1, global_path.components.size()):
			comps.append(global_path.get_component(i))
		return InkPath.from_components(comps, true)

	func compact_path_string(other: InkPath) -> String:
		var global_str: String
		var relative_str: String
		if other.is_relative:
			relative_str = other.components_string()
			global_str = path().path_by_appending_path(other).components_string()
		else:
			relative_str = convert_path_to_relative(other).components_string()
			global_str = other.components_string()
		return relative_str if relative_str.length() < global_str.length() else global_str

	func root_container() -> Cont:
		var a: Obj = self
		while a.parent != null:
			a = a.parent
		return a if a.kind == K_CONT else null

	func has_valid_name() -> bool:
		return false

	func text() -> String:
		return "InkObject"


class Cont extends Obj:
	var name = null
	var content: Array = []
	var named_content: Dictionary = {}
	var visits_should_be_counted := false
	var turn_index_should_be_counted := false
	var counting_at_start_only := false

	func _init() -> void:
		kind = K_CONT

	func has_valid_name() -> bool:
		return name != null and String(name).length() > 0

	func set_count_flags(flag: int) -> void:
		if flag & 1:
			visits_should_be_counted = true
		if flag & 2:
			turn_index_should_be_counted = true
		if flag & 4:
			counting_at_start_only = true

	func count_flags() -> int:
		var f := 0
		if visits_should_be_counted:
			f |= 1
		if turn_index_should_be_counted:
			f |= 2
		if counting_at_start_only:
			f |= 4
		if f == 4:
			f = 0
		return f

	func add_content(obj: Obj) -> void:
		content.append(obj)
		obj.parent = self
		if obj.kind == K_CONT and obj.has_valid_name():
			obj.parent = self
			named_content[obj.name] = obj

	func add_to_named_content_only(obj: Obj) -> void:
		obj.parent = self
		named_content[obj.name] = obj

	# the named content that isn't also in the content
	func named_only_content() -> Dictionary:
		var out := {}
		for k in named_content:
			out[k] = named_content[k]
		for c in content:
			if c.kind == K_CONT and c.has_valid_name():
				out.erase(c.name)
		return out

	func content_at_path(p: InkPath, partial_start := 0, partial_len := -1) -> SearchResult:
		if partial_len == -1:
			partial_len = p.length()
		var result := SearchResult.new()
		var current_container: Cont = self
		var current_obj: Obj = self
		for i in range(partial_start, partial_len):
			var comp: PathComp = p.components[i]
			if current_container == null:
				result.approximate = true
				break
			var found: Obj = current_container.content_with_path_component(comp)
			if found == null:
				result.approximate = true
				break
			var next_container: Cont = found if found.kind == K_CONT else null
			if i < partial_len - 1 and next_container == null:
				result.approximate = true
				break
			current_obj = found
			current_container = next_container
		result.obj = current_obj
		return result

	func content_with_path_component(comp: PathComp) -> Obj:
		if comp.index >= 0:
			if comp.index < content.size():
				return content[comp.index]
			return null
		if comp.name == "^":
			return parent
		return named_content.get(comp.name)

	func text() -> String:
		return "Container"


class Val extends Obj:
	var vtype: int = VT_INT
	var value

	func _init() -> void:
		kind = K_VAL

	func value_object():
		return value

	func is_truthy() -> bool:
		return false

	func cast(_new_type: int) -> Val:
		return self

	func bad_cast(new_type: int) -> Val:
		Ink._throw_global("Can't cast " + text() + " from " + str(vtype) + " to " + str(new_type))
		return self

	func text() -> String:
		return str(value)


class IntVal extends Val:
	func _init(v = 0) -> void:
		kind = K_VAL
		vtype = VT_INT
		value = v if v != null else 0

	func is_truthy() -> bool:
		return value != 0

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		if t == VT_BOOL:
			return BoolVal.new(value != 0)
		if t == VT_FLOAT:
			return FloatVal.new(float(value))
		if t == VT_STRING:
			return StrVal.new(Ink.num_str(value))
		return bad_cast(t)

	func text() -> String:
		return Ink.num_str(value)


class FloatVal extends Val:
	func _init(v = 0.0) -> void:
		kind = K_VAL
		vtype = VT_FLOAT
		value = float(v) if v != null else 0.0

	func is_truthy() -> bool:
		return value != 0.0

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		if t == VT_BOOL:
			return BoolVal.new(value != 0.0)
		if t == VT_INT:
			var iv := IntVal.new()
			iv.value = value      # inkjs keeps the float as it is
			return iv
		if t == VT_STRING:
			return StrVal.new(Ink.num_str(value))
		return bad_cast(t)

	func text() -> String:
		return Ink.num_str(value)


class BoolVal extends Val:
	func _init(v = false) -> void:
		kind = K_VAL
		vtype = VT_BOOL
		value = bool(v) if v != null else false

	func is_truthy() -> bool:
		return value

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		if t == VT_INT:
			return IntVal.new(1 if value else 0)
		if t == VT_FLOAT:
			return FloatVal.new(1.0 if value else 0.0)
		if t == VT_STRING:
			return StrVal.new("true" if value else "false")
		return bad_cast(t)

	func text() -> String:
		return "true" if value else "false"


class StrVal extends Val:
	var is_newline := false
	var is_inline_whitespace := true

	func _init(v = "") -> void:
		kind = K_VAL
		vtype = VT_STRING
		value = String(v) if v != null else ""
		is_newline = value == "\n"
		is_inline_whitespace = true
		for i in range(value.length()):
			var c: String = value[i]
			if c != " " and c != "\t":
				is_inline_whitespace = false
				break

	func is_non_whitespace() -> bool:
		return not is_newline and not is_inline_whitespace

	func is_truthy() -> bool:
		return value.length() > 0

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		if t == VT_INT:
			var s: String = value.strip_edges()
			var m = Ink._leading_int(s)
			if m != null:
				return IntVal.new(m)
			return bad_cast(t)
		if t == VT_FLOAT:
			if value.strip_edges().is_valid_float():
				return FloatVal.new(value.strip_edges().to_float())
			return bad_cast(t)
		return bad_cast(t)

	func text() -> String:
		return value


class DivertTargetVal extends Val:
	func _init(p: InkPath = null) -> void:
		kind = K_VAL
		vtype = VT_DIVERT
		value = p

	func target_path() -> InkPath:
		return value

	func is_truthy() -> bool:
		Ink._throw_global("Shouldn't be checking the truthiness of a divert target")
		return false

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		return bad_cast(t)

	func text() -> String:
		return "DivertTargetValue(" + (value.text() if value != null else "null") + ")"


class VarPtrVal extends Val:
	var context_index := -1

	func _init(var_name = null, ci := -1) -> void:
		kind = K_VAL
		vtype = VT_VAR_PTR
		value = var_name
		context_index = ci

	func variable_name() -> String:
		return value

	func is_truthy() -> bool:
		Ink._throw_global("Shouldn't be checking the truthiness of a variable pointer")
		return false

	func cast(t: int) -> Val:
		if t == vtype:
			return self
		return bad_cast(t)

	func text() -> String:
		return "VariablePointerValue(" + str(value) + ")"


class ListVal extends Val:
	func _init() -> void:
		kind = K_VAL
		vtype = VT_LIST
		value = InkList.new()

	static func from_list(l: InkList) -> ListVal:
		var v := ListVal.new()
		v.value = InkList.copy_of(l)
		return v

	static func single(item: InkListItem, n: int) -> ListVal:
		var v := ListVal.new()
		v.value = InkList.single(item, n)
		return v

	func is_truthy() -> bool:
		return value.count() > 0

	func cast(t: int) -> Val:
		if t == VT_INT:
			var mx: Array = value.max_item()
			return IntVal.new(0) if mx[0].is_null() else IntVal.new(mx[1])
		if t == VT_FLOAT:
			var mx2: Array = value.max_item()
			return FloatVal.new(0.0) if mx2[0].is_null() else FloatVal.new(float(mx2[1]))
		if t == VT_STRING:
			var mx3: Array = value.max_item()
			return StrVal.new("") if mx3[0].is_null() else StrVal.new(mx3[0].full_name())
		if t == vtype:
			return self
		return bad_cast(t)

	func text() -> String:
		return value.text()

	static func retain_list_origins_for_assignment(old_value, new_value) -> void:
		if old_value is ListVal and new_value is ListVal:
			if new_value.value.count() == 0:
				new_value.value.set_initial_origin_names(old_value.value.origin_names())


class Cmd extends Obj:
	var type: int = -1

	func _init(t: int = -1) -> void:
		kind = K_CMD
		type = t

	func text() -> String:
		return "ControlCommand " + str(type)


class Divert extends Obj:
	var _target_path: InkPath = null
	var _target_pointer: Pointer = Pointer.null_ptr()
	var variable_divert_name = null
	var pushes_to_stack := false
	var stack_push_type := 0
	var is_external := false
	var external_args := 0
	var is_conditional := false

	func _init() -> void:
		kind = K_DIVERT

	func target_path() -> InkPath:
		if _target_path != null and _target_path.is_relative:
			var target_obj := target_pointer().resolve()
			if target_obj != null:
				_target_path = target_obj.path()
		return _target_path

	func set_target_path(p: InkPath) -> void:
		_target_path = p
		_target_pointer = Pointer.null_ptr()

	func target_pointer() -> Pointer:
		if _target_pointer.is_null():
			var target_obj: Obj = resolve_path(_target_path).obj
			if _target_path.last_component().is_index():
				_target_pointer = Pointer.new(target_obj.parent if target_obj != null else null, _target_path.last_component().index)
			else:
				_target_pointer = Pointer.start_of(target_obj if (target_obj != null and target_obj.kind == K_CONT) else null)
		return _target_pointer.copy()

	func target_path_string():
		var p := target_path()
		if p == null:
			return null
		return compact_path_string(p)

	func has_variable_target() -> bool:
		return variable_divert_name != null

	func text() -> String:
		if has_variable_target():
			return "Divert(variable: " + str(variable_divert_name) + ")"
		if target_path() == null:
			return "Divert(null)"
		return "Divert -> " + str(target_path_string())


class ChoicePoint extends Obj:
	var _path_on_choice: InkPath = null
	var has_condition := false
	var has_start_content := false
	var has_choice_only_content := false
	var is_invisible_default := false
	var once_only := true

	func _init() -> void:
		kind = K_CHOICE_POINT

	func path_on_choice() -> InkPath:
		if _path_on_choice != null and _path_on_choice.is_relative:
			var target := choice_target()
			if target != null:
				_path_on_choice = target.path()
		return _path_on_choice

	func choice_target() -> Cont:
		return resolve_path(_path_on_choice).container()

	func path_string_on_choice() -> String:
		return compact_path_string(path_on_choice())

	func set_flags(v: int) -> void:
		has_condition = (v & 1) > 0
		has_start_content = (v & 2) > 0
		has_choice_only_content = (v & 4) > 0
		is_invisible_default = (v & 8) > 0
		once_only = (v & 16) > 0

	func flags() -> int:
		var f := 0
		if has_condition:
			f |= 1
		if has_start_content:
			f |= 2
		if has_choice_only_content:
			f |= 4
		if is_invisible_default:
			f |= 8
		if once_only:
			f |= 16
		return f

	func text() -> String:
		return "Choice: -> " + path_on_choice().text()


class Choice extends Obj:
	var text_value := ""
	var index := 0
	var thread_at_generation: CSThread = null
	var source_path := ""
	var target_path: InkPath = null
	var is_invisible_default := false
	var tags = null
	var original_thread_index := 0

	func _init() -> void:
		kind = K_CHOICE

	func path_string_on_choice() -> String:
		return target_path.text()

	func clone() -> Choice:
		var c := Choice.new()
		c.text_value = text_value
		c.source_path = source_path
		c.index = index
		c.target_path = target_path
		c.original_thread_index = original_thread_index
		c.is_invisible_default = is_invisible_default
		if thread_at_generation != null:
			c.thread_at_generation = thread_at_generation.copy()
		return c

	func text() -> String:
		return text_value


class VarRef extends Obj:
	var name = null
	var path_for_count: InkPath = null

	func _init(n = null) -> void:
		kind = K_VAR_REF
		name = n

	func container_for_count() -> Cont:
		if path_for_count == null:
			return null
		return resolve_path(path_for_count).container()

	func path_string_for_count():
		if path_for_count == null:
			return null
		return compact_path_string(path_for_count)

	func text() -> String:
		if name != null:
			return "var(" + str(name) + ")"
		return "read_count(" + str(path_string_for_count()) + ")"


class VarAssign extends Obj:
	var variable_name = null
	var is_new_declaration := false
	var is_global := false

	func _init(n = null, is_new := false) -> void:
		kind = K_VAR_ASSIGN
		variable_name = n
		is_new_declaration = is_new

	func text() -> String:
		return "VarAssign to " + str(variable_name)


class Tag extends Obj:
	var text_value := ""

	func _init(t = "") -> void:
		kind = K_TAG
		text_value = str(t)

	func text() -> String:
		return "# " + text_value


class Glue extends Obj:
	func _init() -> void:
		kind = K_GLUE

	func text() -> String:
		return "Glue"


class Void extends Obj:
	func _init() -> void:
		kind = K_VOID

	func text() -> String:
		return "Void"


# ---------------------------------------------------------------- native functions

class NativeCall extends Obj:
	var name := ""
	var number_of_parameters := 0
	var ops := {}          # value type -> Callable

	func _init(n := "", params := 0) -> void:
		kind = K_NATIVE
		name = n
		number_of_parameters = params

	func text() -> String:
		return "Native \"" + name + "\""


static var _natives: Dictionary = {}


static func _add_op(nm: String, params: int, vt: int, op: Callable) -> void:
	var f: NativeCall = _natives.get(nm)
	if f == null:
		f = NativeCall.new(nm, params)
		_natives[nm] = f
	f.ops[vt] = op


static func natives() -> Dictionary:
	if _natives.is_empty():
		_build_natives()
	return _natives


static func _build_natives() -> void:
	# ints (JavaScript numbers: integer division floors; the rest is ordinary arithmetic)
	_add_op("+", 2, VT_INT, func(x, y): return x + y)
	_add_op("-", 2, VT_INT, func(x, y): return x - y)
	_add_op("*", 2, VT_INT, func(x, y): return x * y)
	_add_op("/", 2, VT_INT, func(x, y): return Ink._js_div_floor(x, y))
	_add_op("%", 2, VT_INT, func(x, y): return Ink._js_mod(x, y))
	_add_op("_", 1, VT_INT, func(x): return -x)
	_add_op("==", 2, VT_INT, func(x, y): return x == y)
	_add_op(">", 2, VT_INT, func(x, y): return x > y)
	_add_op("<", 2, VT_INT, func(x, y): return x < y)
	_add_op(">=", 2, VT_INT, func(x, y): return x >= y)
	_add_op("<=", 2, VT_INT, func(x, y): return x <= y)
	_add_op("!=", 2, VT_INT, func(x, y): return x != y)
	_add_op("!", 1, VT_INT, func(x): return x == 0)
	_add_op("&&", 2, VT_INT, func(x, y): return x != 0 and y != 0)
	_add_op("||", 2, VT_INT, func(x, y): return x != 0 or y != 0)
	_add_op("MAX", 2, VT_INT, func(x, y): return x if x >= y else y)
	_add_op("MIN", 2, VT_INT, func(x, y): return x if x <= y else y)
	_add_op("POW", 2, VT_INT, func(x, y): return pow(float(x), float(y)))
	_add_op("FLOOR", 1, VT_INT, func(x): return x)
	_add_op("CEILING", 1, VT_INT, func(x): return x)
	_add_op("INT", 1, VT_INT, func(x): return x)
	_add_op("FLOAT", 1, VT_INT, func(x): return x)
	# floats
	_add_op("+", 2, VT_FLOAT, func(x, y): return float(x) + float(y))
	_add_op("-", 2, VT_FLOAT, func(x, y): return float(x) - float(y))
	_add_op("*", 2, VT_FLOAT, func(x, y): return float(x) * float(y))
	_add_op("/", 2, VT_FLOAT, func(x, y): return Ink._js_fdiv(x, y))
	_add_op("%", 2, VT_FLOAT, func(x, y): return fmod(float(x), float(y)))
	_add_op("_", 1, VT_FLOAT, func(x): return -float(x))
	_add_op("==", 2, VT_FLOAT, func(x, y): return float(x) == float(y))
	_add_op(">", 2, VT_FLOAT, func(x, y): return float(x) > float(y))
	_add_op("<", 2, VT_FLOAT, func(x, y): return float(x) < float(y))
	_add_op(">=", 2, VT_FLOAT, func(x, y): return float(x) >= float(y))
	_add_op("<=", 2, VT_FLOAT, func(x, y): return float(x) <= float(y))
	_add_op("!=", 2, VT_FLOAT, func(x, y): return float(x) != float(y))
	_add_op("!", 1, VT_FLOAT, func(x): return float(x) == 0.0)
	_add_op("&&", 2, VT_FLOAT, func(x, y): return float(x) != 0.0 and float(y) != 0.0)
	_add_op("||", 2, VT_FLOAT, func(x, y): return float(x) != 0.0 or float(y) != 0.0)
	_add_op("MAX", 2, VT_FLOAT, func(x, y): return maxf(float(x), float(y)))
	_add_op("MIN", 2, VT_FLOAT, func(x, y): return minf(float(x), float(y)))
	_add_op("POW", 2, VT_FLOAT, func(x, y): return pow(float(x), float(y)))
	_add_op("FLOOR", 1, VT_FLOAT, func(x): return floorf(float(x)))
	_add_op("CEILING", 1, VT_FLOAT, func(x): return ceilf(float(x)))
	_add_op("INT", 1, VT_FLOAT, func(x): return floorf(float(x)))
	_add_op("FLOAT", 1, VT_FLOAT, func(x): return x)
	# strings
	_add_op("+", 2, VT_STRING, func(x, y): return str(x) + str(y))
	_add_op("==", 2, VT_STRING, func(x, y): return str(x) == str(y))
	_add_op("!=", 2, VT_STRING, func(x, y): return not (str(x) == str(y)))
	_add_op("?", 2, VT_STRING, func(x, y): return str(x).contains(str(y)))
	_add_op("!?", 2, VT_STRING, func(x, y): return not str(x).contains(str(y)))
	# lists
	_add_op("+", 2, VT_LIST, func(x, y): return x.union(y))
	_add_op("-", 2, VT_LIST, func(x, y): return x.without(y))
	_add_op("?", 2, VT_LIST, func(x, y): return x.contains(y))
	_add_op("!?", 2, VT_LIST, func(x, y): return not x.contains(y))
	_add_op("^", 2, VT_LIST, func(x, y): return x.intersect(y))
	_add_op("==", 2, VT_LIST, func(x, y): return x.equals(y))
	_add_op(">", 2, VT_LIST, func(x, y): return x.greater_than(y))
	_add_op("<", 2, VT_LIST, func(x, y): return x.less_than(y))
	_add_op(">=", 2, VT_LIST, func(x, y): return x.greater_than_or_equals(y))
	_add_op("<=", 2, VT_LIST, func(x, y): return x.less_than_or_equals(y))
	_add_op("!=", 2, VT_LIST, func(x, y): return not x.equals(y))
	_add_op("&&", 2, VT_LIST, func(x, y): return x.count() > 0 and y.count() > 0)
	_add_op("||", 2, VT_LIST, func(x, y): return x.count() > 0 or y.count() > 0)
	_add_op("!", 1, VT_LIST, func(x): return 1 if x.count() == 0 else 0)
	_add_op("LIST_INVERT", 1, VT_LIST, func(x): return x.inverse())
	_add_op("LIST_ALL", 1, VT_LIST, func(x): return x.all())
	_add_op("LIST_MIN", 1, VT_LIST, func(x): return x.min_as_list())
	_add_op("LIST_MAX", 1, VT_LIST, func(x): return x.max_as_list())
	_add_op("LIST_COUNT", 1, VT_LIST, func(x): return x.count())
	_add_op("LIST_VALUE", 1, VT_LIST, func(x): return x.max_item()[1])
	# divert targets
	_add_op("==", 2, VT_DIVERT, func(x, y): return x.equals(y))
	_add_op("!=", 2, VT_DIVERT, func(x, y): return not x.equals(y))


static func _js_div_floor(x, y):
	if y == 0:
		if x == 0:
			return NAN
		return INF if x > 0 else -INF
	return floori(float(x) / float(y))


static func _js_mod(x, y):
	if y == 0:
		return NAN
	return x % y


static func _js_fdiv(x, y):
	return float(x) / float(y)


# parseInt: the whole number at the start of a string, or null
static func _leading_int(s: String):
	var i := 0
	var neg := false
	if i < s.length() and (s[i] == "-" or s[i] == "+"):
		neg = s[i] == "-"
		i += 1
	var start := i
	while i < s.length() and s[i] >= "0" and s[i] <= "9":
		i += 1
	if i == start:
		return null
	var n := s.substr(start, i - start).to_int()
	return -n if neg else n


# ---------------------------------------------------------------- lists

class InkListItem extends RefCounted:
	var origin_name = null
	var item_name = null

	func _init(o = null, i = null) -> void:
		origin_name = o
		item_name = i

	static func from_full_name(full: String) -> InkListItem:
		var parts := full.split(".")
		return InkListItem.new(parts[0], parts[1] if parts.size() > 1 else null)

	static func from_key(k: String) -> InkListItem:
		var dot := k.find(".")
		var o = k.substr(0, dot)
		return InkListItem.new(null if o == "" else o, k.substr(dot + 1))

	static func null_item() -> InkListItem:
		return InkListItem.new(null, null)

	func is_null() -> bool:
		return origin_name == null and item_name == null

	func full_name() -> String:
		return (origin_name if origin_name != null else "?") + "." + str(item_name)

	func key() -> String:
		return (origin_name if origin_name != null else "") + "." + (item_name if item_name != null else "")

	func equals(o) -> bool:
		return o is InkListItem and o.item_name == item_name and o.origin_name == origin_name

	func _to_string() -> String:
		return full_name()


class InkList extends RefCounted:
	var items: Dictionary = {}      # key (origin.item) -> int; keeps order like a JavaScript Map
	var origins = null              # Array of ListDef, or null
	var _origin_names = []          # Array of String, or null

	static func copy_of(other: InkList) -> InkList:
		var l := InkList.new()
		l.items = other.items.duplicate()
		var on = other.origin_names()
		if on != null:
			l._origin_names = on.duplicate()
		if other.origins != null:
			l.origins = other.origins.duplicate()
		return l

	static func single(item: InkListItem, n: int) -> InkList:
		var l := InkList.new()
		l.add(item, n)
		return l

	static func from_origin(list_name: String, story: Story) -> InkList:
		var l := InkList.new()
		l.set_initial_origin_name(list_name)
		var def: ListDef = story.list_definitions.try_get(list_name)
		if def != null:
			l.origins = [def]
		else:
			push_error("InkList origin could not be found in story when constructing new list: " + list_name)
		return l

	func count() -> int:
		return items.size()

	func add(item: InkListItem, n: int) -> void:
		var k := item.key()
		if items.has(k):
			push_error("The Map already contains an entry for " + item.full_name())
			return
		items[k] = n

	func remove(item: InkListItem) -> bool:
		return items.erase(item.key())

	func contains_key(item: InkListItem) -> bool:
		return items.has(item.key())

	func contains_item_named(n: String) -> bool:
		for k in items:
			if k.substr(k.find(".") + 1) == n:
				return true
		return false

	# AddItem, for the game: an item by name, from a list this one already knows about
	func add_item_named(item_name: String, story: Story = null) -> void:
		var found: ListDef = null
		if origins != null:
			for o in origins:
				if o.contains_item_with_name(item_name):
					if found != null:
						push_error("Could not add the item " + item_name + " to this list because it could come from either " + o.name + " or " + found.name)
						return
					found = o
		if found == null:
			if story == null:
				push_error("Could not add the item " + item_name + " to this list because it isn't known to any list definitions previously associated with this list.")
				return
			var lv: ListVal = story.list_definitions.find_single_item_list_with_name(item_name)
			if lv == null:
				push_error("Could not find the InkListItem from the string '" + item_name + "'")
				return
			var first: Array = lv.value.ordered_items()[0]
			add(first[0], first[1])
		else:
			var it := InkListItem.new(found.name, item_name)
			add(it, found.value_for_item(it))

	func origin_of_max_item() -> ListDef:
		if origins == null:
			return null
		var max_origin = max_item()[0].origin_name
		for o in origins:
			if o.name == max_origin:
				return o
		return null

	# inkjs rebuilds this from the items whenever there are any (one name per item)
	func origin_names():
		if items.size() > 0:
			if _origin_names == null:
				_origin_names = []
			else:
				_origin_names.clear()
			for k in items:
				var o = k.substr(0, k.find("."))
				_origin_names.append(o if o != "" else null)
		return _origin_names

	func set_initial_origin_name(n: String) -> void:
		_origin_names = [n]

	func set_initial_origin_names(names) -> void:
		_origin_names = null if names == null else names.duplicate()

	func max_item() -> Array:
		var mk: InkListItem = InkListItem.null_item()
		var mv := 0
		for k in items:
			var v: int = items[k]
			if mk.is_null() or v > mv:
				mk = InkListItem.from_key(k)
				mv = v
		return [mk, mv]

	func min_item() -> Array:
		var mk: InkListItem = InkListItem.null_item()
		var mv := 0
		for k in items:
			var v: int = items[k]
			if mk.is_null() or v < mv:
				mk = InkListItem.from_key(k)
				mv = v
		return [mk, mv]

	func inverse() -> InkList:
		var l := InkList.new()
		if origins != null:
			for o in origins:
				var its: Dictionary = o.items()
				for k in its:
					if not items.has(k):
						l.items[k] = its[k]
		return l

	func all() -> InkList:
		var l := InkList.new()
		if origins != null:
			for o in origins:
				var its: Dictionary = o.items()
				for k in its:
					l.items[k] = its[k]
		return l

	func union(other: InkList) -> InkList:
		var u := InkList.copy_of(self)
		for k in other.items:
			u.items[k] = other.items[k]
		return u

	func intersect(other: InkList) -> InkList:
		var l := InkList.new()
		for k in items:
			if other.items.has(k):
				l.items[k] = items[k]
		return l

	func has_intersection(other: InkList) -> bool:
		for k in items:
			if other.items.has(k):
				return true
		return false

	func without(other: InkList) -> InkList:
		var l := InkList.copy_of(self)
		for k in other.items:
			l.items.erase(k)
		return l

	func contains(what) -> bool:
		if what is String:
			return contains_item_named(what)
		var other: InkList = what
		if other.items.size() == 0 or items.size() == 0:
			return false
		for k in other.items:
			if not items.has(k):
				return false
		return true

	func greater_than(o: InkList) -> bool:
		if count() == 0:
			return false
		if o.count() == 0:
			return true
		return min_item()[1] > o.max_item()[1]

	func greater_than_or_equals(o: InkList) -> bool:
		if count() == 0:
			return false
		if o.count() == 0:
			return true
		return min_item()[1] >= o.min_item()[1] and max_item()[1] >= o.max_item()[1]

	func less_than(o: InkList) -> bool:
		if o.count() == 0:
			return false
		if count() == 0:
			return true
		return max_item()[1] < o.min_item()[1]

	func less_than_or_equals(o: InkList) -> bool:
		if o.count() == 0:
			return false
		if count() == 0:
			return true
		return max_item()[1] <= o.max_item()[1] and min_item()[1] <= o.min_item()[1]

	func max_as_list() -> InkList:
		if count() > 0:
			var m := max_item()
			return InkList.single(m[0], m[1])
		return InkList.new()

	func min_as_list() -> InkList:
		if count() > 0:
			var m := min_item()
			return InkList.single(m[0], m[1])
		return InkList.new()

	func list_with_sub_range(min_bound, max_bound) -> InkList:
		if count() == 0:
			return InkList.new()
		var ordered := ordered_items()
		var min_value := 0
		var max_value: int = MAX_SAFE_INTEGER
		if min_bound is int or (min_bound is float and Ink.is_whole(min_bound)):
			min_value = int(min_bound)
		elif min_bound is InkList and min_bound.count() > 0:
			min_value = min_bound.min_item()[1]
		if max_bound is int or (max_bound is float and Ink.is_whole(max_bound)):
			max_value = int(max_bound)
		elif max_bound is InkList and max_bound.count() > 0:
			max_value = max_bound.max_item()[1]
		var sub := InkList.new()
		sub.set_initial_origin_names(origin_names())
		for it in ordered:
			if it[1] >= min_value and it[1] <= max_value:
				sub.add(it[0], it[1])
		return sub

	func equals(o) -> bool:
		if not (o is InkList):
			return false
		if o.count() != count():
			return false
		for k in items:
			if not o.items.has(k):
				return false
		return true

	# [[item, value], ...] by value, then origin name; stable, like the sort inkjs relies on
	func ordered_items() -> Array:
		var out: Array = []
		for k in items:
			var entry := [InkListItem.from_key(k), items[k]]
			var j := out.size()
			while j > 0 and Ink._list_entry_less(entry, out[j - 1]):
				j -= 1
			out.insert(j, entry)
		return out

	func single_item() -> InkListItem:
		var o := ordered_items()
		return o[0][0] if o.size() > 0 else null

	func text() -> String:
		var parts := PackedStringArray()
		for it in ordered_items():
			parts.append(str(it[0].item_name))
		return ", ".join(parts)

	func _to_string() -> String:
		return text()

	# the item names, lowest value first (what the game reads a list as)
	func names() -> Array:
		var out: Array = []
		for it in ordered_items():
			out.append(it[0].item_name)
		return out


static func _list_entry_less(a: Array, b: Array) -> bool:
	if a[1] == b[1]:
		return _locale_compare(str(a[0].origin_name), str(b[0].origin_name)) < 0
	return a[1] < b[1]


# near enough to localeCompare for ink identifiers: letters before case, then case
static func _locale_compare(a: String, b: String) -> int:
	var la := a.to_lower()
	var lb := b.to_lower()
	if la != lb:
		return -1 if la < lb else 1
	if a == b:
		return 0
	return -1 if a > b else 1


class ListDef extends RefCounted:
	var name := ""
	var item_name_to_values: Dictionary = {}
	var _items = null

	func _init(n := "", its: Dictionary = {}) -> void:
		name = n
		item_name_to_values = its

	func items() -> Dictionary:
		if _items == null:
			_items = {}
			for k in item_name_to_values:
				_items[InkListItem.new(name, k).key()] = item_name_to_values[k]
		return _items

	func value_for_item(item: InkListItem) -> int:
		if item.item_name == null or item.item_name == "":
			return 0
		return item_name_to_values.get(item.item_name, 0)

	func contains_item(item: InkListItem) -> bool:
		if item.item_name == null or item.item_name == "":
			return false
		if item.origin_name != name:
			return false
		return item_name_to_values.has(item.item_name)

	func contains_item_with_name(n: String) -> bool:
		return item_name_to_values.has(n)

	# the item with this value, or null
	func try_get_item_with_value(v: int) -> InkListItem:
		for k in item_name_to_values:
			if item_name_to_values[k] == v:
				return InkListItem.new(name, k)
		return null

	# the value of this item, or null (inkjs treats a value of 0 as not found)
	func try_get_value_for_item(item: InkListItem):
		if item.item_name == null or item.item_name == "":
			return null
		var v = item_name_to_values.get(item.item_name)
		if v == null or v == 0:
			return null
		return v


class ListDefs extends RefCounted:
	var lists: Dictionary = {}
	var _single: Dictionary = {}

	func _init(defs: Array = []) -> void:
		for d in defs:
			lists[d.name] = d
			var its: Dictionary = d.items()
			for k in its:
				var item := InkListItem.from_key(k)
				var lv := ListVal.single(item, its[k])
				_single[item.item_name] = lv
				_single[item.full_name()] = lv

	func try_get(n) -> ListDef:
		if n == null:
			return null
		return lists.get(n)

	func find_single_item_list_with_name(n: String) -> ListVal:
		return _single.get(n)


class PRNG extends RefCounted:
	var seed: int

	func _init(s: int) -> void:
		seed = s % 2147483647
		if seed <= 0:
			seed += 2147483646

	func next() -> int:
		seed = (seed * 48271) % 2147483647
		return seed

	func next_float() -> float:
		return float(next() - 1) / 2147483646.0


# ---------------------------------------------------------------- the call stack

class CSElement extends RefCounted:
	var current_pointer: Pointer
	var in_expression_evaluation := false
	var temporary_variables: Dictionary = {}
	var type := 0
	var evaluation_stack_height_when_pushed := 0
	var function_start_in_output_stream := 0

	func _init(t: int = 0, p: Pointer = null, in_expr := false) -> void:
		type = t
		current_pointer = p.copy() if p != null else Pointer.null_ptr()
		in_expression_evaluation = in_expr

	func copy() -> CSElement:
		var c := CSElement.new(type, current_pointer, in_expression_evaluation)
		c.temporary_variables = temporary_variables.duplicate()
		c.evaluation_stack_height_when_pushed = evaluation_stack_height_when_pushed
		c.function_start_in_output_stream = function_start_in_output_stream
		return c


class CSThread extends RefCounted:
	var callstack: Array = []
	var thread_index := 0
	var previous_pointer: Pointer = Pointer.null_ptr()

	func copy() -> CSThread:
		var c := CSThread.new()
		c.thread_index = thread_index
		for e in callstack:
			c.callstack.append(e.copy())
		c.previous_pointer = previous_pointer.copy()
		return c

	static func from_json(j: Dictionary, story: Story) -> CSThread:
		var t := CSThread.new()
		t.thread_index = Ink.jint(j.get("threadIndex", 0))
		for jel in j.get("callstack", []):
			var type := Ink.jint(jel.get("type", 0))
			var p := Pointer.null_ptr()
			if jel.has("cPath"):
				var path_str := str(jel["cPath"])
				var res: SearchResult = story.content_at_path(InkPath.from_string(path_str))
				p = Pointer.new(res.container(), Ink.jint(jel.get("idx", 0)))
				if res.obj == null:
					push_error("When loading state, internal story location couldn't be found: " + path_str + ". Has the story changed since this save data was created?")
				elif res.approximate:
					story.warning("When loading state, exact internal story location couldn't be found: '" + path_str + "'. Has the story changed since this save data was created?")
			var el := CSElement.new(type, p, bool(jel.get("exp", false)))
			if jel.has("temp"):
				el.temporary_variables = Ink.json_dict_to_objs(jel["temp"])
			t.callstack.append(el)
		if j.has("previousContentObject"):
			t.previous_pointer = story.pointer_at_path(InkPath.from_string(str(j["previousContentObject"])))
		return t

	func to_json() -> Dictionary:
		var cs: Array = []
		for el in callstack:
			var o := {}
			if not el.current_pointer.is_null():
				o["cPath"] = el.current_pointer.container.path().components_string()
				o["idx"] = el.current_pointer.index
			o["exp"] = el.in_expression_evaluation
			o["type"] = el.type
			if el.temporary_variables.size() > 0:
				o["temp"] = Ink.json_objs_to_dict(el.temporary_variables)
			cs.append(o)
		var out := {"callstack": cs, "threadIndex": thread_index}
		if not previous_pointer.is_null():
			out["previousContentObject"] = previous_pointer.resolve().path().text()
		return out


class CallStack extends RefCounted:
	var _threads: Array = []
	var _thread_counter := 0
	var _start_of_root: Pointer = Pointer.null_ptr()

	static func for_story(story: Story) -> CallStack:
		var c := CallStack.new()
		c._start_of_root = Pointer.start_of(story.root_content_container())
		c.reset()
		return c

	static func copy_of(other: CallStack) -> CallStack:
		var c := CallStack.new()
		for t in other._threads:
			c._threads.append(t.copy())
		c._thread_counter = other._thread_counter
		c._start_of_root = other._start_of_root.copy()
		return c

	func reset() -> void:
		_threads = [CSThread.new()]
		_threads[0].callstack.append(CSElement.new(PP_TUNNEL, _start_of_root))

	func set_json_token(j: Dictionary, story: Story) -> void:
		_threads.clear()
		for jt in j.get("threads", []):
			_threads.append(CSThread.from_json(jt, story))
		_thread_counter = Ink.jint(j.get("threadCounter", 0))
		_start_of_root = Pointer.start_of(story.root_content_container())

	func to_json() -> Dictionary:
		var ts: Array = []
		for t in _threads:
			ts.append(t.to_json())
		return {"threads": ts, "threadCounter": _thread_counter}

	func elements() -> Array:
		return _threads[_threads.size() - 1].callstack

	func depth() -> int:
		return elements().size()

	func current_element() -> CSElement:
		var cs: Array = _threads[_threads.size() - 1].callstack
		return cs[cs.size() - 1]

	func current_element_index() -> int:
		return elements().size() - 1

	func current_thread() -> CSThread:
		return _threads[_threads.size() - 1]

	func set_current_thread(t: CSThread) -> void:
		if _threads.size() != 1:
			push_warning("Shouldn't be directly setting the current thread when we have a stack of them")
		_threads = [t]

	func can_pop() -> bool:
		return elements().size() > 1

	func push_thread() -> void:
		var t: CSThread = current_thread().copy()
		_thread_counter += 1
		t.thread_index = _thread_counter
		_threads.append(t)

	func fork_thread() -> CSThread:
		var t: CSThread = current_thread().copy()
		_thread_counter += 1
		t.thread_index = _thread_counter
		return t

	func pop_thread() -> void:
		if can_pop_thread():
			_threads.remove_at(_threads.size() - 1)
		else:
			Ink._throw_global("Can't pop thread")

	func can_pop_thread() -> bool:
		return _threads.size() > 1 and not element_is_evaluate_from_game()

	func element_is_evaluate_from_game() -> bool:
		return current_element().type == PP_FUNCTION_EVAL_FROM_GAME

	func push(type: int, external_eval_stack_height := 0, output_stream_length_with_pushed := 0) -> void:
		var el := CSElement.new(type, current_element().current_pointer, false)
		el.evaluation_stack_height_when_pushed = external_eval_stack_height
		el.function_start_in_output_stream = output_stream_length_with_pushed
		elements().append(el)

	func can_pop_type(type = null) -> bool:
		if not can_pop():
			return false
		if type == null:
			return true
		return current_element().type == type

	func pop(type = null) -> void:
		if can_pop_type(type):
			var e := elements()
			e.remove_at(e.size() - 1)
		else:
			Ink._throw_global("Mismatched push/pop in Callstack")

	func get_temporary_variable_with_name(n: String, context_index := -1) -> Obj:
		if context_index == -1:
			context_index = current_element_index() + 1
		var e := elements()
		if context_index - 1 < 0 or context_index - 1 >= e.size():
			return null
		return e[context_index - 1].temporary_variables.get(n)

	func set_temporary_variable(n: String, value: Obj, declare_new: bool, context_index := -1) -> void:
		if context_index == -1:
			context_index = current_element_index() + 1
		var el: CSElement = elements()[context_index - 1]
		if not declare_new and not el.temporary_variables.has(n):
			Ink._throw_global("Could not find temporary variable to set: " + n)
			return
		if el.temporary_variables.has(n):
			ListVal.retain_list_origins_for_assignment(el.temporary_variables[n], value)
		el.temporary_variables[n] = value

	func context_for_variable_named(n: String) -> int:
		if current_element().temporary_variables.has(n):
			return current_element_index() + 1
		return 0

	func thread_with_index(i: int) -> CSThread:
		for t in _threads:
			if t.thread_index == i:
				return t
		return null

	func call_stack_trace() -> String:
		var sb := ""
		for ti in range(_threads.size()):
			var t: CSThread = _threads[ti]
			sb += "=== THREAD " + str(ti + 1) + "/" + str(_threads.size()) + " " + ("(current) " if ti == _threads.size() - 1 else "") + "===\n"
			for el in t.callstack:
				sb += "  [FUNCTION] " if el.type == PP_FUNCTION else "  [TUNNEL] "
				if not el.current_pointer.is_null():
					sb += "<SOMEWHERE IN " + el.current_pointer.container.path().text() + ">\n"
		return sb


class Flow extends RefCounted:
	var name := ""
	var call_stack: CallStack
	var output_stream: Array = []
	var current_choices: Array = []

	static func make(n: String, story: Story, j = null) -> Flow:
		var f := Flow.new()
		f.name = n
		f.call_stack = CallStack.for_story(story)
		if j != null:
			f.call_stack.set_json_token(j["callstack"], story)
			f.output_stream = Ink.json_array_to_objs(j.get("outputStream", []))
			f.current_choices = Ink.json_array_to_objs(j.get("currentChoices", []))
			if j.has("choiceThreads"):
				f.load_flow_choice_threads(j["choiceThreads"], story)
			else:
				f.load_flow_choice_threads({}, story)
		return f

	func to_json() -> Dictionary:
		var out := {"callstack": call_stack.to_json(), "outputStream": Ink.json_objs_to_array(output_stream)}
		var choice_threads := {}
		for c in current_choices:
			c.original_thread_index = c.thread_at_generation.thread_index
			if call_stack.thread_with_index(c.original_thread_index) == null:
				choice_threads[str(c.original_thread_index)] = c.thread_at_generation.to_json()
		if choice_threads.size() > 0:
			out["choiceThreads"] = choice_threads
		var cs: Array = []
		for c in current_choices:
			cs.append(Ink.choice_to_json(c))
		out["currentChoices"] = cs
		return out

	func load_flow_choice_threads(j: Dictionary, story: Story) -> void:
		for c in current_choices:
			var t: CSThread = call_stack.thread_with_index(c.original_thread_index)
			if t != null:
				c.thread_at_generation = t.copy()
			else:
				c.thread_at_generation = CSThread.from_json(j[str(c.original_thread_index)], story)


class StatePatch extends RefCounted:
	var globals: Dictionary = {}
	var changed_variables: Dictionary = {}
	var visit_counts: Dictionary = {}
	var turn_indices: Dictionary = {}

	func _init(to_copy: StatePatch = null) -> void:
		if to_copy != null:
			globals = to_copy.globals.duplicate()
			changed_variables = to_copy.changed_variables.duplicate()
			visit_counts = to_copy.visit_counts.duplicate()
			turn_indices = to_copy.turn_indices.duplicate()


# ---------------------------------------------------------------- variables

class VariablesState extends RefCounted:
	var patch: StatePatch = null
	var _defaults: Dictionary = {}
	var _globals: Dictionary = {}
	var call_stack: CallStack
	var _list_defs: ListDefs

	func _init(cs: CallStack = null, list_defs: ListDefs = null) -> void:
		call_stack = cs
		_list_defs = list_defs

	# story.variablesState[name]: a global's value as the game sees it, or null
	func get_value(n: String):
		if patch != null and patch.globals.has(n):
			return patch.globals[n].value_object()
		var v = _globals.get(n)
		if v == null:
			v = _defaults.get(n)
		if v != null:
			return v.value_object()
		return null

	# story.variablesState[name] = value
	func set_value(n: String, value) -> bool:
		if not _defaults.has(n):
			push_warning("Cannot assign to a variable (" + n + ") that hasn't been declared in the story")
			return false
		var v := Ink.create_value(value)
		if v == null:
			push_warning("Invalid value passed to VariableState: " + str(value))
			return false
		set_global(n, v)
		return true

	func global_names() -> Array:
		return _globals.keys()

	func apply_patch() -> void:
		for k in patch.globals:
			_globals[k] = patch.globals[k]
		patch = null

	func set_json_token(j: Dictionary) -> void:
		_globals.clear()
		for k in _defaults:
			if j.has(k):
				_globals[k] = Ink.json_to_obj(j[k])
			else:
				_globals[k] = _defaults[k]

	func to_json() -> Dictionary:
		var out := {}
		for k in _globals:
			var v: Obj = _globals[k]
			if _defaults.has(k) and Ink.runtime_objects_equal(v, _defaults[k]):
				continue
			out[k] = Ink.obj_to_json(v)
		return out

	func get_variable_with_name(n: String, context_index := -1) -> Obj:
		var v := get_raw_variable_with_name(n, context_index)
		if v != null and v.kind == K_VAL and v.vtype == VT_VAR_PTR:
			v = value_at_variable_pointer(v)
		return v

	func try_get_default_variable_value(n: String) -> Obj:
		return _defaults.get(n)

	func global_variable_exists_with_name(n: String) -> bool:
		return _globals.has(n) or _defaults.has(n)

	func get_raw_variable_with_name(n: String, context_index: int) -> Obj:
		if context_index == 0 or context_index == -1:
			var v: Obj
			if patch != null:
				v = patch.globals.get(n)
				if v != null:
					return v
			v = _globals.get(n)
			if v != null:
				return v
			v = _defaults.get(n)
			if v != null:
				return v
			if _list_defs != null:
				v = _list_defs._single.get(n)
				if v != null:
					return v
		return call_stack.get_temporary_variable_with_name(n, context_index)

	func value_at_variable_pointer(p: VarPtrVal) -> Obj:
		return get_variable_with_name(p.value, p.context_index)

	func assign(va: VarAssign, value: Obj) -> void:
		var n: String = va.variable_name
		var context_index := -1
		var set_global_var := false
		if va.is_new_declaration:
			set_global_var = va.is_global
		else:
			set_global_var = global_variable_exists_with_name(n)
		if va.is_new_declaration:
			if value != null and value.kind == K_VAL and value.vtype == VT_VAR_PTR:
				value = resolve_variable_pointer(value)
		else:
			var existing: Obj = null
			while true:
				existing = get_raw_variable_with_name(n, context_index)
				if existing != null and existing.kind == K_VAL and existing.vtype == VT_VAR_PTR:
					n = existing.value
					context_index = existing.context_index
					set_global_var = context_index == 0
				else:
					break
		if set_global_var:
			set_global(n, value)
		else:
			call_stack.set_temporary_variable(n, value, va.is_new_declaration, context_index)

	func snapshot_default_globals() -> void:
		_defaults = _globals.duplicate()

	func set_global(n: String, value: Obj) -> void:
		var old_value: Obj = null
		if patch == null:
			old_value = _globals.get(n)
		else:
			old_value = patch.globals.get(n)
			if old_value == null:
				old_value = _globals.get(n)
		ListVal.retain_list_origins_for_assignment(old_value, value)
		if patch != null:
			patch.globals[n] = value
		else:
			_globals[n] = value
		# (inkjs tells variable observers here; nothing in the game observes)

	func resolve_variable_pointer(p: VarPtrVal) -> VarPtrVal:
		var ci := p.context_index
		if ci == -1:
			ci = get_context_index_of_variable_named(p.value)
		var pointed := get_raw_variable_with_name(p.value, ci)
		if pointed != null and pointed.kind == K_VAL and pointed.vtype == VT_VAR_PTR:
			return pointed
		return VarPtrVal.new(p.value, ci)

	func get_context_index_of_variable_named(n: String) -> int:
		if global_variable_exists_with_name(n):
			return 0
		return call_stack.current_element_index()


static func runtime_objects_equal(a: Obj, b: Obj) -> bool:
	if a == null or b == null:
		return false
	if a.get_script() != b.get_script():
		return false
	if a.kind == K_VAL:
		if a.vtype == VT_LIST:
			return a.value.equals(b.value)
		if a.vtype == VT_DIVERT:
			return a.value.equals(b.value)
		return a.value == b.value
	return a == b


# ---------------------------------------------------------------- the story's state

class StoryState extends RefCounted:
	var story: Story
	var _current_flow: Flow
	var _named_flows = null            # Dictionary name -> Flow, or null
	var _alive_flow_names_dirty := true
	var _evaluation_stack: Array = []
	var variables_state: VariablesState
	var _visit_counts: Dictionary = {}
	var _turn_indices: Dictionary = {}
	var current_turn_index := -1
	var story_seed := 0
	var previous_random := 0
	var did_safe_exit := false
	var diverted_pointer: Pointer = Pointer.null_ptr()
	var _current_errors = null
	var _current_warnings = null
	var _current_text = null
	var _current_tags: Array = []
	var _text_dirty := true
	var _tags_dirty := true
	var _patch: StatePatch = null

	func _init(s: Story = null, bare := false) -> void:
		story = s
		if bare or s == null:
			return
		_current_flow = Flow.make(DEFAULT_FLOW, s)
		output_stream_dirty()
		variables_state = VariablesState.new(_current_flow.call_stack, s.list_definitions)
		current_turn_index = -1
		story_seed = PRNG.new(int(Time.get_unix_time_from_system() * 1000.0) % 2147483647).next() % 100
		previous_random = 0
		go_to_start()

	func go_to_start() -> void:
		call_stack().current_element().current_pointer = Pointer.start_of(story.main_content_container())

	# ---- flows ----

	func switch_flow_internal(flow_name: String) -> void:
		if _named_flows == null:
			_named_flows = {}
			_named_flows[DEFAULT_FLOW] = _current_flow
		if flow_name == _current_flow.name:
			return
		var flow: Flow = _named_flows.get(flow_name)
		if flow == null:
			flow = Flow.make(flow_name, story)
			_named_flows[flow_name] = flow
			_alive_flow_names_dirty = true
		_current_flow = flow
		variables_state.call_stack = _current_flow.call_stack
		output_stream_dirty()

	func switch_to_default_flow_internal() -> void:
		if _named_flows == null:
			return
		switch_flow_internal(DEFAULT_FLOW)

	func remove_flow_internal(flow_name: String) -> void:
		if flow_name == DEFAULT_FLOW:
			push_error("Cannot destroy default flow")
			return
		if _current_flow.name == flow_name:
			switch_to_default_flow_internal()
		if _named_flows != null:
			_named_flows.erase(flow_name)
		_alive_flow_names_dirty = true

	# ---- visits and turns ----

	func visit_count_at_path_string(path_string: String) -> int:
		if _patch != null:
			var c: Cont = story.content_at_path(InkPath.from_string(path_string)).container()
			if c == null:
				push_error("Content at path not found: " + path_string)
				return 0
			if _patch.visit_counts.has(c):
				return _patch.visit_counts[c]
		return _visit_counts.get(path_string, 0)

	func visit_count_for_container(c: Cont) -> int:
		if c == null:
			Ink._throw_global("container is null")
			return 0
		if not c.visits_should_be_counted:
			story.error("Read count for target (" + str(c.name) + ") unknown. The story may need to be compiled with countAllVisits flag (-c).")
			return 0
		if _patch != null and _patch.visit_counts.has(c):
			return _patch.visit_counts[c]
		return _visit_counts.get(c.path().text(), 0)

	func increment_visit_count_for_container(c: Cont) -> void:
		if _patch != null:
			var cur := visit_count_for_container(c)
			_patch.visit_counts[c] = cur + 1
			return
		var k := c.path().text()
		_visit_counts[k] = _visit_counts.get(k, 0) + 1

	func record_turn_index_visit_to_container(c: Cont) -> void:
		if _patch != null:
			_patch.turn_indices[c] = current_turn_index
			return
		_turn_indices[c.path().text()] = current_turn_index

	func turns_since_for_container(c: Cont) -> int:
		if not c.turn_index_should_be_counted:
			story.error("TURNS_SINCE() for target (" + str(c.name) + ") unknown. The story may need to be compiled with countAllVisits flag (-c).")
		if _patch != null and _patch.turn_indices.has(c):
			return current_turn_index - _patch.turn_indices[c]
		var k := c.path().text()
		if _turn_indices.has(k):
			return current_turn_index - _turn_indices[k]
		return -1

	# ---- accessors ----

	func callstack_depth() -> int:
		return call_stack().depth()

	func output_stream() -> Array:
		return _current_flow.output_stream

	func current_choices() -> Array:
		if can_continue():
			return []
		return _current_flow.current_choices

	func generated_choices() -> Array:
		return _current_flow.current_choices

	func current_errors():
		return _current_errors

	func current_warnings():
		return _current_warnings

	func call_stack() -> CallStack:
		return _current_flow.call_stack

	func evaluation_stack() -> Array:
		return _evaluation_stack

	func current_path_string():
		var p := current_pointer()
		if p.is_null():
			return null
		return p.path().text()

	func previous_path_string():
		var p := previous_pointer()
		if p.is_null():
			return null
		return p.path().text()

	func current_pointer() -> Pointer:
		return call_stack().current_element().current_pointer

	func set_current_pointer(p: Pointer) -> void:
		call_stack().current_element().current_pointer = p

	func previous_pointer() -> Pointer:
		return call_stack().current_thread().previous_pointer

	func set_previous_pointer(p: Pointer) -> void:
		call_stack().current_thread().previous_pointer = p

	func can_continue() -> bool:
		return not call_stack().current_element().current_pointer.is_null() and not has_error()

	func has_error() -> bool:
		return _current_errors != null and _current_errors.size() > 0

	func has_warning() -> bool:
		return _current_warnings != null and _current_warnings.size() > 0

	func in_expression_evaluation() -> bool:
		return call_stack().current_element().in_expression_evaluation

	func set_in_expression_evaluation(v: bool) -> void:
		call_stack().current_element().in_expression_evaluation = v

	func current_flow_name() -> String:
		return _current_flow.name

	# ---- text and tags ----

	func current_text() -> String:
		if _text_dirty:
			var sb := ""
			var in_tag := false
			for o in output_stream():
				if not in_tag and o.kind == K_VAL and o.vtype == VT_STRING:
					sb += o.value
				elif o.kind == K_CMD:
					if o.type == C_BEGIN_TAG:
						in_tag = true
					elif o.type == C_END_TAG:
						in_tag = false
			_current_text = clean_output_whitespace(sb)
			_text_dirty = false
		return _current_text

	func clean_output_whitespace(s: String) -> String:
		var sb := ""
		var ws_start := -1
		var start_of_line := 0
		for i in range(s.length()):
			var c: String = s[i]
			var inline_ws := c == " " or c == "\t"
			if inline_ws and ws_start == -1:
				ws_start = i
			if not inline_ws:
				if c != "\n" and ws_start > 0 and ws_start != start_of_line:
					sb += " "
				ws_start = -1
			if c == "\n":
				start_of_line = i + 1
			if not inline_ws:
				sb += c
		return sb

	func current_tags() -> Array:
		if _tags_dirty:
			_current_tags = []
			var in_tag := false
			var sb := ""
			for o in output_stream():
				if o.kind == K_CMD:
					if o.type == C_BEGIN_TAG:
						if in_tag and sb.length() > 0:
							_current_tags.append(clean_output_whitespace(sb))
							sb = ""
						in_tag = true
					elif o.type == C_END_TAG:
						if sb.length() > 0:
							_current_tags.append(clean_output_whitespace(sb))
							sb = ""
						in_tag = false
				elif in_tag:
					if o.kind == K_VAL and o.vtype == VT_STRING:
						sb += o.value
				elif o.kind == K_TAG:
					if o.text_value.length() > 0:
						_current_tags.append(o.text_value)
			if sb.length() > 0:
				_current_tags.append(clean_output_whitespace(sb))
			_tags_dirty = false
		return _current_tags

	# ---- snapshots ----

	func copy_and_start_patching(for_background_save: bool) -> StoryState:
		var copy := StoryState.new(story, true)
		copy._patch = StatePatch.new(_patch)
		copy._current_flow = Flow.new()
		copy._current_flow.name = _current_flow.name
		copy._current_flow.call_stack = CallStack.copy_of(_current_flow.call_stack)
		copy._current_flow.output_stream = _current_flow.output_stream.duplicate()
		copy.output_stream_dirty()
		if for_background_save:
			for c in _current_flow.current_choices:
				copy._current_flow.current_choices.append(c.clone())
		else:
			copy._current_flow.current_choices = _current_flow.current_choices.duplicate()
		if _named_flows != null:
			copy._named_flows = {}
			for k in _named_flows:
				copy._named_flows[k] = _named_flows[k]
			copy._alive_flow_names_dirty = true
			copy._named_flows[_current_flow.name] = copy._current_flow
		if has_error():
			copy._current_errors = _current_errors.duplicate()
		if has_warning():
			copy._current_warnings = _current_warnings.duplicate()
		copy.variables_state = variables_state
		copy.variables_state.call_stack = copy.call_stack()
		copy.variables_state.patch = copy._patch
		copy._evaluation_stack = _evaluation_stack.duplicate()
		if not diverted_pointer.is_null():
			copy.diverted_pointer = diverted_pointer.copy()
		copy.set_previous_pointer(previous_pointer())
		copy._visit_counts = _visit_counts
		copy._turn_indices = _turn_indices
		copy.current_turn_index = current_turn_index
		copy.story_seed = story_seed
		copy.previous_random = previous_random
		copy.did_safe_exit = did_safe_exit
		return copy

	func restore_after_patch() -> void:
		variables_state.call_stack = call_stack()
		variables_state.patch = _patch

	func apply_any_patch() -> void:
		if _patch == null:
			return
		variables_state.apply_patch()
		for c in _patch.visit_counts:
			_visit_counts[c.path().text()] = _patch.visit_counts[c]
		for c in _patch.turn_indices:
			_turn_indices[c.path().text()] = _patch.turn_indices[c]
		_patch = null

	# ---- saving ----

	func to_json() -> String:
		return JSON.stringify(to_json_obj())

	func to_json_obj() -> Dictionary:
		var flows := {}
		if _named_flows != null:
			for k in _named_flows:
				flows[k] = _named_flows[k].to_json()
		else:
			flows[_current_flow.name] = _current_flow.to_json()
		var out := {
			"flows": flows,
			"currentFlowName": _current_flow.name,
			"variablesState": variables_state.to_json(),
			"evalStack": Ink.json_objs_to_array(_evaluation_stack),
			"visitCounts": _visit_counts.duplicate(),
			"turnIndices": _turn_indices.duplicate(),
			"turnIdx": current_turn_index,
			"storySeed": story_seed,
			"previousRandom": previous_random,
			"inkSaveVersion": SAVE_VERSION,
			"inkFormatVersion": INK_VERSION_CURRENT,
		}
		if not diverted_pointer.is_null():
			out["currentDivertTarget"] = diverted_pointer.path().components_string()
		return out

	func load_json(text: String) -> bool:
		var j = JSON.parse_string(text)
		if not (j is Dictionary):
			push_error("ink save isn't JSON")
			return false
		return load_json_obj(j)

	func load_json_obj(j: Dictionary) -> bool:
		if not j.has("inkSaveVersion"):
			push_error("ink save format incorrect, can't load.")
			return false
		if Ink.jint(j["inkSaveVersion"]) < SAVE_VERSION_MIN:
			push_error("Ink save format isn't compatible with the current version, so can't load.")
			return false
		var flows = j.get("flows")
		if flows != null:
			if flows.size() == 1:
				_named_flows = null
			else:
				_named_flows = {}
			for k in flows:
				var flow := Flow.make(k, story, flows[k])
				if flows.size() == 1:
					_current_flow = flow
				else:
					_named_flows[k] = flow
			if _named_flows != null and _named_flows.size() > 1:
				_current_flow = _named_flows[str(j["currentFlowName"])]
		output_stream_dirty()
		_alive_flow_names_dirty = true
		variables_state.set_json_token(j.get("variablesState", {}))
		variables_state.call_stack = _current_flow.call_stack
		_evaluation_stack = Ink.json_array_to_objs(j.get("evalStack", []))
		if j.has("currentDivertTarget"):
			diverted_pointer = story.pointer_at_path(InkPath.from_string(str(j["currentDivertTarget"])))
		_visit_counts = {}
		for k in j.get("visitCounts", {}):
			_visit_counts[k] = Ink.jint(j["visitCounts"][k])
		_turn_indices = {}
		for k in j.get("turnIndices", {}):
			_turn_indices[k] = Ink.jint(j["turnIndices"][k])
		current_turn_index = Ink.jint(j.get("turnIdx", 0))
		story_seed = Ink.jint(j.get("storySeed", 0))
		previous_random = Ink.jint(j.get("previousRandom", 0))
		return true

	# ---- output ----

	func reset_errors() -> void:
		_current_errors = null
		_current_warnings = null

	func reset_output(objs = null) -> void:
		_current_flow.output_stream.clear()
		if objs != null:
			_current_flow.output_stream.append_array(objs)
		output_stream_dirty()

	func push_to_output_stream(obj: Obj) -> void:
		if obj.kind == K_VAL and obj.vtype == VT_STRING:
			var parts = try_splitting_head_tail_whitespace(obj)
			if parts != null:
				for t in parts:
					push_to_output_stream_individual(t)
				output_stream_dirty()
				return
		push_to_output_stream_individual(obj)
		output_stream_dirty()

	func pop_from_output_stream(n: int) -> void:
		var os := output_stream()
		os.resize(os.size() - n)
		output_stream_dirty()

	func try_splitting_head_tail_whitespace(single: StrVal):
		var s: String = single.value
		var head_first_nl := -1
		var head_last_nl := -1
		for i in range(s.length()):
			var c: String = s[i]
			if c == "\n":
				if head_first_nl == -1:
					head_first_nl = i
				head_last_nl = i
			elif c == " " or c == "\t":
				continue
			else:
				break
		var tail_last_nl := -1
		var tail_first_nl := -1
		for i in range(s.length() - 1, -1, -1):
			var c: String = s[i]
			if c == "\n":
				if tail_last_nl == -1:
					tail_last_nl = i
				tail_first_nl = i
			elif c == " " or c == "\t":
				continue
			else:
				break
		if head_first_nl == -1 and tail_last_nl == -1:
			return null
		var out: Array = []
		var inner_start := 0
		var inner_end := s.length()
		if head_first_nl != -1:
			if head_first_nl > 0:
				out.append(StrVal.new(s.substr(0, head_first_nl)))
			out.append(StrVal.new("\n"))
			inner_start = head_last_nl + 1
		if tail_last_nl != -1:
			inner_end = tail_first_nl
		if inner_end > inner_start:
			out.append(StrVal.new(s.substr(inner_start, inner_end - inner_start)))
		if tail_last_nl != -1 and tail_first_nl > head_last_nl:
			out.append(StrVal.new("\n"))
			if tail_last_nl < s.length() - 1:
				var num_spaces := s.length() - tail_last_nl - 1
				out.append(StrVal.new(s.substr(tail_last_nl + 1, num_spaces)))
		return out

	func push_to_output_stream_individual(obj: Obj) -> void:
		var include := true
		var os := output_stream()
		if obj.kind == K_GLUE:
			trim_newlines_from_output_stream()
			include = true
		elif obj.kind == K_VAL and obj.vtype == VT_STRING:
			var text: StrVal = obj
			var function_trim_index := -1
			var cur_el := call_stack().current_element()
			if cur_el.type == PP_FUNCTION:
				function_trim_index = cur_el.function_start_in_output_stream
			var glue_trim_index := -1
			for i in range(os.size() - 1, -1, -1):
				var o: Obj = os[i]
				if o.kind == K_GLUE:
					glue_trim_index = i
					break
				elif o.kind == K_CMD and o.type == C_BEGIN_STRING:
					if i >= function_trim_index:
						function_trim_index = -1
					break
			var trim_index := -1
			if glue_trim_index != -1 and function_trim_index != -1:
				trim_index = mini(function_trim_index, glue_trim_index)
			elif glue_trim_index != -1:
				trim_index = glue_trim_index
			else:
				trim_index = function_trim_index
			if trim_index != -1:
				if text.is_newline:
					include = false
				elif text.is_non_whitespace():
					if glue_trim_index > -1:
						remove_existing_glue()
					if function_trim_index > -1:
						var els := call_stack().elements()
						for i in range(els.size() - 1, -1, -1):
							var el: CSElement = els[i]
							if el.type == PP_FUNCTION:
								el.function_start_in_output_stream = -1
							else:
								break
			elif text.is_newline:
				if output_stream_ends_in_newline() or not output_stream_contains_content():
					include = false
		if include:
			os.append(obj)
			output_stream_dirty()

	func trim_newlines_from_output_stream() -> void:
		var os := output_stream()
		var remove_from := -1
		var i := os.size() - 1
		while i >= 0:
			var o: Obj = os[i]
			if o.kind == K_CMD or (o.kind == K_VAL and o.vtype == VT_STRING and o.is_non_whitespace()):
				break
			elif o.kind == K_VAL and o.vtype == VT_STRING and o.is_newline:
				remove_from = i
			i -= 1
		if remove_from >= 0:
			i = remove_from
			while i < os.size():
				var o: Obj = os[i]
				if o.kind == K_VAL and o.vtype == VT_STRING:
					os.remove_at(i)
				else:
					i += 1
		output_stream_dirty()

	func remove_existing_glue() -> void:
		var os := output_stream()
		for i in range(os.size() - 1, -1, -1):
			var o: Obj = os[i]
			if o.kind == K_GLUE:
				os.remove_at(i)
			elif o.kind == K_CMD:
				break
		output_stream_dirty()

	func output_stream_ends_in_newline() -> bool:
		var os := output_stream()
		for i in range(os.size() - 1, -1, -1):
			var o: Obj = os[i]
			if o.kind == K_CMD:
				break
			if o.kind == K_VAL and o.vtype == VT_STRING:
				if o.is_newline:
					return true
				elif o.is_non_whitespace():
					break
		return false

	func output_stream_contains_content() -> bool:
		for o in output_stream():
			if o.kind == K_VAL and o.vtype == VT_STRING:
				return true
		return false

	func in_string_evaluation() -> bool:
		var os := output_stream()
		for i in range(os.size() - 1, -1, -1):
			var o: Obj = os[i]
			if o.kind == K_CMD and o.type == C_BEGIN_STRING:
				return true
		return false

	# ---- evaluation stack ----

	func push_evaluation_stack(obj: Obj) -> void:
		if obj == null:
			Ink._throw_global("pushed null onto the evaluation stack")
			return
		if obj.kind == K_VAL and obj.vtype == VT_LIST:
			var raw: InkList = obj.value
			var names = raw.origin_names()
			if names != null:
				if raw.origins == null:
					raw.origins = []
				raw.origins.clear()
				for n in names:
					var def: ListDef = story.list_definitions.try_get(n)
					if def != null and not raw.origins.has(def):
						raw.origins.append(def)
		_evaluation_stack.append(obj)

	func pop_evaluation_stack() -> Obj:
		if _evaluation_stack.is_empty():
			return null
		return _evaluation_stack.pop_back()

	func pop_evaluation_stack_n(n: int) -> Array:
		if n > _evaluation_stack.size():
			Ink._throw_global("trying to pop too many objects")
			return []
		var out := _evaluation_stack.slice(_evaluation_stack.size() - n)
		_evaluation_stack.resize(_evaluation_stack.size() - n)
		return out

	func peek_evaluation_stack() -> Obj:
		return _evaluation_stack.back() if not _evaluation_stack.is_empty() else null

	func force_end() -> void:
		call_stack().reset()
		_current_flow.current_choices.clear()
		set_current_pointer(Pointer.null_ptr())
		set_previous_pointer(Pointer.null_ptr())
		did_safe_exit = true

	func trim_whitespace_from_function_end() -> void:
		var start := call_stack().current_element().function_start_in_output_stream
		if start == -1:
			start = 0
		var os := output_stream()
		for i in range(os.size() - 1, start - 1, -1):
			var o: Obj = os[i]
			if not (o.kind == K_VAL and o.vtype == VT_STRING):
				continue
			if o.is_newline or o.is_inline_whitespace:
				os.remove_at(i)
				output_stream_dirty()
			else:
				break

	func pop_call_stack(pop_type = null) -> void:
		if call_stack().current_element().type == PP_FUNCTION:
			trim_whitespace_from_function_end()
		call_stack().pop(pop_type)

	func set_chosen_path(p: InkPath, incrementing_turn_index: bool) -> void:
		_current_flow.current_choices.clear()
		var np: Pointer = story.pointer_at_path(p)
		if not np.is_null() and np.index == -1:
			np = Pointer.new(np.container, 0)
		set_current_pointer(np)
		if incrementing_turn_index:
			current_turn_index += 1

	func start_function_evaluation_from_game(func_container: Cont, args: Array) -> void:
		call_stack().push(PP_FUNCTION_EVAL_FROM_GAME, _evaluation_stack.size())
		call_stack().current_element().current_pointer = Pointer.start_of(func_container)
		pass_arguments_to_evaluation_stack(args)

	func pass_arguments_to_evaluation_stack(args) -> void:
		if args == null:
			return
		for a in args:
			if not (a is int or a is float or a is String or a is bool or a is InkList):
				Ink._throw_global("ink arguments when calling EvaluateFunction / ChoosePathStringWithParameters must be number, string, bool or InkList. Argument was " + str(a))
				return
			push_evaluation_stack(Ink.create_value(a))

	func try_exit_function_evaluation_from_game() -> bool:
		if call_stack().current_element().type == PP_FUNCTION_EVAL_FROM_GAME:
			set_current_pointer(Pointer.null_ptr())
			did_safe_exit = true
			return true
		return false

	func complete_function_evaluation_from_game():
		if call_stack().current_element().type != PP_FUNCTION_EVAL_FROM_GAME:
			push_error("Expected external function evaluation to be complete. Stack trace: " + call_stack().call_stack_trace())
			return null
		var original_height := call_stack().current_element().evaluation_stack_height_when_pushed
		var returned: Obj = null
		while _evaluation_stack.size() > original_height:
			var popped := pop_evaluation_stack()
			if returned == null:
				returned = popped
		pop_call_stack(PP_FUNCTION_EVAL_FROM_GAME)
		if returned != null:
			if returned.kind == K_VOID:
				return null
			if returned.kind == K_VAL and returned.vtype == VT_DIVERT:
				return "-> " + returned.value.text()
			return returned.value_object()
		return null

	func add_error(message: String, is_warning: bool) -> void:
		if not is_warning:
			if _current_errors == null:
				_current_errors = []
			_current_errors.append(message)
		else:
			if _current_warnings == null:
				_current_warnings = []
			_current_warnings.append(message)

	func output_stream_dirty() -> void:
		_text_dirty = true
		_tags_dirty = true


# ---------------------------------------------------------------- JSON

# The first thing that went wrong in this step, standing in for a thrown exception
static var _exception := ""
static var _prof := {}
static var _cnt := {}
static func _p(n: String, t0: int) -> void:
	_prof[n] = _prof.get(n, 0) + Time.get_ticks_usec() - t0
	_cnt[n] = _cnt.get(n, 0) + 1


static func _throw_global(msg: String) -> void:
	if _exception == "":
		_exception = msg


static func json_to_obj(token) -> Obj:
	if token is bool:
		return create_value(token)
	if token is int or token is float:
		if token is float and is_nan(token):
			return null
		return create_value(jnum(token))
	if token is String:
		var s: String = token
		if s.length() > 1 and s.ends_with("f") and s.substr(0, s.length() - 1).is_valid_float() and s.contains("."):
			return FloatVal.new(s.substr(0, s.length() - 1).to_float())
		if s.length() > 0 and s[0] == "^":
			return StrVal.new(s.substr(1))
		elif s == "\n":
			return StrVal.new("\n")
		if s == "<>":
			return Glue.new()
		var ci := CMD_NAMES.find(s)
		if ci != -1:
			return Cmd.new(ci)
		if s == "L^":
			s = "^"
		var nat: NativeCall = natives().get(s)
		if nat != null:
			return nat
		if s == "void":
			return Void.new()
	if token is Dictionary:
		var o: Dictionary = token
		if o.has("^->") and o["^->"]:
			return DivertTargetVal.new(InkPath.from_string(str(o["^->"])))
		if o.has("^var") and o["^var"]:
			var vp := VarPtrVal.new(str(o["^var"]))
			if o.has("ci"):
				vp.context_index = jint(o["ci"])
			return vp
		var is_divert := false
		var pushes := false
		var push_type := PP_FUNCTION
		var external := false
		var target = null
		if o.has("->") and o["->"]:
			is_divert = true
			target = o["->"]
		elif o.has("f()") and o["f()"]:
			is_divert = true
			pushes = true
			push_type = PP_FUNCTION
			target = o["f()"]
		elif o.has("->t->") and o["->t->"]:
			is_divert = true
			pushes = true
			push_type = PP_TUNNEL
			target = o["->t->"]
		elif o.has("x()") and o["x()"]:
			is_divert = true
			external = true
			pushes = false
			push_type = PP_FUNCTION
			target = o["x()"]
		if is_divert:
			var d := Divert.new()
			d.pushes_to_stack = pushes
			d.stack_push_type = push_type
			d.is_external = external
			if o.has("var") and o["var"]:
				d.variable_divert_name = str(target)
			else:
				d.set_target_path(InkPath.from_string(str(target)))
			d.is_conditional = bool(o.get("c", false))
			if external and o.has("exArgs") and o["exArgs"]:
				d.external_args = jint(o["exArgs"])
			return d
		if o.has("*") and o["*"]:
			var cp := ChoicePoint.new()
			cp._path_on_choice = InkPath.from_string(str(o["*"]))
			if o.has("flg") and o["flg"]:
				cp.set_flags(jint(o["flg"]))
			return cp
		if o.has("VAR?") and o["VAR?"]:
			return VarRef.new(str(o["VAR?"]))
		elif o.has("CNT?") and o["CNT?"]:
			var vr := VarRef.new()
			vr.path_for_count = InkPath.from_string(str(o["CNT?"]))
			return vr
		var is_var_ass := false
		var is_global := false
		var var_name = null
		if o.has("VAR=") and o["VAR="]:
			is_var_ass = true
			is_global = true
			var_name = o["VAR="]
		elif o.has("temp=") and o["temp="]:
			is_var_ass = true
			var_name = o["temp="]
		if is_var_ass:
			var va := VarAssign.new(str(var_name), not bool(o.get("re", false)))
			va.is_global = is_global
			return va
		if o.has("#"):
			return Tag.new(str(o["#"]))
		if o.has("list"):
			var raw := InkList.new()
			if o.has("origins") and o["origins"]:
				raw.set_initial_origin_names(o["origins"])
			var content: Dictionary = o["list"]
			for k in content:
				raw.add(InkListItem.from_full_name(k), jint(content[k]))
			var lv := ListVal.new()
			lv.value = raw
			return lv
		if o.has("originalChoicePath") and o["originalChoicePath"] != null:
			return json_to_choice(o)
	if token is Array:
		return json_array_to_container(token)
	if token == null:
		return null
	push_error("Failed to convert token to runtime object: " + str(token))
	return null


static func json_array_to_objs(arr: Array, skip_last := false) -> Array:
	var n := arr.size()
	if skip_last:
		n -= 1
	var out: Array = []
	for i in range(n):
		out.append(json_to_obj(arr[i]))
	return out


static func json_array_to_container(arr: Array) -> Cont:
	var c := Cont.new()
	for o in json_array_to_objs(arr, true):
		c.add_content(o)
	var term = arr[arr.size() - 1]
	if term != null and term is Dictionary:
		for k in term:
			if k == "#f":
				c.set_count_flags(jint(term[k]))
			elif k == "#n":
				c.name = str(term[k])
			else:
				var item := json_to_obj(term[k])
				if item != null and item.kind == K_CONT:
					item.name = k
					c.add_to_named_content_only(item)
	return c


static func json_to_choice(j: Dictionary) -> Choice:
	var c := Choice.new()
	c.text_value = str(j.get("text", ""))
	c.index = jint(j.get("index", 0))
	c.source_path = str(j.get("originalChoicePath", ""))
	c.original_thread_index = jint(j.get("originalThreadIndex", 0))
	c.target_path = InkPath.from_string(str(j.get("targetPath", "")))
	c.tags = j.get("tags") if j.get("tags") else null
	# The browser build's inkjs is patched to keep this across a save (lib/ink.js); so is this.
	c.is_invisible_default = bool(j.get("isInvisibleDefault", false))
	return c


static func choice_to_json(c: Choice) -> Dictionary:
	var out := {"text": c.text_value, "index": c.index, "originalChoicePath": c.source_path, "originalThreadIndex": c.original_thread_index, "targetPath": c.path_string_on_choice(), "isInvisibleDefault": c.is_invisible_default}
	if c.tags != null and c.tags.size() > 0:
		out["tags"] = c.tags.duplicate()
	return out


static func json_dict_to_objs(j: Dictionary) -> Dictionary:
	var out := {}
	for k in j:
		out[k] = json_to_obj(j[k])
	return out


static func json_objs_to_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = obj_to_json(d[k])
	return out


static func json_objs_to_array(a: Array) -> Array:
	var out: Array = []
	for o in a:
		out.append(obj_to_json(o))
	return out


# the runtime objects a state holds (values, text, commands, tags, glue, choices) as JSON
static func obj_to_json(o: Obj):
	match o.kind:
		K_VAL:
			match o.vtype:
				VT_BOOL:
					return o.value
				VT_INT:
					return o.value
				VT_FLOAT:
					return o.value
				VT_STRING:
					if o.is_newline:
						return "\n"
					return "^" + o.value
				VT_LIST:
					var raw: InkList = o.value
					var lst := {}
					for k in raw.items:
						var it := InkListItem.from_key(k)
						lst[(it.origin_name if it.origin_name != null else "?") + "." + str(it.item_name)] = raw.items[k]
					var out := {"list": lst}
					var names = raw.origin_names()
					if raw.count() == 0 and names != null and names.size() > 0:
						out["origins"] = names.duplicate()
					return out
				VT_DIVERT:
					return {"^->": o.value.components_string()}
				VT_VAR_PTR:
					return {"^var": o.value, "ci": o.context_index}
		K_GLUE:
			return "<>"
		K_CMD:
			return CMD_NAMES[o.type]
		K_NATIVE:
			return "L^" if o.name == "^" else o.name
		K_VOID:
			return "void"
		K_TAG:
			return {"#": o.text_value}
		K_CHOICE:
			return choice_to_json(o)
		K_DIVERT:
			var key := "->"
			if o.is_external:
				key = "x()"
			elif o.pushes_to_stack:
				key = "f()" if o.stack_push_type == PP_FUNCTION else "->t->"
			var d := {key: o.variable_divert_name if o.has_variable_target() else o.target_path_string()}
			if o.has_variable_target():
				d["var"] = true
			if o.is_conditional:
				d["c"] = true
			if o.external_args > 0:
				d["exArgs"] = o.external_args
			return d
		K_VAR_REF:
			if o.path_for_count != null:
				return {"CNT?": o.path_string_for_count()}
			return {"VAR?": o.name}
		K_VAR_ASSIGN:
			var va := {("VAR=" if o.is_global else "temp="): o.variable_name}
			if not o.is_new_declaration:
				va["re"] = true
			return va
	push_error("Failed to convert runtime object to Json token: " + o.text())
	return null


static func json_to_list_definitions(j: Dictionary) -> ListDefs:
	var defs: Array = []
	for list_name in j:
		var its := {}
		var src: Dictionary = j[list_name]
		for item_name in src:
			its[item_name] = jint(src[item_name])
		defs.append(ListDef.new(list_name, its))
	return ListDefs.new(defs)


# One parse of a story's JSON, shared by every Story made from it: the content is never changed
# while it plays (only its paths are cached), so there's no need to build it twice.
static var _parsed: Dictionary = {}


static func parse_story(json: Dictionary) -> Array:
	var ident = json.get("__ink_parsed_id")
	if ident != null and _parsed.has(ident):
		return _parsed[ident]
	var root_token = json.get("root")
	var root := json_array_to_container(root_token)
	var list_defs := json_to_list_definitions(json["listDefs"]) if json.has("listDefs") and json["listDefs"] is Dictionary else ListDefs.new([])
	var id := _parsed.size() + 1
	json["__ink_parsed_id"] = id
	_parsed[id] = [root, list_defs]
	return [root, list_defs]


# ---------------------------------------------------------------- the story

class Story extends RefCounted:
	var _main_content_container: Cont
	var list_definitions: ListDefs
	var _state: StoryState
	var allow_external_function_fallbacks := false
	var on_error: Callable = Callable()
	var _externals: Dictionary = {}
	var _has_validated_externals := false
	var _temporary_evaluation_container: Cont = null
	var _state_snapshot_at_last_newline: StoryState = null
	var _saw_lookahead_unsafe_function_after_newline := false
	var _recursive_continue_count := 0
	var _prev_containers: Array = []

	# json: the compiled story, parsed (a Dictionary with inkVersion, root and listDefs)
	func _init(json: Dictionary) -> void:
		var v := Ink.jint(json.get("inkVersion", 0))
		if v > INK_VERSION_CURRENT:
			push_error("Version of ink used to build story was newer than the current version of the engine")
		elif v < INK_VERSION_MIN:
			push_error("Version of ink used to build story is too old to be loaded by this version of the engine")
		var parsed := Ink.parse_story(json)
		_main_content_container = parsed[0]
		list_definitions = parsed[1]
		reset_state()

	# ---- public ----

	func state() -> StoryState:
		return _state

	func variables_state() -> VariablesState:
		return _state.variables_state

	func get_var(n: String):
		return _state.variables_state.get_value(n)

	func set_var(n: String, value) -> bool:
		return _state.variables_state.set_value(n, value)

	func can_continue() -> bool:
		return _state.can_continue()

	func current_text() -> String:
		return _state.current_text()

	func current_tags() -> Array:
		return _state.current_tags()

	func current_errors():
		return _state.current_errors()

	func current_warnings():
		return _state.current_warnings()

	func has_error() -> bool:
		return _state.has_error()

	func current_choices() -> Array:
		var out: Array = []
		for c in _state.current_choices():
			if not c.is_invisible_default:
				c.index = out.size()
				out.append(c)
		return out

	func main_content_container() -> Cont:
		return _temporary_evaluation_container if _temporary_evaluation_container != null else _main_content_container

	func root_content_container() -> Cont:
		return _main_content_container

	func reset_state() -> void:
		_state = StoryState.new(self)
		reset_globals()

	func reset_errors() -> void:
		_state.reset_errors()

	func reset_callstack() -> void:
		_state.force_end()

	func reset_globals() -> void:
		if _main_content_container.named_content.has("global decl"):
			var original := _state.current_pointer()
			choose_path(InkPath.from_string("global decl"), false)
			continue_internal()
			_state.set_current_pointer(original)
		_state.variables_state.snapshot_default_globals()

	func switch_flow(flow_name: String) -> void:
		_state.switch_flow_internal(flow_name)

	func remove_flow(flow_name: String) -> void:
		_state.remove_flow_internal(flow_name)

	func switch_to_default_flow() -> void:
		_state.switch_to_default_flow_internal()

	# story.Continue()
	func continue_story() -> String:
		if not _has_validated_externals:
			validate_external_bindings()
		continue_internal()
		return _state.current_text()

	func continue_maximally() -> String:
		var sb := ""
		while can_continue():
			sb += continue_story()
		return sb

	func content_at_path(p: InkPath) -> SearchResult:
		return main_content_container().content_at_path(p)

	func knot_container_with_name(n: String) -> Cont:
		var c = main_content_container().named_content.get(n)
		if c != null and c.kind == K_CONT:
			return c
		return null

	func pointer_at_path(p: InkPath) -> Pointer:
		if p.length() == 0:
			return Pointer.null_ptr()
		var ptr: Pointer
		var use_len := p.length()
		var result: SearchResult
		if p.last_component().is_index():
			use_len = p.length() - 1
			result = main_content_container().content_at_path(p, 0, use_len)
			ptr = Pointer.new(result.container(), p.last_component().index)
		else:
			result = main_content_container().content_at_path(p)
			ptr = Pointer.new(result.container(), -1)
		if result.obj == null or (result.obj == main_content_container() and use_len > 0):
			error("Failed to find content at path '" + p.text() + "', and no approximation of it was possible.")
		elif result.approximate:
			warning("Failed to find content at path '" + p.text() + "', so it was approximated to: '" + result.obj.path().text() + "'.")
		return ptr

	# ---- continuing ----

	func continue_internal() -> void:
		_recursive_continue_count += 1
		if not can_continue():
			push_error("Can't continue - should check canContinue before calling Continue")
			_recursive_continue_count -= 1
			return
		_state.did_safe_exit = false
		_state.reset_output()
		var ends_in_newline := false
		_saw_lookahead_unsafe_function_after_newline = false
		while true:
			Ink._exception = ""
			ends_in_newline = continue_single_step()
			if Ink._exception != "":
				var msg := Ink._exception
				Ink._exception = ""
				add_error(msg)
				break
			if ends_in_newline:
				break
			if not can_continue():
				break
		if ends_in_newline or not can_continue():
			if _state_snapshot_at_last_newline != null:
				restore_state_snapshot()
			if not can_continue():
				if _state.call_stack().can_pop_thread():
					add_error("Thread available to pop, threads should always be flat by the end of evaluation?")
				if _state.generated_choices().size() == 0 and not _state.did_safe_exit and _temporary_evaluation_container == null:
					if _state.call_stack().can_pop_type(PP_TUNNEL):
						add_error("unexpectedly reached end of content. Do you need a '->->' to return from a tunnel?")
					elif _state.call_stack().can_pop_type(PP_FUNCTION):
						add_error("unexpectedly reached end of content. Do you need a '~ return'?")
					elif not _state.call_stack().can_pop():
						add_error("ran out of content. Do you need a '-> DONE' or '-> END'?")
					else:
						add_error("unexpectedly reached end of content for unknown reason. Please debug compiler!")
			_state.did_safe_exit = false
			_saw_lookahead_unsafe_function_after_newline = false
		_recursive_continue_count -= 1
		if _state.has_error() or _state.has_warning():
			if on_error.is_valid():
				if _state.has_error():
					for e in _state.current_errors():
						on_error.call(e, ERROR_ERROR)
				if _state.has_warning():
					for w in _state.current_warnings():
						on_error.call(w, ERROR_WARNING)
				reset_errors()
			else:
				var first = _state.current_errors()[0] if _state.has_error() else _state.current_warnings()[0]
				push_error("Ink had errors or warnings. The first was: " + str(first))

	func continue_single_step() -> bool:
		step()
		if not can_continue() and not _state.call_stack().element_is_evaluate_from_game():
			try_follow_default_invisible_choice()
		if not _state.in_string_evaluation():
			if _state_snapshot_at_last_newline != null:
				var change := calculate_newline_output_state_change(
					_state_snapshot_at_last_newline.current_text(), _state.current_text(),
					_state_snapshot_at_last_newline.current_tags().size(), _state.current_tags().size())
				if change == 1 or _saw_lookahead_unsafe_function_after_newline:
					restore_state_snapshot()
					return true
				elif change == 2:
					discard_snapshot()
			if _state.output_stream_ends_in_newline():
				if can_continue():
					if _state_snapshot_at_last_newline == null:
						state_snapshot()
				else:
					discard_snapshot()
		return false

	# 0: no change; 1: extended beyond the newline; 2: the newline was removed
	func calculate_newline_output_state_change(prev_text: String, curr_text: String, prev_tags: int, curr_tags: int) -> int:
		var still := curr_text.length() >= prev_text.length() and prev_text.length() > 0 and curr_text[prev_text.length() - 1] == "\n"
		if prev_tags == curr_tags and prev_text.length() == curr_text.length() and still:
			return 0
		if not still:
			return 2
		if curr_tags > prev_tags:
			return 1
		for i in range(prev_text.length(), curr_text.length()):
			var c: String = curr_text[i]
			if c != " " and c != "\t":
				return 1
		return 0

	func state_snapshot() -> void:
		_state_snapshot_at_last_newline = _state
		_state = _state.copy_and_start_patching(false)

	func restore_state_snapshot() -> void:
		_state_snapshot_at_last_newline.restore_after_patch()
		_state = _state_snapshot_at_last_newline
		_state_snapshot_at_last_newline = null
		_state.apply_any_patch()

	func discard_snapshot() -> void:
		_state.apply_any_patch()
		_state_snapshot_at_last_newline = null

	func step() -> void:
		var should_add_to_stream := true
		var pointer := _state.current_pointer()
		if pointer.is_null():
			return
		var r: Obj = pointer.resolve()
		var container_to_enter: Cont = r if (r != null and r.kind == K_CONT) else null
		while container_to_enter != null:
			visit_container(container_to_enter, true)
			if container_to_enter.content.size() == 0:
				break
			pointer = Pointer.start_of(container_to_enter)
			r = pointer.resolve()
			container_to_enter = r if (r != null and r.kind == K_CONT) else null
		_state.set_current_pointer(pointer)
		var current: Obj = pointer.resolve()
		var is_logic := perform_logic_and_flow_control(current)
		if _state.current_pointer().is_null():
			return
		if is_logic:
			should_add_to_stream = false
		if current != null and current.kind == K_CHOICE_POINT:
			var choice := process_choice(current)
			if choice != null:
				_state.generated_choices().append(choice)
			current = null
			should_add_to_stream = false
		if current != null and current.kind == K_CONT:
			should_add_to_stream = false
		if should_add_to_stream and current != null:
			if current.kind == K_VAL and current.vtype == VT_VAR_PTR and current.context_index == -1:
				var ci := _state.call_stack().context_for_variable_named(current.value)
				current = VarPtrVal.new(current.value, ci)
			if _state.in_expression_evaluation():
				_state.push_evaluation_stack(current)
			else:
				_state.push_to_output_stream(current)
		next_content()
		if current != null and current.kind == K_CMD and current.type == C_START_THREAD:
			_state.call_stack().push_thread()

	func visit_container(c: Cont, at_start: bool) -> void:
		if not c.counting_at_start_only or at_start:
			if c.visits_should_be_counted:
				_state.increment_visit_count_for_container(c)
			if c.turn_index_should_be_counted:
				_state.record_turn_index_visit_to_container(c)

	func visit_changed_containers_due_to_divert() -> void:
		var previous := _state.previous_pointer()
		var pointer := _state.current_pointer()
		if pointer.is_null() or pointer.index == -1:
			return
		_prev_containers.clear()
		if not previous.is_null():
			var rp: Obj = previous.resolve()
			var anc: Cont = rp if (rp != null and rp.kind == K_CONT) else previous.container
			while anc != null:
				_prev_containers.append(anc)
				anc = anc.parent
		var child: Obj = pointer.resolve()
		if child == null:
			return
		var cur_anc: Cont = child.parent
		var all_at_start := true
		while cur_anc != null and (not _prev_containers.has(cur_anc) or cur_anc.counting_at_start_only):
			var entering_at_start: bool = cur_anc.content.size() > 0 and child == cur_anc.content[0] and all_at_start
			if not entering_at_start:
				all_at_start = false
			visit_container(cur_anc, entering_at_start)
			child = cur_anc
			cur_anc = cur_anc.parent

	func pop_choice_string_and_tags(tags: Array) -> String:
		var s: Obj = _state.pop_evaluation_stack()
		while _state.evaluation_stack().size() > 0 and _state.peek_evaluation_stack().kind == K_TAG:
			var t: Tag = _state.pop_evaluation_stack()
			tags.append(t.text_value)
		if s == null or not (s.kind == K_VAL and s.vtype == VT_STRING):
			Ink._throw_global("expected the choice's text on the evaluation stack")
			return ""
		return s.value

	func process_choice(cp: ChoicePoint) -> Choice:
		var show := true
		if cp.has_condition:
			var cond := _state.pop_evaluation_stack()
			if not is_truthy(cond):
				show = false
		var start_text := ""
		var choice_only_text := ""
		var tags: Array = []
		if cp.has_choice_only_content:
			choice_only_text = pop_choice_string_and_tags(tags)
		if cp.has_start_content:
			start_text = pop_choice_string_and_tags(tags)
		if cp.once_only:
			if _state.visit_count_for_container(cp.choice_target()) > 0:
				show = false
		if not show:
			return null
		var c := Choice.new()
		c.target_path = cp.path_on_choice()
		c.source_path = cp.path().text()
		c.is_invisible_default = cp.is_invisible_default
		c.thread_at_generation = _state.call_stack().fork_thread()
		tags.reverse()
		c.tags = tags
		c.text_value = (start_text + choice_only_text).strip_edges()
		return c

	func is_truthy(obj: Obj) -> bool:
		if obj != null and obj.kind == K_VAL:
			if obj.vtype == VT_DIVERT:
				error("Shouldn't use a divert target (to " + obj.value.text() + ") as a conditional value. Did you intend a function call 'likeThis()' or a read count check 'likeThis'? (no arrows)")
				return false
			return obj.is_truthy()
		return false

	func perform_logic_and_flow_control(obj: Obj) -> bool:
		if obj == null:
			return false
		match obj.kind:
			K_DIVERT:
				var d: Divert = obj
				if d.is_conditional:
					var cond := _state.pop_evaluation_stack()
					if not is_truthy(cond):
						return true
				if d.has_variable_target():
					var var_name: String = d.variable_divert_name
					var contents: Obj = _state.variables_state.get_variable_with_name(var_name)
					if contents == null:
						error("Tried to divert using a target from a variable that could not be found (" + var_name + ")")
						return true
					elif not (contents.kind == K_VAL and contents.vtype == VT_DIVERT):
						var msg := "Tried to divert to a target from a variable, but the variable (" + var_name + ") didn't contain a divert target, it "
						if contents.kind == K_VAL and contents.vtype == VT_INT and contents.value == 0:
							msg += "was empty/null (the value 0)."
						else:
							msg += "contained '" + contents.text() + "'."
						error(msg)
						return true
					_state.diverted_pointer = pointer_at_path(contents.value)
				elif d.is_external:
					call_external_function(d.target_path_string(), d.external_args)
					return true
				else:
					_state.diverted_pointer = d.target_pointer()
				if d.pushes_to_stack:
					_state.call_stack().push(d.stack_push_type, 0, _state.output_stream().size())
				if _state.diverted_pointer.is_null() and not d.is_external:
					error("Divert resolution failed: " + d.text())
				return true
			K_CMD:
				_perform_command(obj)
				return true
			K_VAR_ASSIGN:
				var assigned := _state.pop_evaluation_stack()
				_state.variables_state.assign(obj, assigned)
				return true
			K_VAR_REF:
				var vr: VarRef = obj
				var found: Obj = null
				if vr.path_for_count != null:
					var c := vr.container_for_count()
					found = IntVal.new(_state.visit_count_for_container(c))
				else:
					found = _state.variables_state.get_variable_with_name(vr.name)
					if found == null:
						warning("Variable not found: '" + str(vr.name) + "'. Using default value of 0 (false). This can happen with temporary variables if the declaration hasn't yet been hit. Globals are always given a default value on load if a value doesn't exist in the save state.")
						found = IntVal.new(0)
				_state.push_evaluation_stack(found)
				return true
			K_NATIVE:
				var f: NativeCall = obj
				var params := _state.pop_evaluation_stack_n(f.number_of_parameters)
				var result := call_native(f, params)
				_state.push_evaluation_stack(result)
				return true
		return false

	func _perform_command(cmd: Cmd) -> void:
		match cmd.type:
			C_EVAL_START:
				_state.set_in_expression_evaluation(true)
			C_EVAL_END:
				_state.set_in_expression_evaluation(false)
			C_EVAL_OUTPUT:
				if _state.evaluation_stack().size() > 0:
					var output := _state.pop_evaluation_stack()
					if output.kind != K_VOID:
						_state.push_to_output_stream(StrVal.new(output.text()))
			C_NOOP:
				pass
			C_DUPLICATE:
				_state.push_evaluation_stack(_state.peek_evaluation_stack())
			C_POP_EVALUATED:
				_state.pop_evaluation_stack()
			C_POP_FUNCTION, C_POP_TUNNEL:
				var pop_type := PP_FUNCTION if cmd.type == C_POP_FUNCTION else PP_TUNNEL
				var override: Obj = null
				if pop_type == PP_TUNNEL:
					var popped := _state.pop_evaluation_stack()
					if popped != null and popped.kind == K_VAL and popped.vtype == VT_DIVERT:
						override = popped
				if _state.try_exit_function_evaluation_from_game():
					pass
				elif _state.call_stack().current_element().type != pop_type or not _state.call_stack().can_pop():
					var names := {PP_FUNCTION: "function return statement (~ return)", PP_TUNNEL: "tunnel onwards statement (->->)"}
					var expected = names.get(_state.call_stack().current_element().type, "?")
					if not _state.call_stack().can_pop():
						expected = "end of flow (-> END or choice)"
					error("Found " + str(names.get(pop_type)) + ", when expected " + str(expected))
				else:
					_state.pop_call_stack()
					if override != null:
						_state.diverted_pointer = pointer_at_path(override.value)
			C_BEGIN_STRING:
				_state.push_to_output_stream(cmd)
				_state.set_in_expression_evaluation(false)
			C_BEGIN_TAG:
				_state.push_to_output_stream(cmd)
			C_END_TAG:
				if _state.in_string_evaluation():
					var stack_for_tag: Array = []
					var consumed := 0
					var os := _state.output_stream()
					for i in range(os.size() - 1, -1, -1):
						var o: Obj = os[i]
						consumed += 1
						if o.kind == K_CMD:
							if o.type == C_BEGIN_TAG:
								break
							else:
								error("Unexpected ControlCommand while extracting tag from choice")
								break
						if o.kind == K_VAL and o.vtype == VT_STRING:
							stack_for_tag.append(o)
					_state.pop_from_output_stream(consumed)
					var sb := ""
					stack_for_tag.reverse()
					for s in stack_for_tag:
						sb += s.text()
					_state.push_evaluation_stack(Tag.new(_state.clean_output_whitespace(sb)))
				else:
					_state.push_to_output_stream(cmd)
			C_END_STRING:
				var stack_for_string: Array = []
				var retain: Array = []
				var consumed2 := 0
				var os2 := _state.output_stream()
				for i in range(os2.size() - 1, -1, -1):
					var o: Obj = os2[i]
					consumed2 += 1
					if o.kind == K_CMD and o.type == C_BEGIN_STRING:
						break
					if o.kind == K_TAG:
						retain.append(o)
					if o.kind == K_VAL and o.vtype == VT_STRING:
						stack_for_string.append(o)
				_state.pop_from_output_stream(consumed2)
				for t in retain:
					_state.push_to_output_stream(t)
				stack_for_string.reverse()
				var sb2 := ""
				for s in stack_for_string:
					sb2 += s.text()
				_state.set_in_expression_evaluation(true)
				_state.push_evaluation_stack(StrVal.new(sb2))
			C_CHOICE_COUNT:
				_state.push_evaluation_stack(IntVal.new(_state.generated_choices().size()))
			C_TURNS:
				_state.push_evaluation_stack(IntVal.new(_state.current_turn_index + 1))
			C_TURNS_SINCE, C_READ_COUNT:
				var target := _state.pop_evaluation_stack()
				if target == null or not (target.kind == K_VAL and target.vtype == VT_DIVERT):
					var note := ""
					if target != null and target.kind == K_VAL and target.vtype == VT_INT:
						note = ". Did you accidentally pass a read count ('knot_name') instead of a target ('-> knot_name')?"
					error("TURNS_SINCE / READ_COUNT expected a divert target (knot, stitch, label name), but saw " + (target.text() if target != null else "null") + note)
					return
				var res := content_at_path(target.value)
				var co: Obj = res.correct_obj()
				var container: Cont = co if (co != null and co.kind == K_CONT) else null
				var either := 0
				if container != null:
					if cmd.type == C_TURNS_SINCE:
						either = _state.turns_since_for_container(container)
					else:
						either = _state.visit_count_for_container(container)
				else:
					either = -1 if cmd.type == C_TURNS_SINCE else 0
					warning("Failed to find container for " + cmd.text() + " lookup at " + target.value.text())
				_state.push_evaluation_stack(IntVal.new(either))
			C_RANDOM:
				var max_i := _state.pop_evaluation_stack()
				var min_i := _state.pop_evaluation_stack()
				if min_i == null or not (min_i.kind == K_VAL and min_i.vtype == VT_INT):
					error("Invalid value for minimum parameter of RANDOM(min, max)")
					return
				if max_i == null or not (max_i.kind == K_VAL and max_i.vtype == VT_INT):
					error("Invalid value for maximum parameter of RANDOM(min, max)")
					return
				var random_range: int = max_i.value - min_i.value + 1
				if random_range <= 0:
					error("RANDOM was called with minimum as " + str(min_i.value) + " and maximum as " + str(max_i.value) + ". The maximum must be larger")
				var prng := PRNG.new(_state.story_seed + _state.previous_random)
				var next_random := prng.next()
				var chosen: int = (next_random % random_range) + min_i.value
				_state.push_evaluation_stack(IntVal.new(chosen))
				_state.previous_random = next_random
			C_SEED_RANDOM:
				var sd := _state.pop_evaluation_stack()
				if sd == null or not (sd.kind == K_VAL and sd.vtype == VT_INT):
					error("Invalid value passed to SEED_RANDOM")
					return
				_state.story_seed = sd.value
				_state.previous_random = 0
				_state.push_evaluation_stack(Void.new())
			C_VISIT_INDEX:
				var count := _state.visit_count_for_container(_state.current_pointer().container) - 1
				_state.push_evaluation_stack(IntVal.new(count))
			C_SEQ_SHUFFLE_INDEX:
				_state.push_evaluation_stack(IntVal.new(next_sequence_shuffle_index()))
			C_START_THREAD:
				pass
			C_DONE:
				if _state.call_stack().can_pop_thread():
					_state.call_stack().pop_thread()
				else:
					_state.did_safe_exit = true
					_state.set_current_pointer(Pointer.null_ptr())
			C_END:
				_state.force_end()
			C_LIST_FROM_INT:
				var int_val := _state.pop_evaluation_stack()
				var list_name_val := _state.pop_evaluation_stack()
				if int_val == null or not (int_val.kind == K_VAL and int_val.vtype == VT_INT):
					Ink._throw_global("Passed non-integer when creating a list element from a numerical value.")
					return
				var generated: ListVal = null
				var def: ListDef = list_definitions.try_get(list_name_val.value)
				if def != null:
					var item := def.try_get_item_with_value(int_val.value)
					if item != null:
						generated = ListVal.single(item, int_val.value)
				else:
					Ink._throw_global("Failed to find LIST called " + str(list_name_val.value))
					return
				if generated == null:
					generated = ListVal.new()
				_state.push_evaluation_stack(generated)
			C_LIST_RANGE:
				var mx := _state.pop_evaluation_stack()
				var mn := _state.pop_evaluation_stack()
				var target_list := _state.pop_evaluation_stack()
				if target_list == null or mn == null or mx == null or not (target_list.kind == K_VAL and target_list.vtype == VT_LIST):
					Ink._throw_global("Expected list, minimum and maximum for LIST_RANGE")
					return
				var result: InkList = target_list.value.list_with_sub_range(mn.value_object(), mx.value_object())
				var lv := ListVal.new()
				lv.value = result
				_state.push_evaluation_stack(lv)
			C_LIST_RANDOM:
				var list_val := _state.pop_evaluation_stack()
				if list_val == null:
					Ink._throw_global("Expected list for LIST_RANDOM")
					return
				var lst: InkList = list_val.value
				var new_list: InkList = null
				if lst.count() == 0:
					new_list = InkList.new()
				else:
					var prng2 := PRNG.new(_state.story_seed + _state.previous_random)
					var next_random2 := prng2.next()
					var item_index := next_random2 % lst.count()
					var k = lst.items.keys()[item_index]
					var rand_item := InkListItem.from_key(k)
					new_list = InkList.from_origin(rand_item.origin_name, self)
					new_list.add(rand_item, lst.items[k])
					_state.previous_random = next_random2
				var lv2 := ListVal.new()
				lv2.value = InkList.copy_of(new_list)
				_state.push_evaluation_stack(lv2)
			_:
				error("unhandled ControlCommand: " + cmd.text())

	# ---- native functions ----

	func call_native(f: NativeCall, params: Array) -> Obj:
		# The common cases without the general machinery below, with the same results: whole
		# numbers, true and false (which inkjs turns into whole numbers first), and has / hasnt.
		var n := params.size()
		if n == 2 and f.number_of_parameters == 2:
			var a: Obj = params[0]
			var b: Obj = params[1]
			if a != null and b != null and a.kind == K_VAL and b.kind == K_VAL:
				var at: int = a.vtype
				var bt: int = b.vtype
				if (at == VT_INT or at == VT_BOOL) and (bt == VT_INT or bt == VT_BOOL):
					var x: int = int(a.value)
					var y: int = int(b.value)
					match f.name:
						"+": return IntVal.new(x + y)
						"-": return IntVal.new(x - y)
						"*": return IntVal.new(x * y)
						"==": return BoolVal.new(x == y)
						"!=": return BoolVal.new(x != y)
						">": return BoolVal.new(x > y)
						"<": return BoolVal.new(x < y)
						">=": return BoolVal.new(x >= y)
						"<=": return BoolVal.new(x <= y)
						"&&": return BoolVal.new(x != 0 and y != 0)
						"||": return BoolVal.new(x != 0 or y != 0)
						"MAX": return IntVal.new(x if x >= y else y)
						"MIN": return IntVal.new(x if x <= y else y)
				elif at == VT_LIST and bt == VT_LIST:
					match f.name:
						"?": return BoolVal.new(a.value.contains(b.value))
						"!?": return BoolVal.new(not a.value.contains(b.value))
		elif n == 1 and f.number_of_parameters == 1 and f.name == "!":
			var a: Obj = params[0]
			if a != null and a.kind == K_VAL and (a.vtype == VT_INT or a.vtype == VT_BOOL):
				return BoolVal.new(int(a.value) == 0)
		if f.number_of_parameters != params.size():
			Ink._throw_global("Unexpected number of parameters")
			return null
		var has_list := false
		for p in params:
			if p == null:
				Ink._throw_global("Attempting to perform " + f.name + " on a null value.")
				return null
			if p.kind == K_VOID:
				Ink._throw_global("Attempting to perform " + f.name + ' on a void value. Did you forget to "return" a value from a function you called here?')
				return null
			if p.kind == K_VAL and p.vtype == VT_LIST:
				has_list = true
		if params.size() == 2 and has_list:
			return _call_binary_list_operation(f, params)
		var coerced := _coerce_values_to_single_type(params)
		if coerced.is_empty():
			return null
		return _call_type(f, coerced)

	func _call_type(f: NativeCall, params: Array) -> Obj:
		var p1: Val = params[0]
		var vt := p1.vtype
		var op = f.ops.get(vt)
		if op == null:
			Ink._throw_global("Cannot perform operation " + f.name + " on " + str(VT_NAMES.get(vt, vt)))
			return null
		if params.size() == 2:
			var p2: Val = params[1]
			return Ink.create_value(op.call(p1.value, p2.value))
		var r = op.call(p1.value)
		if f.name == "INT":
			return Ink.create_value(r, VT_INT)
		elif f.name == "FLOAT":
			return Ink.create_value(r, VT_FLOAT)
		return Ink.create_value(r, p1.vtype)

	func _call_binary_list_operation(f: NativeCall, params: Array) -> Obj:
		if (f.name == "+" or f.name == "-") and params[0].vtype == VT_LIST and params[1].vtype == VT_INT:
			return _call_list_increment_operation(f, params)
		var v1: Val = params[0]
		var v2: Val = params[1]
		if (f.name == "&&" or f.name == "||") and (v1.vtype != VT_LIST or v2.vtype != VT_LIST):
			var op = f.ops.get(VT_INT)
			return BoolVal.new(op.call(1 if v1.is_truthy() else 0, 1 if v2.is_truthy() else 0))
		if v1.vtype == VT_LIST and v2.vtype == VT_LIST:
			return _call_type(f, [v1, v2])
		Ink._throw_global("Can not call use " + f.name + " operation on " + str(VT_NAMES.get(v1.vtype)) + " and " + str(VT_NAMES.get(v2.vtype)))
		return null

	func _call_list_increment_operation(f: NativeCall, params: Array) -> Obj:
		var list_val: ListVal = params[0]
		var int_val: IntVal = params[1]
		var result := InkList.new()
		var int_op = f.ops.get(VT_INT)
		for k in list_val.value.items:
			var item := InkListItem.from_key(k)
			var target_int = int_op.call(list_val.value.items[k], int_val.value)
			var item_origin: ListDef = null
			if list_val.value.origins == null:
				Ink._throw_global("list has no origins")
				return null
			for o in list_val.value.origins:
				if o.name == item.origin_name:
					item_origin = o
					break
			if item_origin != null:
				var inc := item_origin.try_get_item_with_value(target_int)
				if inc != null:
					result.add(inc, target_int)
		var lv := ListVal.new()
		lv.value = InkList.copy_of(result)
		return lv

	func _coerce_values_to_single_type(params: Array) -> Array:
		var vt := VT_INT
		var special_case_list: ListVal = null
		for p in params:
			if p.vtype > vt:
				vt = p.vtype
			if p.vtype == VT_LIST:
				special_case_list = p
		var out: Array = []
		if vt == VT_LIST:
			for p in params:
				if p.vtype == VT_LIST:
					out.append(p)
				elif p.vtype == VT_INT:
					var iv: int = int(p.value)
					var lst: ListDef = special_case_list.value.origin_of_max_item()
					if lst == null:
						Ink._throw_global("no list to find an item in")
						return []
					var item := lst.try_get_item_with_value(iv)
					if item != null:
						out.append(ListVal.single(item, iv))
					else:
						Ink._throw_global("Could not find List item with the value " + str(iv) + " in " + lst.name)
						return []
				else:
					Ink._throw_global("Cannot mix Lists and " + str(VT_NAMES.get(p.vtype)) + " values in this operation")
					return []
		else:
			for p in params:
				out.append(p.cast(vt))
		return out

	# ---- choosing ----

	func choose_path_string(path: String, reset_callstack := true, args: Array = []) -> void:
		if reset_callstack:
			reset_callstack()
		elif _state.call_stack().current_element().type == PP_FUNCTION:
			push_error("Story was running a function when you called ChoosePathString(" + path + ")")
			return
		_state.pass_arguments_to_evaluation_stack(args)
		choose_path(InkPath.from_string(path))

	func choose_path(p: InkPath, incrementing_turn_index := true) -> void:
		_state.set_chosen_path(p, incrementing_turn_index)
		visit_changed_containers_due_to_divert()

	func choose_choice_index(i: int) -> void:
		var choices := current_choices()
		if i < 0 or i >= choices.size():
			push_error("choice out of range")
			return
		var c: Choice = choices[i]
		_state.call_stack().set_current_thread(c.thread_at_generation)
		choose_path(c.target_path)

	func has_function(n: String) -> bool:
		return knot_container_with_name(n) != null

	# EvaluateFunction(name, args, true): {returned, output}; with return_text_output false, the value
	func evaluate_function(n: String, args: Array = [], return_text_output := false):
		if n.strip_edges() == "":
			push_error("Function is empty or white space.")
			return null
		var fc := knot_container_with_name(n)
		if fc == null:
			push_error("Function doesn't exist: '" + n + "'")
			return null
		var before: Array = _state.output_stream().duplicate()
		_state.reset_output()
		_state.start_function_evaluation_from_game(fc, args)
		var sb := ""
		while can_continue():
			sb += continue_story()
		_state.reset_output(before)
		var result = _state.complete_function_evaluation_from_game()
		if return_text_output:
			return {"returned": result, "output": sb}
		return result

	# ---- externals ----

	func call_external_function(func_name, n_args: int) -> void:
		if func_name == null:
			Ink._throw_global("external function name is null")
			return
		var def = _externals.get(func_name)
		var found: bool = def != null
		if found and not def.safe and _state.in_string_evaluation():
			error("External function " + func_name + " could not be called because 1) it wasn't marked as lookaheadSafe when BindExternalFunction was called and 2) the story is in the middle of string generation, either because choice text is being generated, or because you have ink like \"hello {func()}\". You can work around this by generating the result of your function into a temporary variable before the string or choice gets generated: ~ temp x = " + func_name + "()")
			return
		if found and not def.safe and _state_snapshot_at_last_newline != null:
			_saw_lookahead_unsafe_function_after_newline = true
			return
		if not found:
			if allow_external_function_fallbacks:
				var fallback := knot_container_with_name(func_name)
				if fallback == null:
					Ink._throw_global("Trying to call EXTERNAL function '" + func_name + "' which has not been bound, and fallback ink function could not be found.")
					return
				_state.call_stack().push(PP_FUNCTION, 0, _state.output_stream().size())
				_state.diverted_pointer = Pointer.start_of(fallback)
				return
			Ink._throw_global("Trying to call EXTERNAL function '" + func_name + "' which has not been bound (and ink fallbacks disabled).")
			return
		var args: Array = []
		for i in range(n_args):
			var popped := _state.pop_evaluation_stack()
			args.append(popped.value_object() if popped != null and popped.kind == K_VAL else null)
		args.reverse()
		var result = def.fn.callv(args)
		var ret: Obj
		if result != null:
			ret = Ink.create_value(result)
			if ret == null:
				Ink._throw_global("Could not create ink value from returned object of type " + type_string(typeof(result)))
				return
		else:
			ret = Void.new()
		_state.push_evaluation_stack(ret)

	# fn is called with the arguments the Ink passes; lookahead_safe as in inkjs (default false)
	func bind_external_function(n: String, fn: Callable, lookahead_safe := false) -> void:
		if _externals.has(n):
			push_error("Function '" + n + "' has already been bound.")
			return
		_externals[n] = {"fn": fn, "safe": lookahead_safe}

	func unbind_external_function(n: String) -> void:
		_externals.erase(n)

	func validate_external_bindings() -> void:
		var missing := {}
		_validate_externals_in(_main_content_container, missing)
		_has_validated_externals = true
		if missing.size() > 0:
			var msg := "Error: Missing function binding for external" + ("s" if missing.size() > 1 else "") + ": '" + "', '".join(PackedStringArray(missing.keys())) + "' "
			msg += ", and no fallback ink function found." if allow_external_function_fallbacks else " (ink fallbacks disabled)"
			error(msg)

	func _validate_externals_in(o: Obj, missing: Dictionary) -> void:
		if o == null:
			return
		if o.kind == K_CONT:
			for inner in o.content:
				if inner.kind != K_CONT or not inner.has_valid_name():
					_validate_externals_in(inner, missing)
			for k in o.named_content:
				_validate_externals_in(o.named_content[k], missing)
		elif o.kind == K_DIVERT and o.is_external:
			var nm = o.target_path_string()
			if not _externals.has(nm):
				if allow_external_function_fallbacks:
					if not _main_content_container.named_content.has(nm):
						missing[nm] = true
				else:
					missing[nm] = true

	# ---- tags at a path ----

	func global_tags():
		return tags_at_start_of_flow_container_with_path_string("")

	func tags_for_content_at_path(p: String):
		return tags_at_start_of_flow_container_with_path_string(p)

	func tags_at_start_of_flow_container_with_path_string(path_string: String):
		var flow_container: Cont = content_at_path(InkPath.from_string(path_string)).container()
		if flow_container == null:
			return null
		while flow_container.content.size() > 0 and flow_container.content[0].kind == K_CONT:
			flow_container = flow_container.content[0]
		var in_tag := false
		var tags = null
		for c in flow_container.content:
			if c.kind == K_CMD:
				if c.type == C_BEGIN_TAG:
					in_tag = true
				elif c.type == C_END_TAG:
					in_tag = false
			elif in_tag:
				if c.kind == K_VAL and c.vtype == VT_STRING:
					if tags == null:
						tags = []
					tags.append(c.value)
			else:
				break
		return tags

	# ---- stepping on ----

	func next_content() -> void:
		_state.set_previous_pointer(_state.current_pointer())
		if not _state.diverted_pointer.is_null():
			_state.set_current_pointer(_state.diverted_pointer)
			_state.diverted_pointer = Pointer.null_ptr()
			visit_changed_containers_due_to_divert()
			if not _state.current_pointer().is_null():
				return
		var ok := increment_content_pointer()
		if not ok:
			var did_pop := false
			if _state.call_stack().can_pop_type(PP_FUNCTION):
				_state.pop_call_stack(PP_FUNCTION)
				if _state.in_expression_evaluation():
					_state.push_evaluation_stack(Void.new())
				did_pop = true
			elif _state.call_stack().can_pop_thread():
				_state.call_stack().pop_thread()
				did_pop = true
			else:
				_state.try_exit_function_evaluation_from_game()
			if did_pop and not _state.current_pointer().is_null():
				next_content()

	func increment_content_pointer() -> bool:
		var ok := true
		var el := _state.call_stack().current_element()
		var cont: Cont = el.current_pointer.container
		var idx: int = el.current_pointer.index + 1
		while idx >= cont.content.size():
			ok = false
			var next_ancestor: Cont = cont.parent
			if next_ancestor == null:
				break
			var i := cont.index_in_parent()
			if i == -1:
				break
			cont = next_ancestor
			idx = i + 1
			ok = true
		el.current_pointer = Pointer.new(cont, idx) if ok else Pointer.NULL
		return ok

	func try_follow_default_invisible_choice() -> bool:
		var all_choices := _state.current_choices()
		var invisible: Array = []
		for c in all_choices:
			if c.is_invisible_default:
				invisible.append(c)
		if invisible.size() == 0 or all_choices.size() > invisible.size():
			return false
		var c: Choice = invisible[0]
		_state.call_stack().set_current_thread(c.thread_at_generation)
		if _state_snapshot_at_last_newline != null:
			_state.call_stack().set_current_thread(_state.call_stack().fork_thread())
		choose_path(c.target_path, false)
		return true

	func next_sequence_shuffle_index() -> int:
		var num_el := _state.pop_evaluation_stack()
		if num_el == null or not (num_el.kind == K_VAL and num_el.vtype == VT_INT):
			error("expected number of elements in sequence for shuffle index")
			return 0
		var seq_container: Cont = _state.current_pointer().container
		var num_elements: int = num_el.value
		var seq_count_val := _state.pop_evaluation_stack()
		var seq_count: int = seq_count_val.value
		var loop_index := floori(float(seq_count) / float(num_elements))
		var iteration_index := seq_count % num_elements
		var seq_path_str := seq_container.path().text()
		var sequence_hash := 0
		for i in range(seq_path_str.length()):
			sequence_hash += seq_path_str.unicode_at(i)
		var random_seed := sequence_hash + loop_index + _state.story_seed
		var prng := PRNG.new(random_seed)
		var unpicked: Array = []
		for i in range(num_elements):
			unpicked.append(i)
		for i in range(iteration_index + 1):
			var chosen := prng.next() % unpicked.size()
			var chosen_index: int = unpicked[chosen]
			unpicked.remove_at(chosen)
			if i == iteration_index:
				return chosen_index
		return 0

	# ---- errors ----

	# a StoryException: recorded, and the Continue loop turns it into an error
	func error(message: String) -> void:
		Ink._throw_global(message)

	func warning(message: String) -> void:
		add_error(message, true)

	func add_error(message: String, is_warning := false) -> void:
		var kind := "WARNING" if is_warning else "ERROR"
		var p := _state.current_pointer()
		if not p.is_null():
			message = "RUNTIME " + kind + ": (" + str(p) + "): " + message
		else:
			message = "RUNTIME " + kind + ": " + message
		_state.add_error(message, is_warning)
		if not is_warning:
			_state.force_end()
