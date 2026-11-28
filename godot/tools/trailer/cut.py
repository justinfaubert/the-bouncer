#!/usr/bin/env python3
"""The teaser's cut, timed to "Slow Heavy Mercy" (Mallvvays).

What the track does (tools/trailer/analyze.py, librosa): 136 BPM, a bar every 1.79 s. A swelling
intro with no drums to 0:09.7, where the drums come in on a downbeat; four minutes of the band; a
loud last push at 4:01; at 4:08.8 the drums drop out for two bars; they're back at 4:12.5 for
sixteen bars; at 4:42.1 they stop and the last chord rings out to 4:51.

The teaser is two pieces of it: 0:00 to 0:38.4 (the intro and the first sixteen bars), two beats
of nothing but the last-call bell, then 4:01.5 to the end. Every cut lands on a bar or a half bar
of the music as it plays in the teaser.

  python3 cut.py plan   --analysis analysis.json --out cut.json      the shots and their frames
  python3 cut.py music  --track track.mp3 --out music.wav            the edit of the track
  python3 cut.py film   --cut cut.json --frames DIR --music music.wav --out teaser.mp4
"""
import argparse, json, os, subprocess, sys

FPS = 24
A_END = 38.38          # the end of the first sixteen bars with drums (a downbeat)
GAP = 2 * 60 / 136.0   # two beats of the bell
B_FROM = 241.46        # four bars before the break
B_TO = 290.96

def b(t):              # a time in the track's second piece, in the teaser
    return t - B_FROM + A_END + GAP

# the shots in the order they're cut, and the teaser time each one starts
SHOTS = [
    # the intro, no drums: the place, the room before the doors, the door
    ("sov_far", 0.0),
    ("bar_empty", 4.34),
    ("door_in", 7.92),
    # the drums: a cut every two bars, then every bar
    ("door_hand", 9.71),
    ("room_full", 13.30),
    ("talk", 16.88),
    ("walk_lot", 20.46),
    ("darts_aim", 24.06),
    ("darts_fly", 25.84),
    ("pool_break", 27.63),
    ("cig_synth", 29.44),
    ("washer", 31.21),
    ("truck_road", 33.00),
    ("fight_frozen", 34.81),
    ("payphone_wall", 36.60),
    ("_bell", A_END),
    # the last push: every half bar
    ("x_fight_hit", b(241.46)),
    ("x_pool_pot", b(242.38)),
    ("x_dart_treble", b(243.30)),
    ("x_line_rain", b(244.20)),
    ("x_stall", b(245.11)),
    ("x_declined", b(246.02)),
    ("x_cig_pull", b(246.94)),
    ("x_mirror", b(247.86)),
    # the break: it comes up out of the water
    ("listener_rise", b(248.78)),
    # back in: two bars a shot
    ("listener_push", b(252.47)),
    ("room_frozen", b(256.16)),
    ("line_door", b(259.86)),
    ("fight_live", b(263.57)),
    ("pool_table", b(267.29)),
    ("hall_walk", b(271.00)),
    ("sign_dying", b(274.74)),
    ("seawall_end", b(278.48)),
    # the drums stop: the title, and the chord ringing out
    ("_title", b(282.10)),
]
END = b(B_TO)

# The game played as it's played, the page and all: these keep the whole 16:9 frame. Everything
# else is the film, cut to 2.39:1 out of the middle (or this far down from the top, in pixels at
# 1080, where the shot's better framed lower or higher).
FULL = {"door_hand", "darts_aim", "pool_break", "x_pool_pot", "fight_frozen", "x_fight_hit",
        "fight_live", "x_cig_pull", "pool_table"}
CROP_Y = {"sov_far": 0, "seawall_end": 60, "sign_dying": 40}
SCOPE_H = 804
# A shot cut from another one's frames instead of its own: (the shot, its first frame, how far in,
# and the middle of the picture in 1080p pixels)
SOURCE = {"x_dart_treble": ("darts_fly", 21, 1.7, (1240, 860))}
# Super 8 (the second cut): the gate's round corners are in the picture, so nothing is cut to scope.
SCOPE = False
# The dream pass over every frame of the film (dream() below): these shots trail a little of the
# frames before them, the way a step-printed shot smears, slowed down and remembered.
TRAIL = {"sov_far": 0.32, "seawall_end": 0.3, "listener_rise": 0.38, "listener_push": 0.35,
         "x_mirror": 0.3, "room_frozen": 0.25, "bar_empty": 0.2, "sign_dying": 0.25}


