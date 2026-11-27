"""The second round of the set dressing's pictures (world/dressing.gd): more ads, the strange things
on the walls, the layers (stains, rings, scuffs, stickers, the scrawl in the hall).

    python3 godot/tools/dressing2.py [which ...]

Uses the helpers in dressing.py (Sheet, age, save, the fonts). The velvet painting needs the
poster-girl render (tools/poster_girls, pose "velvet") in GIRLS_WORK; the painting of the room needs
the eye picture of tests/shots_dressing.gd's src_1952 view (ROOM_SRC, default /tmp/claude-0/src).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dressing import (SS, OUT, WORK, Sheet, age, font, noise, rgb, save, spline)  # noqa: E402

ROOM_SRC = os.environ.get('ROOM_SRC', '/tmp/claude-0/src/src_1952_eye.png')


def _layer(w, h):
    """A transparent sheet to draw on."""
    sh = Sheet(w, h, '000000')
    sh.im = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))
    sh.d = ImageDraw.Draw(sh.im)
    return sh


# ---------------------------------------------------------------------------------- the new ads

def teeth(w=500, h=750):
    """ALEXANDER TEETH'S: the sea captain, all teeth."""
    sh = Sheet(w, h, '17283e')
    cx = w / 2
    # the sea behind him, three bands, a lighthouse far off
    for i, c in enumerate(('1d3350', '22405f', '2a4d6e')):
        sh.rect(0, 430 + i * 40, w, 470 + i * 40, c)
    sh.rect(0, 550, w, h, '0f1b2b')
    sh.poly([(410, 470), (420, 380), (428, 380), (438, 470)], 'e8dcc0')
    sh.rect(414, 368, 434, 382, 'e8c84a')
    # the captain: the head a great round mask, the beard a white cloud, the cap, the grin
    sh.ellipse(cx - 150, 150, cx + 150, 470, 'e2b48a', '2a1a10', 4)
    sh.blob([(cx - 165, 330), (cx - 150, 450), (cx - 60, 520), (cx + 60, 520), (cx + 150, 450), (cx + 165, 330),
             (cx + 110, 360), (cx - 110, 360)], 'f2efe6', '9aa0a8', 3)
    sh.poly([(cx - 170, 190), (cx + 170, 190), (cx + 150, 150), (cx - 150, 150)], '0f1b2b')
    sh.blob([(cx - 140, 155), (cx - 110, 80), (cx + 110, 80), (cx + 140, 155)], '1b2b44', '0b1320', 3)
    sh.ellipse(cx - 30, 120, cx + 30, 160, 'e8c84a', 'a07a20', 2)
    # the eyes: two drawn rings, the pupils off to one side, like he's seen something behind you
    for ex in (cx - 62, cx + 62):
        sh.ellipse(ex - 34, 232, ex + 34, 292, 'fbf6ea', '2a1a10', 4)
        sh.ellipse(ex - 4, 250, ex + 22, 280, '1a120c')
    sh.blob([(cx - 96, 214), (cx - 60, 200), (cx - 28, 212)], None, '2a1a10', 6, closed=False)
    sh.blob([(cx + 28, 212), (cx + 60, 200), (cx + 96, 214)], None, '2a1a10', 6, closed=False)
    sh.blob([(cx - 12, 290), (cx - 22, 330), (cx + 4, 336)], None, '8a5a3a', 4, closed=False)
    # the grin: too many teeth, two rows of them, every one its own
    sh.blob([(cx - 112, 360), (cx, 420), (cx + 112, 360), (cx, 392)], '5a1a14', '2a1a10', 3)
    for row, (y0, y1, n) in enumerate(((362, 386, 14), (386, 404, 12))):
        for k in range(n):
            t0, t1 = k / n, (k + 1) / n
            xa = cx - 104 + 208 * t0
            xb = cx - 104 + 208 * t1
            dip = 16 * math.sin(math.pi * (t0 + t1) / 2)
            sh.rect(xa + 1, y0 + dip * (0.6 if row else 1.0), xb - 1, y1 + dip, 'fbf6ea', '9a8a70', 1)
    sh.text((cx, 600), "ALEXANDER TEETH'S", font('zilla-slab-600', 46), 'e8dcc0', anchor='mm', track=2)
    sh.text((cx, 646), 'I N D I A   P A L E   A L E', font('barlow-condensed-600', 22), 'e8c84a', anchor='mm')
    sh.text((cx, 690), 'For the man who has stopped explaining himself.', font('cormorant-garamond-400-italic', 25), 'e8dcc0', anchor='mm')
    sh.text((cx, 728), 'HALIFAX-ISH SINCE 1820   ·   SMILE', font('barlow-condensed-400', 13), '8a9ab0', anchor='mm', track=3)
    im = age(sh.done(), 41, sun=0.3, yellow=0.25, fox=0.5, creases=[('h', 0.5)], pins=[(0.03, 0.02), (0.97, 0.02)],
             tape=[(0.06, 0.97, 50, 16, -20)], torn=0.3, grime=0.45)
    save(im, 'teeth')


