extends SceneTree
# The truck's radio (game/truck_radio.gd), offline: switched off, then on just off the island's
# station, tuned in, swept across the band through the static, each of the five buttons, and the
# voice through every station that game/truck_odd.gd makes. Checks what can be read comes and goes
# with the signal, the static falls when a station's in, the town's news reads the night, a caller
# phones in what he did, 1470 reads his odometer, nothing clips, and what it costs to make.
# Writes the whole thing to a WAV: listen to it.
#   godot --headless --path godot -s res://tests/truck_radio.gd -- --out /tmp/radio.wav

var bad := 0
var r: TruckRadio
var all := PackedVector2Array()


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		print("  FAIL ", what)
		bad += 1


# seconds of it: [rms, peak, captions seen]
func _run(secs: float) -> Array:
	var block := int(TruckRadio.RATE / 60.0)
	var e := 0.0
	var pk := 0.0
	var n := 0
	var caps := {}
	for f in int(secs * 60.0):
		var b := r.fill(block)
		for v in b:
			e += v.x * v.x
			pk = maxf(pk, absf(v.x))
			n += 1
			if is_nan(v.x):
				bad += 1
		all.append_array(b)
		if r.caption != "":
			caps[r.caption_from + " | " + r.caption] = true
	return [sqrt(e / maxf(n, 1)), pk, caps.keys()]


func _init() -> void:
	var out := "/tmp/radio.wav"
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
	r = TruckRadio.new()
	r._rng.seed = 78
	r._bleed_v = r._voice_state("it")
	TruckRadio._coef(r._spk, 1500.0, 1.2)
	r._make_stations()
	var vars := {"ogre_done": 2, "ring_name": 3, "esso_answered": 1, "count_in": 31, "walter": 0, "hurt": 2}
	r.begin(vars, [{"x": "Want to find out?"}, {"x": "[Strength 9] Put him out the door."}])
	r.drive = {"odo": 86417, "where": "North of the motel", "out": false}
	r.rpm = 800.0
	print("the town's news:")
	for l in r.news:
		print("   ", l)
	_check(r.news.size() >= 5, "the night's story made the island's news (%d items)" % r.news.size())
	_check(TruckRadio.news_from({}).is_empty(), "an empty night makes no news about him")
	_check(r.his_words.has("Put him out the door."), "his words come through without the check's markup")
	_check(TruckRadio.place_name(450.0) == "At the motel" and TruckRadio.place_name(800.0) == "North of the motel", "where he is, said the island's way")

	var off := _run(1.0)
	_check(off[1] < 0.001, "off is silent")
	r.toggle()
	var near := _run(4.0)
	print("  1238 kHz: rms %.3f peak %.3f" % [near[0], near[1]])
	_check(near[0] > 0.01, "on, just off the island's station: something's coming out")
	r.dial = 1240.0
	var t0 := Time.get_ticks_usec()
	var tuned := _run(40.0)
	var cost := float(Time.get_ticks_usec() - t0) / 1000.0 / 40.0
	print("  1240 kHz: rms %.3f peak %.3f, %.1f ms to make each second" % [tuned[0], tuned[1], cost])
	for c in tuned[2].slice(0, 6):
		print("     ", c)
	_check(tuned[1] < 0.95, "it never clips hard")
	_check(cost < 120.0, "it costs under an eighth of the time it plays")
	# the static between the stations
	r.dial = 1150.0
	var between := _run(3.0)
	print("  1150 kHz: rms %.3f, captions %d" % [between[0], between[2].size()])
	_check(between[2].is_empty(), "nothing to read between the stations")
	_check(between[0] > 0.02, "between the stations, the static")
	# a sweep, the way a hand does it
	for i in 180:
		r.tune(-2.0)
		_run(1.0 / 60.0)
	_check(r.dial < 1150.0 and r.dial > 700.0, "the sweep moved the pointer (%.0f)" % r.dial)
	# the buttons
	var seen := {}
	for i in TruckRadio.PRESETS.size():
		r.preset(i)
		r.dial = TruckRadio.PRESETS[i]
		r._want = -1.0
		var res := _run(25.0)
		var near_st: Array = r.nearest()
		_check(near_st[0] != null and float(near_st[0].f) == TruckRadio.PRESETS[i], "button %d is %s" % [i + 1, near_st[0].call])
		for c in res[2].slice(0, 3):
			print("     ", c)
		seen[i] = res[2]
	# a caller: he bailed; Reg says so
	r.dial = 1240.0
	r.saw("bail")
	_check(r._pending.size() == 1, "a bail gets phoned in")
	r._pending[0][0] = r._t
	var called := _run(30.0)
	var heard_it := false
	for c in called[2]:
		if "door open" in c or "Cutting in" in c:
			heard_it = true
	_check(heard_it, "Reg reads the caller about the truck with its door open")
	r.saw("bail")
	_check(r._pending.is_empty(), "the same thing's phoned in once a drive")
	# 1470 reads his odometer, sooner or later
	r.dial = 1470.0
	var it_st: Dictionary = r.stations[4]
	it_st.k = 1
	r._next(it_st)
	var odd := _run(12.0)
	var digits := false
	for c in odd[2]:
		if "Eight. Six. Four. One. Seven." in c:
			digits = true
	_check(digits, "1470 reads the odometer")
	# something on the road: every station goes under, and the voice
	r.dial = 1240.0
	r.interfere = 1.0
	r.bleed = "\"Want to find out?\""
	var through := _run(4.0)
	var bled := false
	for c in through[2]:
		if "Want to find out" in c:
			bled = true
	_check(bled, "the voice comes through every station")
	r.interfere = 0.0
	r.bleed = ""
	r.toggle()
	_run(1.0)
	_save(out, all)
	print("wrote ", out, " (", all.size() / int(TruckRadio.RATE), " s)")
	print("FAILED %d" % bad if bad > 0 else "ALL OK")
	r.free()
	quit(1 if bad > 0 else 0)


func _save(path: String, b: PackedVector2Array) -> void:
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i].x, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(TruckRadio.RATE)
	w.stereo = false
	w.data = data
	w.save_to_wav(path)