def dream(frames, seed=8):
    """What a reel of Super 8 picks up between the camera and the projector, laid over the rendered
    frames: the first frames of every shot flashed as the motor comes up to speed, dust and the odd
    hair in the gate, a scratch down the emulsion now and then, and the remembered shots trailing.
    frames: [(src path, dst path, shot, frame in shot, frames in shot)], written in order."""
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
    rng = np.random.default_rng(seed)
    prev = None
    hair = None
    scratch = None
    for src, dst, shot, i, n in frames:
        im = Image.open(src).convert("RGB")
        w, h = im.size
        a = np.asarray(im).astype(np.float32) / 255.0
        lin = a ** 2.2
        # a trail of the frames before, in the remembered shots
        k = TRAIL.get(shot, 0.0)
        if k and prev is not None and i > 0:
            lin = lin * (1.0 - k) + prev * k
        prev = lin.copy()
        if not shot.startswith("_"):
            # the camera's motor coming up to speed: the first frames burn warm, and the last one
            # of a shot dips as the reel's let go
            if i < 3:
                f = [1.9, 1.35, 1.1][i]
                lin = lin * f + np.array([0.05, 0.02, 0.0]) * (f - 1.0)
            elif i == n - 1:
                lin *= 0.86
        out = np.clip(lin, 0, 1) ** (1 / 2.2)
        im = Image.fromarray((out * 255 + 0.5).astype(np.uint8))
        if shot != "_bell":
            d = ImageDraw.Draw(im)
            # dust: dark flecks, a new handful every frame, mostly small
            for _ in range(int(rng.poisson(2.2))):
                x, y = rng.uniform(0, w), rng.uniform(0, h)
                r = rng.choice([1.0, 1.4, 2.0, 3.2], p=[0.45, 0.3, 0.18, 0.07])
                pts = [(x + rng.normal(0, r), y + rng.normal(0, r)) for _ in range(5)]
                d.polygon(pts, fill=(8, 6, 5))
            # now and then a white fleck: a scrape through to the base
            if rng.random() < 0.18:
                x, y = rng.uniform(0, w), rng.uniform(0, h)
                d.ellipse((x - 1.5, y - 1.5, x + 1.5, y + 1.5), fill=(235, 225, 205))
            # a hair caught at the edge of the gate stays a few frames, trembling
            if hair is None and rng.random() < 0.012:
                side = rng.choice([0, 1])
                x0 = rng.uniform(0.05, 0.2) * w if side == 0 else rng.uniform(0.8, 0.95) * w
                y0 = rng.uniform(0.1, 0.9) * h
                ang = rng.uniform(0, 6.28)
                hair = [x0, y0, ang, int(rng.integers(6, 18))]
            if hair is not None:
                x0, y0, ang, left = hair
                pts = []
                for t in np.linspace(0, 1, 14):
                    pts.append((x0 + np.cos(ang + t * 2.2) * 60 * t + rng.normal(0, 0.6),
                                y0 + np.sin(ang + t * 2.2) * 60 * t + rng.normal(0, 0.6)))
                d.line(pts, fill=(10, 8, 6), width=2)
                hair[3] -= 1
                if hair[3] <= 0:
                    hair = None
            # a scratch down the emulsion, wandering, for a beat or two
            if scratch is None and rng.random() < 0.006:
                scratch = [rng.uniform(0.15, 0.85) * w, int(rng.integers(6, 16))]
            if scratch is not None:
                scratch[0] += rng.normal(0, 1.2)
                x = scratch[0]
                d.line([(x + rng.normal(0, 0.4), 0), (x + rng.normal(0, 0.4), h)], fill=(200, 192, 176), width=1)
                scratch[1] -= 1
                if scratch[1] <= 0:
                    scratch = None
        im.save(dst, quality=95)


def plan(args):
    shots = []
    for i, (name, t0) in enumerate(SHOTS):
        t1 = SHOTS[i + 1][1] if i + 1 < len(SHOTS) else END
        f0, f1 = round(t0 * FPS), round(t1 * FPS)
        shots.append({"name": name, "t0": round(t0, 3), "frame": f0, "frames": f1 - f0})
    json.dump({"fps": FPS, "end": END, "frames": round(END * FPS), "shots": shots}, open(args.out, "w"), indent=1)
    for s in shots:
        print(f"{s['t0']:7.2f}  {s['frames']:4d}  {s['name']}")
    print("teaser", round(END, 2), "s")


def music(args):
    # the two pieces butted on their downbeats, two beats of silence between, a few ms of fade at each
    # edge so nothing clicks; the bell goes in over the gap in film()
    gap = GAP
    fc = (f"[0:a]atrim=0:{A_END},asetpts=PTS-STARTPTS,afade=t=out:st={A_END-0.03}:d=0.03[a];"
          f"[0:a]atrim={B_FROM}:{B_TO},asetpts=PTS-STARTPTS,afade=t=in:d=0.01[b];"
          f"anullsrc=r=48000:cl=stereo,atrim=0:{gap}[g];"
          f"[a][g][b]concat=n=3:v=0:a=1[out]")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", args.track, "-filter_complex", fc, "-map", "[out]",
                    "-ar", "48000", args.out], check=True)