def cokanee(w=500, h=750):
    """COKANEE: the glacier, and a line of white along the ridge."""
    sh = Sheet(w, h, 'cfe6f2')
    for i in range(30):
        y = i * 18
        t = i / 30
        c = np.array(rgb('6aa8d0')[:3]) * (1 - t) + np.array(rgb('dceef6')[:3]) * t
        sh.rect(0, y, w, y + 19, '%02x%02x%02x' % tuple(int(v) for v in c))
    # the range: one long sharp ridge, and along the very top of it, a single fine line of white
    ridge = [(0, 420), (60, 360), (120, 390), (190, 250), (250, 300), (300, 210), (360, 290), (420, 260), (500, 330)]
    sh.poly(ridge + [(500, 560), (0, 560)], '3a6a8e')
    sh.poly([(x, y + 16) for x, y in ridge] + [(500, 560), (0, 560)], '2a5476')
    sh.line(ridge, 'ffffff', 5)
    # the can, standing in the snow, sweating
    sh.rect(0, 540, w, h, 'eef6fa')
    sh.rect(190, 400, 310, 600, '2a7ab8', '1a4a72', 3)
    sh.ellipse(190, 388, 310, 412, 'c8d4dc', '8a9aa6', 2)
    sh.text((250, 500), 'C', font('archivo-black-400', 70), 'eef6fa', anchor='mm')
    for k in range(9):
        x = 200 + (k * 37) % 100
        y = 430 + (k * 53) % 150
        sh.ellipse(x, y, x + 5, y + 8, 'cfe6f2')
    sh.text((w / 2, 74), 'COKANEE', font('archivo-black-400', 64), '17405e', anchor='mm', track=4)
    sh.text((w / 2, 128), 'Mountain fresh. Legally.', font('cormorant-garamond-400-italic', 32), '17405e', anchor='mm')
    sh.text((w / 2, 660), 'GLACIER LAGER', font('barlow-condensed-600', 30), '17405e', anchor='mm', track=8)
    sh.text((w / 2, 700), 'Filtered through the Kootenays.  The Kootenays deny everything.', font('barlow-condensed-400', 15), '4a6a80', anchor='mm')
    sh.text((w / 2, 728), 'Do not snort.', font('barlow-condensed-400', 11), '8aa0b0', anchor='mm')
    im = age(sh.done(), 42, sun=0.45, yellow=0.25, fox=0.4, creases=[('v', 0.5), ('h', 0.5)],
             pins=[(0.03, 0.02), (0.97, 0.02), (0.03, 0.98), (0.97, 0.98)], torn=0.2, grime=0.3)
    save(im, 'cokanee')


def hockey(w=400, h=560):
    """HOCKEY NIGHT AT THE SOV, the house's own, run off at the print shop."""
    sh = Sheet(w, h, 'f2ead2')
    sh.rect(0, 0, w, 150, 'a8281e')
    sh.text((w / 2, 52), 'HOCKEY', font('anton-400', 70), 'f2ead2', anchor='mm', track=4)
    sh.text((w / 2, 118), 'NIGHT AT THE SOV', font('anton-400', 34), 'f2ead2', anchor='mm', track=2)
    # a stick and a puck, as the print shop's clip art had them
    sh.poly([(110, 330), (290, 190), (300, 202), (130, 344)], '7a5a3a', '3a2a1a', 2)
    sh.poly([(100, 326), (140, 346), (130, 362), (80, 352)], '3a2a1a')
    sh.ellipse(240, 320, 300, 344, '1a1814')
    sh.text((w / 2, 410), 'WINGS 35¢', font('anton-400', 52), 'a8281e', anchor='mm')
    sh.text((w / 2, 458), 'Every game. Even those ones.', font('barlow-condensed-600', 24), '1a1814', anchor='mm')
    sh.text((w / 2, 500), 'Big screen  ·  Bigger regrets  ·  No fighting (in here)', font('barlow-condensed-400', 15), '3a3a34', anchor='mm')
    im = sh.done()
    mk = _layer(w, h)
    mk.text((300, 540), 'NO OILERS JERSEYS', font('kalam-400', 22), '16121a', anchor='mm', rot=6)
    mk.line([(84, 410), (316, 410)], '16121a', 2)
    mk.text((w / 2, 380), '60¢', font('kalam-400', 30), '16121a', anchor='mm', rot=-8)
    im.alpha_composite(mk.done())
    im = age(im, 43, sun=0.2, yellow=0.35, fox=0.3, grime=0.5, tape=[(0.08, 0.04, 44, 14, -25), (0.92, 0.04, 44, 14, 25)])
    save(im, 'hockey')


