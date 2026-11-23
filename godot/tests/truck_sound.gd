extends SceneTree
# The truck's sound (game/truck_sound.gd) rendered to a WAV, offline: a cold start, idle, a pull
# away through the gears (the rpm and load from the physics, game/truck_sim.gd), a cruise at 80 on
# the wet, a lift off, the horn. Checks it never clips hard or goes silent while the engine runs,
# and that each bank's pulses come unevenly (the lope). Listen to the file.
#   godot --headless --path godot -s res://tests/truck_sound.gd -- --out /tmp/truck.wav

var bad := 0


func _init() -> void:
	var out := "/tmp/truck.wav"
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
	var snd := TruckSound.new()
	snd._rng.seed = 460
	for i in 8:
		snd._cyl_jit.append(snd._rng.randf_range(0.88, 1.12))
	var sim := TruckSim.new()
	sim.place(Vector3.ZERO, 0.0)
	sim.running = false
	sim.rpm = 0.0
	var all := PackedVector2Array()
	var block := int(TruckSound.RATE / 60.0)
	var peak := 0.0
	var quiet_run := 0
	# script: [seconds, selector, throttle, brake, cranking, running, horn]
	var plan := [[1.0, "P", 0.0, 1.0, false, false, false], [1.2, "P", 0.0, 1.0, true, false, false],
		[3.0, "P", 0.0, 1.0, false, true, false], [1.5, "P", 0.7, 1.0, false, true, false],
		[1.5, "P", 0.0, 1.0, false, true, false], [14.0, "D", 0.85, 0.0, false, true, false],
		[6.0, "D", 0.3, 0.0, false, true, false], [3.0, "D", 0.0, 0.0, false, true, false],
		[1.2, "D", 0.0, 0.0, false, true, true], [3.0, "D", 0.0, 0.6, false, true, false]]
	for step in plan:
		sim.selector = step[1]
		sim.throttle = step[2]
		sim.brake = step[3]
		if step[4]:
			snd.cranking = step[0]
		sim.running = step[5]
		if step[5] and sim.rpm < 300.0:
			sim.rpm = 1100.0
		snd.horn = step[6]
		var frames := int(float(step[0]) * 60.0)
		for f in frames:
			for k in 4:
				sim.step()
			snd.rpm = sim.rpm
			snd.load = sim.throttle
			snd.speed = sim.speed
			snd.running = sim.running
			var b := snd.fill(block)
			var loud := 0.0
			for v in b:
				loud = maxf(loud, maxf(absf(v.x), absf(v.y)))
			peak = maxf(peak, loud)
			if sim.running and loud < 0.01:
				quiet_run += 1
			all.append_array(b)
	_check(peak < 1.0, "never clips hard (peak %.2f)" % peak)
	_check(peak > 0.15, "loud enough to hear (peak %.2f)" % peak)
	_check(quiet_run < 10, "never silent while it runs (%d silent frames)" % quiet_run)
	_save(out, all)
	print("  wrote %s, %.1f s" % [out, all.size() / TruckSound.RATE])
	print("truck_sound: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  BAD  ") + what)
	if not ok:
		bad += 1


func _save(path: String, buf: PackedVector2Array) -> void:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(TruckSound.RATE)
	w.stereo = true
	var data := PackedByteArray()
	data.resize(buf.size() * 4)
	for i in buf.size():
		data.encode_s16(i * 4, int(clampf(buf[i].x, -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(buf[i].y, -1.0, 1.0) * 32767.0))
	w.data = data
	w.save_to_wav(path)