SOUNDS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "audio")
INK = (0xea, 0xe2, 0xcf)
PAPER = (7, 8, 11)


def title_frames(n, size, font_path, outdir):
    """LAST CALL, the way the game's title comes down: a block on a press, a quarter second in,
    big and then hard down with a jolt; held in the dark while the chord rings; gone at the end."""
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
    import random
    w, h = size
    os.makedirs(outdir, exist_ok=True)
    big = min(h, w / 2.39) * 0.2
    paths = []
    rnd = random.Random(7)
    for i in range(n):
        t = i / FPS
        im = Image.new("RGB", (w, h), PAPER)
        land = 0.25
        if t >= land - 0.06:
            k = min(1.0, max(0.0, (t - (land - 0.06)) / 0.09))
            scale = 1.18 - 0.18 * (k * k)
            alpha = min(1.0, max(0.0, (t - (land - 0.06)) / 0.06))
            # the last seconds: it goes, the way a print fades when the lamp's off
            alpha *= 1.0 - min(1.0, max(0.0, (t - (n / FPS - 2.2)) / 1.9))
            f = ImageFont.truetype(font_path, int(big * scale))
            try:
                f.set_variation_by_axes([780])
            except Exception:
                pass
            txt = "LAST CALL"
            layer = Image.new("L", (w, h), 0)
            d = ImageDraw.Draw(layer)
            bb = d.textbbox((0, 0), txt, font=f)
            tw, th = bb[2] - bb[0], bb[3] - bb[1]
            jolt = 0
            if land + 0.09 <= t < land + 0.3:
                u = (t - land - 0.09) / 0.21
                jolt = int(5 * (1 - u) * (1 if u < 0.2 else -0.4) * h / 1080)
            d.text(((w - tw) / 2 - bb[0], (h - th) / 2 - bb[1] + jolt), txt, font=f, fill=255)
            # the ink doesn't take everywhere: a block print's speckle
            noise = Image.effect_noise((w // 2, h // 2), 60).resize((w, h)).point(lambda v: 255 if v > 34 else 0)
            layer = Image.composite(layer, Image.new("L", (w, h), 0), noise).filter(ImageFilter.GaussianBlur(0.6))
            layer = layer.point(lambda v: int(v * alpha))
            im.paste(Image.new("RGB", (w, h), INK), (0, 0), layer)
        p = os.path.join(outdir, f"{i:04d}.jpg")
        im.save(p, quality=95)
        paths.append(p)
    return paths


def film(args):
    from PIL import Image
    cutd = json.load(open(args.cut))
    seq = os.path.join(args.work, "seq")
    if os.path.isdir(seq):
        for f in os.listdir(seq):
            os.remove(os.path.join(seq, f))
    os.makedirs(seq, exist_ok=True)
    size = None
    for s in cutd["shots"]:
        d = os.path.join(args.frames, s["name"])
        if os.path.isdir(d) and any(f.endswith(".jpg") for f in os.listdir(d)):
            size = Image.open(os.path.join(d, sorted(f for f in os.listdir(d) if f.endswith(".jpg"))[0])).size
            break
    size = (1920, 1080)
    black = os.path.join(args.work, "black.jpg")
    Image.new("RGB", size, PAPER).save(black, quality=95)
    scope = os.path.join(args.work, "scope")
    os.makedirs(scope, exist_ok=True)
    events = []
    jobs = []
    k = 0
    for s in cutd["shots"]:
        name, n = s["name"], s["frames"]
        t0 = s["frame"] / FPS
        k0 = k
        if name == "_title":
            src = title_frames(n, (size[0], SCOPE_H if SCOPE else size[1]), args.font, os.path.join(args.work, "title"))
            events += [[t0 + 0.25, "stamp", 1.0], [t0 + 0.25, "thump", 0.8]]
        elif name == "_bell":
            src = [black] * n
            events.append([t0, "bell", 1.0])
        else:
            src_name, first, zoom, centre = SOURCE.get(name, (name, 0, 1.0, None))
            d = os.path.join(args.frames, src_name)
            have = sorted(f for f in os.listdir(d) if f.endswith(".jpg")) if os.path.isdir(d) else []
            if len(have) < n:
                print(f"film: {name} has {len(have)} of {n} frames", file=sys.stderr)
            have = have[first:]
            src = [os.path.join(d, have[i]) if i < len(have) else (os.path.join(d, have[-1]) if have else black) for i in range(n)]
            if zoom != 1.0 and have:
                zd = os.path.join(args.work, "zoom_" + name)
                os.makedirs(zd, exist_ok=True)
                zs = []
                for i, p in enumerate(src):
                    im = Image.open(p)
                    w2, h2 = im.size[0] / zoom, im.size[1] / zoom
                    cx = min(max(centre[0], w2 / 2), im.size[0] - w2 / 2)
                    cy = min(max(centre[1], h2 / 2), im.size[1] - h2 / 2)
                    im = im.crop((int(cx - w2 / 2), int(cy - h2 / 2), int(cx + w2 / 2), int(cy + h2 / 2))).resize(im.size, Image.LANCZOS)
                    zp = os.path.join(zd, f"{i:04d}.jpg")
                    im.save(zp, quality=95)
                    zs.append(zp)
                src = zs
            ev = os.path.join(d, "events.json")
            if os.path.exists(ev) and src_name == name:
                for e in json.load(open(ev)):
                    events.append([t0 + e[0], e[1], e[2]])
        for p in src:
            dst = os.path.join(seq, f"{k:05d}.jpg")
            if not SCOPE:
                jobs.append((p, dst, name, k - k0, n))
            elif name in FULL or name.startswith("_") or p == black:
                if name == "_title":
                    # the title's drawn at scope: put it in the bars
                    im = Image.new("RGB", size, PAPER)
                    t = Image.open(p)
                    im.paste(t, (0, (size[1] - t.size[1]) // 2))
                    im.save(dst, quality=95)
                else:
                    os.symlink(os.path.abspath(p), dst)
            else:
                im = Image.open(p)
                y = CROP_Y.get(name, (im.size[1] - SCOPE_H) // 2)
                out = Image.new("RGB", size, PAPER)
                out.paste(im.crop((0, y, im.size[0], y + SCOPE_H)), (0, (size[1] - SCOPE_H) // 2))
                out.save(dst, quality=95)
            k += 1
    if jobs:
        dream(jobs)
    # the sounds of the game under the music, where they happen
    ins = ["-i", args.music]
    fc = []
    mix = ["[0:a]"]
    for i, (t, snd, g) in enumerate(events):
        path = os.path.join(SOUNDS, snd + ".wav")
        if not os.path.exists(path):
            print("film: no sound", snd, file=sys.stderr)
            continue
        ins += ["-i", path]
        j = len(mix)
        ms = int(t * 1000)
        fc.append(f"[{j}:a]aresample=48000,aformat=channel_layouts=stereo,volume={g * 0.5},adelay={ms}|{ms}[s{j}]")
        mix.append(f"[s{j}]")
    fc.append("".join(mix) + f"amix=inputs={len(mix)}:normalize=0:duration=first,alimiter=limit=0.95[a]")
    pad = ""
    # night stock wants its toe pressed down; Super 8 already has its blacks, so only a touch
    toe = "0/0 0.10/0.045 0.35/0.28 0.7/0.68 1/0.97" if SCOPE else "0/0 0.08/0.06 0.35/0.33 0.7/0.71 1/0.98"
    grade = (f"curves=master='{toe}',"
             "eq=saturation=1.04,"
             "fade=t=in:st=0:d=1.6")
    vf = f"[{len(mix)}:v]{grade}{pad},format=yuv420p[v]"
    fc.append(vf)
    cmd = ["ffmpeg", "-y", "-v", "error"] + ins + ["-framerate", str(FPS), "-i", os.path.join(seq, "%05d.jpg"),
           "-filter_complex", ";".join(fc), "-map", "[v]", "-map", "[a]",
           "-c:v", "libx264", "-preset", "slow", "-crf", "19", "-pix_fmt", "yuv420p",
           "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart", "-shortest", args.out]
    subprocess.run(cmd, check=True)
    print("film:", args.out, k, "frames,", len(events), "sounds")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("what")
    ap.add_argument("--analysis")
    ap.add_argument("--track")
    ap.add_argument("--out")
    ap.add_argument("--cut")
    ap.add_argument("--frames")
    ap.add_argument("--music")
    ap.add_argument("--work", default="/tmp/trailer/work")
    ap.add_argument("--font", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "fonts", "big-shoulders-display-300.woff2"))
    a = ap.parse_args()
    os.makedirs(a.work, exist_ok=True)
    if a.font.endswith(".woff2"):
        # the game's display face, out of its web wrapping for PIL (pip install fonttools brotli)
        from fontTools.ttLib import TTFont
        f = TTFont(a.font)
        f.flavor = None
        a.font = os.path.join(a.work, "display.ttf")
        f.save(a.font)
    {"plan": plan, "music": music, "film": film}[a.what](a)