def zero(w=300, h=420):
    """BOORS ZERO, summer 2031: not out yet, and already thirty years in the sun."""
    sh = Sheet(w, h, 'e8f0f4')
    sh.rect(0, 0, w, 120, '1f3a6a')
    sh.text((w / 2, 50), 'BOORS', font('archivo-black-400', 54), 'eef3f6', anchor='mm')
    sh.text((w / 2, 96), 'Z E R O', font('barlow-condensed-600', 30), 'c9d3da', anchor='mm')
    # the can: blank, white, a zero on it
    sh.rect(110, 150, 190, 300, 'f6f8fa', 'aab6c0', 2)
    sh.ellipse(110, 142, 190, 158, 'c8d4dc')
    sh.ellipse(128, 196, 172, 256, None, '1f3a6a', 5)
    sh.text((w / 2, 330), 'NEW!  Now with zero.', font('anton-400', 26), '1f3a6a', anchor='mm')
    sh.text((w / 2, 362), 'No alcohol. No barley. No water.', font('barlow-condensed-400', 15), '3a4a5a', anchor='mm')
    sh.text((w / 2, 382), 'Contains Boors.', font('barlow-condensed-400', 15), '3a4a5a', anchor='mm')
    sh.text((w / 2, 406), 'AVAILABLE SUMMER 2031', font('barlow-condensed-600', 13), '1f3a6a', anchor='mm', track=3)
    im = age(sh.done(), 44, sun=0.4, yellow=0.5, fox=0.7, creases=[('h', 0.5)], pins=[(0.04, 0.03), (0.96, 0.03)], torn=0.5, grime=0.6)
    save(im, 'zero')


def clam(w=360, h=240):
    """CLAM-A-LOT, the table tents: the front and the back, one picture each."""
    def face(name, lines, seed):
        sh = Sheet(w, h, 'b8281e')
        sh.rect(8, 8, w - 8, h - 8, None, 'f2d27a', 3)
        for (t, f, sz, col, y) in lines:
            sh.text((w / 2, y), t, font(f, sz), col, anchor='mm')
        if seed == 1:
            # the celery, up out of the glass's rim
            sh.poly([(300, 150), (316, 60), (324, 62), (310, 152)], '8ac04a', '4a7a2a', 2)
            sh.blob([(306, 70), (296, 40), (316, 34), (332, 50), (322, 70)], '6aa03a', '4a7a2a', 2)
            sh.poly([(270, 150), (340, 150), (330, 214), (280, 214)], 'd84a3a', 'f2d27a', 2)
        im = age(sh.done(), 45 + seed, sun=0.1, yellow=0.2, fox=0.2, grime=0.7)
        # rings and a splash where a glass was put on it
        d = ImageDraw.Draw(im)
        r = np.random.default_rng(seed)
        cx, cy = r.uniform(60, 300), r.uniform(60, 180)
        d.ellipse([cx - 44, cy - 44, cx + 44, cy + 44], outline=(90, 40, 20, 120), width=3)
        save(im, name)
    face('clam_a', [('CLAM-A-LOT', 'anton-400', 50, 'f2d27a', 60), ('THE CAESAR', 'barlow-condensed-600', 30, 'f6efe0', 110),
                    ("Canada's national cocktail", 'cormorant-garamond-400-italic', 22, 'f6efe0', 150),
                    ('and only defence.', 'cormorant-garamond-400-italic', 22, 'f6efe0', 176), ('$6.50', 'anton-400', 26, 'f2d27a', 212)], 1)
    face('clam_b', [('ASK ABOUT', 'barlow-condensed-600', 34, 'f6efe0', 64), ('OUR WINGS', 'anton-400', 52, 'f2d27a', 116),
                    ("(don't)", 'kalam-400', 34, 'f6efe0', 178)], 2)


# ---------------------------------------------------------------------------------- the strange ones

