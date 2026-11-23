extends SceneTree
# The wine glasses' voice (game/glass_synth.gd) on its own, offline: a glass rubbed at a range of
# speeds and pressures, wet and dry, how loud it settles and at what pitch (counted from its zero
# crossings against what French's formula says), a tap, a pour, and a scale. WAVs out, timed.
#   godot --headless --path godot -s res://tests/glass_synth.gd -- [outdir]
func _init():
	var out := "user://glass"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var s := GlassSynth.new()
	root.add_child(s)
	s.setup()
	for i in GlassSynth.NG:
		s.set_glass(i, 720.0 + i * 55.0, 0.0006, 0.0)
	var blk := 1600
	# the rub: how it settles at each speed and pressure
	print("speed  press  wet   rms    pitch  want   squeal")
	for wet in [1.0, 0.2]:
		for press in [0.5, 1.0, 1.8]:
			for vb in [0.05, 0.15, 0.3, 0.6, 1.2]:
				s.glasses[0].x.fill(0.0)
				s.glasses[0].y.fill(0.0)
				s.set_finger(0, vb, press, wet)
				var buf := PackedVector2Array()
				var t0 := Time.get_ticks_usec()
				for k in 30:
					buf.append_array(s.render(blk))
				var took := (Time.get_ticks_usec() - t0) / 1e6
				var tail := buf.slice(buf.size() - 16000)
				var rms := 0.0
				var zc := 0
				for j in tail.size():
					rms += tail[j].x * tail[j].x
					if j > 0 and (tail[j - 1].x < 0.0) != (tail[j].x < 0.0):
						zc += 1
				rms = sqrt(rms / tail.size())
				print("%.2f   %.1f    %.1f   %.3f  %5.0f  %5.0f  %.3f  (%.0f%% rt)" % [vb, press, wet, rms, zc / 2.0 / (tail.size() / GlassSynth.RATE), s.freq(0), s.glasses[0].squeal, took / (buf.size() / GlassSynth.RATE) * 100.0])
				if wet == 1.0 and press == 1.0 and vb == 0.3:
					_wav(out + "/rub.wav", buf)
				if wet == 0.2 and press == 1.0 and vb == 0.3:
					_wav(out + "/rub_dry.wav", buf)
				if wet == 1.0 and press == 1.8 and vb == 0.05:
					_wav(out + "/rub_grind.wav", buf)
	s.set_finger(0, 0.0, 0.0, 1.0)
	# a tap on each, then a sung glass filled while it sings
	var b := PackedVector2Array()
	for i in GlassSynth.NG:
		s.tap(i, 0.7, 1.0)
		b.append_array(s.render(8000))
	b.append_array(s.render(32000))
	s.set_finger(3, 0.3, 1.0, 1.0)
	for k in 60:
		if k > 15:
			s.set_fill(3, (k - 15) / 45.0 * 0.8)
			s.pour = 0.7
			s.pour_into = 3
		b.append_array(s.render(1600))
	s.pour = 0.0
	s.set_finger(3, 0.0, 0.0, 1.0)
	b.append_array(s.render(48000))
	var peak := 0.0
	for v in b:
		peak = maxf(peak, absf(v.x))
	print("taps and a pour: peak %.2f" % peak)
	_wav(out + "/taps_and_pour.wav", b)
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
	w.mix_rate = int(GlassSynth.RATE)
	w.data = data
	w.save_to_wav(path)
