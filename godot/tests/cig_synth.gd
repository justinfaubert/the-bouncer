extends SceneTree
# The cigarette machine's voice (game/cig_synth.gd) on its own, offline: each patch plays a chord and
# a run, rendered to WAVs, and it's timed against real time (it has to make a second of sound in
# well under a second). Checks nothing comes out NaN or clipped.
#   godot --headless --path godot -s res://tests/cig_synth.gd -- [outdir]
func _init():
	var out := "user://cig"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var s := CigSynth.new()
	root.add_child(s)
	s.setup()
	var worst := 0.0
	for p in CigSynth.PATCHES.size():
		s.set_patch(p)
		s.all_off()
		var buf := PackedVector2Array()
		var t0 := Time.get_ticks_usec()
		var chord := [60, 64, 67, 71] if not bool(s.P.mono) else [48]
		var step := int(CigSynth.RATE * 0.25) - int(CigSynth.RATE * 0.25) % CigSynth.CTRL
		# a chord, pulled harder as it holds
		for n in chord:
			s.pull(n, 0.4)
		for k in 8:
			for n in chord:
				s.pull(n, 0.4 + k * 0.075)
			buf.append_array(s.render(step))
		for n in chord:
			s.push_in(n)
		buf.append_array(s.render(step * 2))
		# a run up
		for n in [60, 62, 63, 65, 67, 70, 72, 75]:
			s.pull(n, 0.6)
			buf.append_array(s.render(step / 2))
			s.push_in(n)
			buf.append_array(s.render(step / 2))
		buf.append_array(s.render(step * 4))
		var secs := buf.size() / CigSynth.RATE
		var took := (Time.get_ticks_usec() - t0) / 1e6
		var peak := 0.0
		var bad := false
		for v in buf:
			if is_nan(v.x) or is_nan(v.y):
				bad = true
			peak = maxf(peak, maxf(absf(v.x), absf(v.y)))
		worst = maxf(worst, took / secs)
		print("%-10s %.2fs of sound in %.2fs (%.0f%% of real time) peak %.2f %s" % [s.P.name, secs, took, took / secs * 100.0, peak, "NaN!" if bad else ""])
		_wav(out + "/patch_%d_%s.wav" % [p, str(s.P.name).replace(" ", "_")], buf)
	# the box: knocks, the flap, a quarter down the chute, two back
	s.set_patch(1)
	s.all_off()
	var b := PackedVector2Array()
	for k in 4:
		s.knock(0.2 + k * 0.2, 0.5, 0.8, 1.0 if k % 2 == 0 else 0.0)
		b.append_array(s.render(8000))
	s.flap(0.8)
	b.append_array(s.render(16000))
	s.coin_in()
	b.append_array(s.render(24000))
	s.coin_in()
	b.append_array(s.render(16000))
	s.knob_click(false)
	b.append_array(s.render(6400))
	s.knob_click(true)
	b.append_array(s.render(6400))
	s.knob_home()
	b.append_array(s.render(9600))
	s.coins_back()
	b.append_array(s.render(24000))
	_wav(out + "/the_box.wav", b)
	# the hold and the motor: a quarter, a chord, let go, the arpeggio over two octaves
	s.set_patch(4)
	s.all_off()
	s.coin_in()
	s.coin_in()
	var c := PackedVector2Array()
	for n in [57, 60, 64]:
		s.pull(n, 0.6)
		c.append_array(s.render(1600))
		s.push_in(n)
	s.set_arp(true)
	c.append_array(s.render(int(CigSynth.RATE * 5) - int(CigSynth.RATE * 5) % 16))
	_wav(out + "/arpeggio.wav", c)
	print("worst %.0f%% of real time" % (worst * 100.0))
	quit()

func _wav(path: String, buf: PackedVector2Array) -> void:
	var data := PackedByteArray()
	data.resize(buf.size() * 4)
	for i in buf.size():
		data.encode_s16(i * 4, int(clampf(buf[i].x, -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(buf[i].y, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.stereo = true
	w.mix_rate = int(CigSynth.RATE)
	w.data = data
	w.save_to_wav(path)