def _oil(im, k=5, cracks=0.5, seed=0, varnish='c89a50', yellow=0.25):
    """A picture as an old oil: smeared to strokes, the varnish yellowed over it, cracked."""
    im = im.convert('RGB')
    w0, h0 = im.size
    im = im.resize((max(1, w0 // 2), max(1, h0 // 2)), Image.LANCZOS).filter(ImageFilter.MedianFilter(k | 1))
    im = im.resize((w0, h0), Image.BICUBIC).filter(ImageFilter.MedianFilter(3))
    a = np.asarray(im, dtype=np.float32) / 255.0
    h, w = a.shape[:2]
    # brush: a little directional noise, as strokes
    n = noise(h, w, 3, seed)
    a = a * (0.92 + 0.12 * n[..., None])
    v = np.array(rgb(varnish)[:3]) / 255.0
    a = a * (1 - yellow) + a * v * yellow * 1.6
    a = np.clip(a * 0.94 + 0.02, 0, 1)
    out = Image.fromarray((a * 255).astype(np.uint8))
    # craquelure: a net of fine dark lines
    d = ImageDraw.Draw(out)
    r = np.random.default_rng(seed + 9)
    for _ in range(int(cracks * w * h / 4000)):
        x, y = r.uniform(0, w), r.uniform(0, h)
        pts = [(x, y)]
        ang = r.uniform(0, 6.3)
        for _ in range(3):
            ang += r.uniform(-0.8, 0.8)
            x += math.cos(ang) * r.uniform(3, 7)
            y += math.sin(ang) * r.uniform(3, 7)
            pts.append((x, y))
        d.line(pts, fill=(60, 44, 28), width=1)
    return out


def founder(w=500, h=650):
    """R. H. SOVEREIGN, PROPRIETOR: the founder in his frock coat, and where his face is, a disc of
    black, polished, that shows the room."""
    sh = Sheet(w, h, '2a1c12')
    cx = w / 2
    # the dark of the studio, warmer behind him
    sh.ellipse(cx - 260, 40, cx + 260, 560, '3a2818')
    # the coat: shoulders, lapels, the waistcoat, the watch chain
    sh.blob([(cx - 210, h), (cx - 200, 430), (cx - 120, 360), (cx - 40, 345), (cx + 40, 345), (cx + 120, 360),
             (cx + 200, 430), (cx + 210, h)], '141010', '0a0806', 3)
    sh.poly([(cx - 40, 345), (cx, 470), (cx + 40, 345)], 'efe6d0')
    sh.poly([(cx - 22, 360), (cx, 420), (cx + 22, 360)], '1a1210')
    sh.poly([(cx - 40, 345), (cx - 70, 470), (cx - 8, 560)], '221a16', '0a0806', 2)
    sh.poly([(cx + 40, 345), (cx + 70, 470), (cx + 8, 560)], '221a16', '0a0806', 2)
    sh.blob([(cx - 60, 560), (cx - 20, 590), (cx + 30, 580), (cx + 70, 555)], None, 'c8a040', 3, closed=False)
    sh.ellipse(cx + 64, 548, cx + 80, 564, 'd8b050')
    # the hands, folded, on a cane's head
    sh.blob([(cx - 60, 610), (cx - 30, 590), (cx + 30, 592), (cx + 60, 612), (cx + 20, 630), (cx - 20, 630)], 'd8b494', '6a4a30', 2)
    sh.rect(cx - 6, 618, cx + 6, h, '3a2a1a')
    # the neck, the collar, and the face: a disc, perfectly round, perfectly black
    sh.rect(cx - 34, 300, cx + 34, 350, 'c89a78')
    sh.ellipse(cx - 92, 130, cx + 92, 330, '050505')
    # the room in it, faint: a window's light curved round its edge, a lamp
    sh.blob([(cx - 70, 170), (cx - 84, 230), (cx - 70, 290)], None, '3a3430', 6, closed=False)
    sh.ellipse(cx + 28, 168, cx + 44, 184, '6a5a4a')
    im = _oil(sh.done(), k=5, cracks=0.8, seed=51, yellow=0.3)
    im = age(im, 51, sun=0.0, yellow=0.1, fox=0.0, grime=0.5)
    save(im, 'founder')


def room1952(w=720, h=480):
    """The room, painted in 1952 from the back by the pool table, toward the door. Empty, the chairs
    still out, and in the door, a man the size of the door. Painted from a render of the room as it is
    (the eye picture of shots_dressing.gd's src_1952)."""
    src = Image.open(ROOM_SRC).convert('RGB')
    # the panel's frame: the part of the view with the door in it and nobody close
    im = src.crop(SRC_CROP).resize((w, h), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float32) / 255.0
    # lifted out of the dark the way a painter lifts it, warmer
    a = np.clip(a * 1.45 + 0.03, 0, 1) ** 0.95
    a = a * np.array([1.0, 0.9, 0.72])
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
    # a door in the far wall that the room hasn't got, open on somewhere lit, and the man in it, dark,
    # square-shouldered, filling it, his edges caught by the light behind him
    d = ImageDraw.Draw(im)
    x0, x1 = int(w * DOOR_IN_PIC[0]), int(w * (DOOR_IN_PIC[0] + 0.105))
    y0, y1 = int(h * DOOR_IN_PIC[1]), int(h * (DOOR_IN_PIC[1] + DOOR_IN_PIC[2]))
    d.rectangle([x0 - 5, y0 - 5, x1 + 5, y1], fill=(58, 34, 20))
    for k in range(y1 - y0):
        t = k / (y1 - y0)
        d.line([(x0, y0 + k), (x1, y0 + k)], fill=(int(250 - 40 * t), int(214 - 50 * t), int(150 - 60 * t)))
    cx = (x0 + x1) / 2
    W = (x1 - x0)
    head_r = W * 0.17
    hy = y0 + W * 0.3
    man = [(x0 + W * 0.04, y1), (x0 + W * 0.05, hy + W * 0.55), (x0 + W * 0.12, hy + W * 0.3),
           (cx - W * 0.12, hy + W * 0.2), (cx + W * 0.12, hy + W * 0.2), (x1 - W * 0.12, hy + W * 0.3),
           (x1 - W * 0.05, hy + W * 0.55), (x1 - W * 0.04, y1)]
    rim = Image.new('L', im.size, 0)
    rd = ImageDraw.Draw(rim)
    rd.polygon(man, fill=255)
    rd.ellipse([cx - head_r, hy - head_r * 1.2, cx + head_r, hy + head_r * 1.1], fill=255)
    glow = rim.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(2))
    im.paste((255, 226, 170), (0, 0), glow.point(lambda v: v * 0.8))
    im.paste((20, 14, 10), (0, 0), rim)
    im = _oil(im, k=7, cracks=0.4, seed=52, yellow=0.35)
    # the signature, bottom right, and the year
    sig = _layer(w, h)
    sig.text((w - 70, h - 22), 'E. M. 1952', font('kalam-300', 18), '2a1a10', anchor='mm', rot=3)
    im = im.convert('RGBA')
    im.alpha_composite(sig.done())
    save(age(im, 52, sun=0.0, yellow=0.15, fox=0.0, grime=0.4), 'room1952')


SRC_CROP = (100, 200, 580, 520)      # the part of the src_1952 eye picture (838 x 720) it's painted from
DOOR_IN_PIC = (0.36, 0.26, 0.48)     # where the door falls in that, and how tall the man in it is


def velvet(w=420, h=620):
    """On black velvet: the woman on the stool from behind, looking back over her shoulder. The
    paint only where the light is; everywhere else, the velvet."""
    g = Image.open(os.path.join(WORK, 'girl_velvet.png')).convert('RGBA')
    g = g.crop(g.getbbox())
    g = g.crop((0, 0, g.width, int(g.height * 0.7)))
    sc = min((w - 60) / g.width, (h - 50) / g.height)
    g = g.resize((int(g.width * sc), int(g.height * sc)), Image.LANCZOS)
    a = np.asarray(g, dtype=np.float32) / 255.0
    rgbc, al = a[..., :3], a[..., 3:]
    # the seams in her skin where the bikini was: smoothed out of the light
    lum = (rgbc * [0.3, 0.59, 0.11]).sum(-1)
    lum = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(9)).filter(ImageFilter.GaussianBlur(2.2)), dtype=np.float32) / 255.0
    # the palette of a velvet painting: black, a hot amber, a rose, a cream at the very top
    t = np.clip((lum - 0.18) / 0.7, 0, 1)
    stops = [(0.0, (0.0, 0.0, 0.0)), (0.25, (0.38, 0.08, 0.10)), (0.5, (0.86, 0.36, 0.20)), (0.75, (1.0, 0.7, 0.42)), (1.0, (1.0, 0.95, 0.8))]
    col = np.zeros_like(rgbc)
    for (t0, c0), (t1, c1) in zip(stops[:-1], stops[1:]):
        m = ((t >= t0) & (t <= t1))[..., None]
        k = ((t - t0) / (t1 - t0))[..., None]
        col = np.where(m, np.array(c0) * (1 - k) + np.array(c1) * k, col)
    # her hair: blue-black, the light along it blue
    hairm = (rgbc.max(-1) < 0.28)[..., None] & (al > 0.5)
    col = np.where(hairm, np.array([0.08, 0.12, 0.3]) * (0.4 + 2.2 * lum[..., None]), col)
    fig = Image.fromarray((np.concatenate([np.clip(col, 0, 1), al], -1) * 255).astype(np.uint8), 'RGBA')
    glow = fig.filter(ImageFilter.GaussianBlur(9))
    # the velvet: black with a nap, a little purple where the light catches it
    r = np.random.default_rng(61)
    base = np.zeros((h, w, 3), np.float32)
    nap = r.standard_normal((h, w)) * 0.012 + noise(h, w, 40, 61) * 0.025
    yy, xx = np.mgrid[0:h, 0:w]
    sheen = np.exp(-(((xx - w * 0.5) / (w * 0.7)) ** 2 + ((yy - h * 0.35) / (h * 0.6)) ** 2)) * 0.05
    base += (nap + sheen)[..., None] * np.array([0.6, 0.35, 0.9])
    canvas = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)).convert('RGBA')
    ox, oy = (w - fig.width) // 2, h - fig.height - 26
    gl = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gl.alpha_composite(glow, (ox, oy))
    gla = np.asarray(gl, dtype=np.float32) / 255.0
    cv = np.asarray(canvas, dtype=np.float32) / 255.0
    cv[..., :3] = np.clip(cv[..., :3] + gla[..., :3] * gla[..., 3:] * 0.35, 0, 1)
    canvas = Image.fromarray((cv * 255).astype(np.uint8), 'RGBA')
    canvas.alpha_composite(fig, (ox, oy))
    # a moon behind her, and the artist's name, in the paint's own amber
    d = ImageDraw.Draw(canvas)
    d.ellipse([w - 120, 40, w - 50, 110], fill=(230, 200, 150, 255))
    d.ellipse([w - 110, 34, w - 44, 100], fill=(6, 4, 10, 255))
    sig = _layer(w, h)
    sig.text((70, h - 16), 'Rocco', font('kalam-400', 20), 'd89a50', anchor='mm', rot=4)
    canvas.alpha_composite(sig.done())
    save(canvas, 'velvet')


