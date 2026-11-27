#!/usr/bin/env python3
"""What the track does, for the cut (cut.py): tempo, beats, bars (the strongest beat of four as the
downbeat), onsets, the loudest hits, the energy second by second and the sections where the sound
changes. python3 analyze.py track.mp3 [analysis.json]"""
import librosa, numpy as np, json, sys
track = sys.argv[1] if len(sys.argv) > 1 else "track.mp3"
out_path = sys.argv[2] if len(sys.argv) > 2 else "analysis.json"
y, sr = librosa.load(track, sr=22050, mono=True)
dur = len(y)/sr
tempo, beats = librosa.beat.beat_track(y=y, sr=sr, units='time')
onset_env = librosa.onset.onset_strength(y=y, sr=sr)
onsets = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, units='time')
rms = librosa.feature.rms(y=y)[0]; t = librosa.times_like(rms, sr=sr)
# per-second energy
sec = [float(np.mean(rms[(t>=i)&(t<i+1)])) for i in range(int(dur)+1)]
# structural segments
S = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
bounds = librosa.segment.agglomerative(S, 10)
bt = librosa.frames_to_time(bounds, sr=sr)
# downbeat guess: strongest beat phase mod 4
oe_b = onset_env[librosa.time_to_frames(beats, sr=sr)]
phase = int(np.argmax([oe_b[i::4].mean() for i in range(4)]))
# strong hits
strong = onsets[onset_env[librosa.time_to_frames(onsets,sr=sr)] > np.percentile(onset_env, 97)]
out = dict(dur=dur, tempo=float(np.atleast_1d(tempo)[0]), beats=[round(float(b),3) for b in beats], downbeat_phase=phase,
  segments=[round(float(b),2) for b in bt], strong=[round(float(s),2) for s in strong], energy=[round(e,4) for e in sec])
json.dump(out, open(out_path, 'w'))
print('dur',dur,'tempo',out['tempo'],'nbeats',len(beats),'phase',phase)
print('segments',out['segments'])
print('strong',out['strong'])
mx=max(sec)
for i,e in enumerate(sec): print(f"{i:3d} {'#'*int(40*e/mx)}")
