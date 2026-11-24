# Out of the truck on his own feet (game/truck.gd keeps one of these): anywhere the truck stands
# still he can get out and walk round it, and get back in at the driver's door. Moving, he can bail:
# under a walking pace it's a stumble; faster it hurts, more the faster, and the truck goes on
# without him, door open, in whatever gear it was in, and rolls to a stop.
#
#   Q (or E at the door)   the door: out, or back in        W A S D   walk, Shift hurries
#   the mouse              his head                         Esc       leave the rehearsal
class_name TruckFoot
extends RefCounted

const EYE_H := 1.68                 # his eyes standing: six foot four
const RADIUS := 0.32
const WALK := 1.5
const HURRY := 4.2
const DOOR := Vector3(-1.45, 0.0, -0.05)    # where he stands to get in, the truck's own frame
const KEYS_ROWS := [["W A S D", "walk (Shift hurries)"], ["Mouse", "his head"], ["Q or E", "the door, at the driver's side"],
	["Esc", "leave"]]

var truck                           # game/truck.gd
var out := false
var pos := Vector3.ZERO             # his feet
var vel := Vector3.ZERO             # bailing: what he left the truck with
var down := 0.0                     # seconds still on the ground after a bail
var _rise := 1.0                    # 0 flat on the road, 1 standing
var _stride := 0.0
var _roll := 0.0


func _init(t) -> void:
	truck = t


func door_point() -> Vector3:
	var s: TruckSim = truck.sim
	var p := s.pos + s.rot * DOOR
	return Vector3(p.x, truck.road.height(p.x, p.z), p.z)


func near_door() -> bool:
	return out and down <= 0.0 and Vector2(pos.x - door_point().x, pos.z - door_point().z).length() < 1.5


# out the door: stepping down if it's still, bailing if it isn't. Returns how hard he hit the road
# (0 none, 1 a stumble, 2 hurt, 3 badly)
func get_out() -> int:
	var s: TruckSim = truck.sim
	var spd := absf(s.speed)
	out = true
	pos = door_point()
	var view: View = truck.view
	# his head keeps looking where it was, now in the world's terms rather than the cab's
	view.yaw = s.yaw() + view.yaw
	view.want_yaw = view.yaw
	if spd < 0.7:
		vel = Vector3.ZERO
		down = 0.0
		_rise = 0.62          # he unfolds out of the cab
		return 0
	var kmh := spd * 3.6
	var side := -(s.rot * Vector3.RIGHT)
	vel = s.vel * 0.9 + side * 1.6
	vel.y = 0.0
	if kmh < 12.0:
		down = 0.35
		_rise = 0.7
		return 1
	down = clampf(kmh / 14.0, 1.2, 4.5)
	_rise = 0.0
	_roll = (1.0 if randf() < 0.5 else -1.0) * clampf(kmh / 40.0, 0.4, 1.4)
	return 2 if kmh < 40.0 else 3


func get_in() -> void:
	out = false
	down = 0.0
	_roll = 0.0
	var view: View = truck.view
	view.lean_roll = 0.0
	view.yaw = 0.0
	view.want_yaw = 0.0
	view.pitch = -0.08
	view.want_pitch = -0.08


func step(dt: float) -> void:
	var view: View = truck.view
	var road: IslandRoad = truck.road
	if down > 0.0:
		# on the road: sliding and rolling till what he left with is gone
		down -= dt
		pos += vel * dt
		vel = vel.move_toward(Vector3.ZERO, 8.5 * dt)
		_roll = move_toward(_roll, 0.0, dt * 0.6)
	else:
		var wish := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W):
			wish.y += 1.0
		if Input.is_physical_key_pressed(KEY_S):
			wish.y -= 1.0
		if Input.is_physical_key_pressed(KEY_A):
			wish.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			wish.x += 1.0
		var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if pad.length() > 0.15:
			wish = pad
		wish = wish.limit_length(1.0)
		var fwd := Vector3(-sin(view.yaw), 0.0, -cos(view.yaw))
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var fast := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_STICK)
		var want := (fwd * wish.y + right * wish.x) * (HURRY if fast else WALK) * lerpf(0.4, 1.0, _rise)
		vel = vel.move_toward(want, dt * 9.0)
		pos += vel * dt
		_rise = move_toward(_rise, 1.0, dt * 0.8)
		_roll = move_toward(_roll, 0.0, dt * 2.0)
	_collide()
	pos.y = road.height(pos.x, pos.z)
	# his eyes: low while he's down, a step's bob as he goes
	var v := Vector2(vel.x, vel.z).length()
	_stride += v * dt
	var bob := 0.0
	if down <= 0.0:
		bob = (absf(sin(_stride / 0.78 * PI)) - 0.64) * 0.02 * clampf(v / WALK, 0.0, 1.5)
	var h := lerpf(0.32, EYE_H, smoothstep(0.0, 1.0, _rise))
	view.ride = null
	view.eye_pos = pos + Vector3(0, h + bob, 0)
	view.lean_roll = _roll * sin(down * 3.0) * 0.6 if down > 0.0 else _roll


# out of the walls by the road and the truck's own sides
func _collide() -> void:
	var s: TruckSim = truck.sim
	var walls: Array = truck.road.walls_near(pos, 8.0)
	var f := s.forward()
	walls.append([Vector2(s.pos.x, s.pos.z), TruckSim.HALF, atan2(f.x, -f.z), s.pos.y + 1.2])
	for w in walls:
		var c: Vector2 = w[0]
		var half: Vector2 = w[1]
		var a: float = w[2]
		var ax := Vector2(cos(a), sin(a))
		var az := Vector2(-sin(a), cos(a))
		var d := Vector2(pos.x, pos.z) - c
		var local := Vector2(d.dot(ax), d.dot(az))
		var near := Vector2(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y))
		var off := local - near
		var dist := off.length()
		if dist >= RADIUS:
			continue
		var push: Vector2
		if dist > 1e-4:
			push = off / dist * (RADIUS - dist)
		else:
			# inside it: out the nearest side
			var gx := half.x - absf(local.x)
			var gz := half.y - absf(local.y)
			push = Vector2(signf(local.x) * (gx + RADIUS), 0.0) if gx < gz else Vector2(0.0, signf(local.y) * (gz + RADIUS))
		var world := ax * push.x + az * push.y
		pos.x += world.x
		pos.z += world.y
		var n := world.normalized()
		var into := vel.x * n.x + vel.z * n.y
		if into < 0.0:
			vel.x -= into * n.x
			vel.z -= into * n.y