def clock_back(n=512):
    """The hall's clock: a school's, SOVEREIGN across it. Its hands go the other way."""
    sh = Sheet(n, n, 'f4f2ea')
    c = n / 2
    sh.ellipse(4, 4, n - 4, n - 4, 'f4f2ea', '1a1814', 10)
    for k in range(60):
        a = k / 60 * 2 * math.pi
        r0 = n * 0.44 if k % 5 else n * 0.41
        sh.line([(c + math.sin(a) * r0, c - math.cos(a) * r0), (c + math.sin(a) * n * 0.465, c - math.cos(a) * n * 0.465)], '1a1814', 5 if k % 5 == 0 else 2)
    for k in range(12):
        a = k / 12 * 2 * math.pi
        sh.text((c + math.sin(a) * n * 0.34, c - math.cos(a) * n * 0.34), str(12 if k == 0 else k), font('archivo-black-400', 40), '1a1814', anchor='mm')
    sh.text((c, c - 74), 'SOVEREIGN', font('barlow-condensed-600', 26), '1a1814', anchor='mm', track=6)
    sh.text((c, c + 80), 'TIME, GENTLEMEN', font('barlow-condensed-400', 18), '6a6a60', anchor='mm', track=4)
    from dressing import round_face
    save(round_face(age(sh.done(), 62, sun=0.0, yellow=0.35, fox=0.3, grime=0.4)), 'clock_back')


# ---------------------------------------------------------------------------------- the layers

def scrawl(w=1400, h=500):
    """The hall wall by the phone, in pen and marker and key: what people write while they wait for
    a phone that doesn't ring, or for the washroom."""
    sh = _layer(w, h)
    k = lambda sz: font('kalam-400', sz)
    sh.text((200, 60), 'DARLENE  338-1979', k(34), '1a1a40', anchor='mm', rot=3)
    sh.text((220, 100), '(ask for the other Darlene)', k(21), '1a1a40', anchor='mm', rot=2)
    sh.text((640, 64), 'GARY IS A COWARD', font('anton-400', 42), '2a1414', anchor='mm', rot=-2)
    sh.text((720, 112), "no I'm not  - G.", k(25), '1a1814', anchor='mm', rot=-4)
    sh.text((1130, 52), 'rent in this town', font('archivo-black-400', 30), '2a3a6a', anchor='mm', rot=2)
    sh.text((1140, 92), 'is a hate crime', font('archivo-black-400', 30), '2a3a6a', anchor='mm', rot=2)
    sh.text((1200, 130), 'agreed', k(18), '1a1814', anchor='mm', rot=-6)
    sh.text((1260, 150), 'agreed', k(16), '6a1a14', anchor='mm', rot=4)
    # days sober, tallied, and then not
    x = 100
    for g in range(4):
        for i in range(4):
            sh.line([(x + i * 12, 220), (x + i * 12 + 2, 270)], '1a1814', 3)
        sh.line([(x - 6, 260), (x + 46, 228)], '1a1814', 3)
        x += 70
    sh.text((240, 304), 'days', k(24), '1a1814', anchor='mm', rot=-2)
    sh.line([(80, 245), (400, 250)], '8a1a14', 5)
    sh.text((640, 210), 'you are the main character', k(30), '1a1814', anchor='mm', rot=-1)
    sh.text((660, 246), '(of this hallway)', k(22), '1a1814', anchor='mm', rot=-1)
    sh.text((1110, 220), 'THIS PHONE DOESNT WORK', font('anton-400', 30), '1a1814', anchor='mm', rot=1)
    sh.text((1150, 258), 'neither does Kevin', k(24), '3a5a2a', anchor='mm', rot=-3)
    sh.text((1200, 290), "I'm on disability - Kevin", k(17), '1a1814', anchor='mm', rot=2)
    sh.text((300, 400), 'for a good time call your mother', k(24), '2a2a5a', anchor='mm', rot=-1)
    sh.text((340, 432), "she's lonely and she's been asking", k(18), '2a2a5a', anchor='mm', rot=-1)
    # a heart, keyed in, T + and the other letter scratched out to a smear
    sh.blob([(650, 450), (610, 390), (640, 365), (670, 395), (700, 365), (730, 390)], None, '6a6a60', 3)
    sh.text((656, 410), 'T +', font('archivo-black-400', 26), '6a6a60', anchor='mm')
    for j in range(14):
        sh.line([(685 + j % 4 * 3, 398 + j), (712 + j % 3 * 2, 418 - j)], '6a6a60', 2)
    sh.text((930, 360), 'a computer wrote this wall', k(22), '1a1814', anchor='mm', rot=2)
    sh.text((950, 392), "then whose hand is this", k(20), '4a1a5a', anchor='mm', rot=-2)
    sh.text((1040, 330), 'who put the lime in the helmet', k(17), '3a3a3a', anchor='mm', rot=1)
    # an eye, small, drawn very carefully, lower than anyone would look
    sh.ellipse(1210, 400, 1280, 440, None, '1a1814', 3)
    sh.ellipse(1234, 406, 1256, 434, '1a1814')
    sh.ellipse(1240, 412, 1246, 418, 'f4f2ea')
    sh.text((1245, 466), 'it hears you flush', k(18), '4a4a4a', anchor='mm', rot=0)
    im = sh.done()
    a = np.asarray(im, dtype=np.float32)
    # worn into the paint, not on it
    a[..., 3] *= 0.85 * (0.75 + 0.25 * noise(h, w, 6, 63))
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA'), 'scrawl')


def stickers(n=512):
    """Stickers, four to a sheet: the band's, the mill, the drinking line, the heart."""
    sh = _layer(n, n)
    q = n / 2
    def card(x, y, ground, border):
        sh.rect(x + 14, y + 40, x + q - 14, y + q - 40, ground, border, 3)
    card(0, 0, '1a1814', 'e8c84a')
    sh.text((q / 2, q / 2 - 22), 'THE', font('barlow-condensed-600', 22), 'e8c84a', anchor='mm')
    sh.text((q / 2, q / 2 + 12), 'DOWNSTROKES', font('anton-400', 34), 'e8c84a', anchor='mm')
    card(q, 0, '2a5a3a', 'f2ead2')
    sh.text((q + q / 2, q / 2 - 18), 'SAVE THE', font('barlow-condensed-600', 26), 'f2ead2', anchor='mm')
    sh.text((q + q / 2, q / 2 + 18), 'MILL', font('anton-400', 46), 'f2ead2', anchor='mm')
    card(0, q, 'f2ead2', '1a1814')
    sh.text((q / 2, q + q / 2 - 26), "HOW'S MY DRINKING?", font('barlow-condensed-600', 22), '1a1814', anchor='mm')
    sh.text((q / 2, q + q / 2 + 8), '1-800-MIND-YRS', font('anton-400', 30), 'a8281e', anchor='mm')
    card(q, q, 'f2ead2', 'a8281e')
    hx, hy = q + q / 2 + 26, q + q / 2 - 6
    sh.text((hx - 62, hy), 'I', font('anton-400', 46), '1a1814', anchor='mm')
    sh.ellipse(hx - 26, hy - 22, hx + 2, hy + 6, 'a8281e')
    sh.ellipse(hx - 2, hy - 22, hx + 26, hy + 6, 'a8281e')
    sh.poly([(hx - 25, hy - 2), (hx + 25, hy - 2), (hx, hy + 28)], 'a8281e')
    # somebody's keyed through the heart
    sh.line([(hx - 30, hy - 26), (hx + 28, hy + 30)], 'f2ead2', 4)
    sh.text((q + q / 2, q + q / 2 + 52), 'CAMPBELL RIVER', font('barlow-condensed-600', 22), '1a1814', anchor='mm')
    im = sh.done()
    im = age(im, 64, sun=0.3, yellow=0.2, fox=0.3, grime=0.6)
    # one file each, cut to what's printed, so each goes on a wall as its own paper
    for i in range(4):
        x, y = (i % 2) * n // 2, (i // 2) * n // 2
        c = im.crop((x, y, x + n // 2, y + n // 2))
        save(c.crop(c.getbbox()), 'stk_%d' % i)


def decals():
    """The marks: a glass's rings, a ceiling's water stain, heel scuffs, a nicotine cloud."""
    r = np.random.default_rng(65)
    # rings: a few overlapping, darker at their edge where it dried
    n = 256
    a = np.zeros((n, n, 4), np.float32)
    yy, xx = np.mgrid[0:n, 0:n]
    for (cx, cy, rr) in ((110, 120, 46), (150, 140, 44), (128, 96, 30)):
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        ring = np.exp(-((d - rr) / 2.2) ** 2) * (0.6 + 0.4 * noise(n, n, 8, int(cx))) + (d < rr) * 0.08
        a[..., 3] = np.maximum(a[..., 3], ring)
    a[..., :3] = np.array([0.22, 0.12, 0.05])
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), 'RGBA').save(os.path.join(OUT, 'dress_rings.png'))
    # the water stain: a tide-marked bloom, rings of brown at each edge it stopped at
    n = 512
    yy, xx = np.mgrid[0:n, 0:n]
    nz = noise(n, n, 60, 66) * 0.35 + noise(n, n, 18, 67) * 0.12
    d = np.sqrt(((xx - n / 2) / (n * 0.42)) ** 2 + ((yy - n / 2) / (n * 0.36)) ** 2) + nz
    al = np.zeros_like(d)
    for edge in (0.55, 0.75, 0.92):
        al = np.maximum(al, np.exp(-((d - edge) / 0.02) ** 2) * 0.8)
    al = np.maximum(al, (d < 0.92) * 0.22 * (1 - d))
    col = np.stack([np.full_like(d, 0.42), np.full_like(d, 0.3), np.full_like(d, 0.14)], -1)
    Image.fromarray((np.concatenate([col, al[..., None]], -1).clip(0, 1) * 255).astype(np.uint8), 'RGBA').save(os.path.join(OUT, 'dress_stain.png'))
    # scuffs: black heel marks, short curved strokes all one way
    sh = _layer(512, 512)
    for _ in range(70):
        x, y = r.uniform(20, 492), r.uniform(20, 492)
        ang = r.uniform(-0.6, 0.6)
        ln = r.uniform(10, 40)
        pts = [(x + math.cos(ang + t * 0.4) * ln * t, y + math.sin(ang + t * 0.4) * ln * t) for t in np.linspace(0, 1, 5)]
        sh.line(pts, '0e0c0a', int(r.uniform(2, 5)))
    im = sh.done()
    b = np.asarray(im, dtype=np.float32)
    b[..., 3] *= 0.7
    Image.fromarray(b.astype(np.uint8), 'RGBA').save(os.path.join(OUT, 'dress_scuffs.png'))
    # the nicotine: a yellow-brown cloud, thickest in the middle, where a table of them sat for thirty years
    n = 512
    yy, xx = np.mgrid[0:n, 0:n]
    d = np.sqrt(((xx - n / 2) / (n * 0.45)) ** 2 + ((yy - n / 2) / (n * 0.45)) ** 2) + noise(n, n, 50, 68) * 0.25
    al = np.clip(1 - d, 0, 1) ** 1.5 * 0.55
    col = np.stack([np.full_like(d, 0.55), np.full_like(d, 0.42), np.full_like(d, 0.16)], -1)
    Image.fromarray((np.concatenate([col, al[..., None]], -1).clip(0, 1) * 255).astype(np.uint8), 'RGBA').save(os.path.join(OUT, 'dress_nicotine.png'))
    for f in ('rings', 'stain', 'scuffs', 'nicotine'):
        print('textures/dress_' + f + '.png')


ALL = {'teeth': teeth, 'cokanee': cokanee, 'hockey': hockey, 'zero': zero, 'clam': clam,
       'founder': founder, 'room1952': room1952, 'velvet': velvet, 'clock_back': clock_back,
       'scrawl': scrawl, 'stickers': stickers, 'decals': decals}

if __name__ == '__main__':
    for k in sys.argv[1:] or ALL:
        ALL[k]()
