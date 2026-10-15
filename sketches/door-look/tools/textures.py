"""The room's surfaces, drawn in code: the carpet, the wood, the walls, the signs, and the photo on
the kid's phone. Each is a PNG in textures/. The press prints whatever colour a surface has in the
light it's in, so these are drawn in the room's real colours, not in the inks: a maroon carpet
prints red and night, gold motifs print amber, the cream of a card prints as bare paper.

  python3 tools/textures.py

The tiling ones (carpet, wood, panel, plaster) repeat seamlessly both ways: their noise is made
periodic by filtering it in the frequency domain, and their motifs are drawn with wraparound.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'textures')
FONTS = os.path.join(HERE, 'fonts')
rng = np.random.default_rng(1974)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name + '.ttf'), size)


def hexc(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


def noise(n, scale, aniso=(1.0, 1.0), seed=None):
    """Periodic noise, n x n, with features about `scale` px across (stretched by aniso), -1..1."""
    r = np.random.default_rng(seed) if seed is not None else rng
    w = r.standard_normal((n, n))
    fy = np.fft.fftfreq(n)[:, None] * aniso[1]
    fx = np.fft.fftfreq(n)[None, :] * aniso[0]
    f = np.sqrt(fx * fx + fy * fy) * scale
    spec = np.fft.fft2(w) * np.exp(-(f ** 2) * 4.0)
    out = np.real(np.fft.ifft2(spec))
    out -= out.mean()
    return out / (np.abs(out).max() + 1e-9)


def save(a, name):
    os.makedirs(OUT, exist_ok=True)
    a = np.clip(a, 0, 1)
    mode = 'RGBA' if a.shape[2] == 4 else 'RGB'
    Image.fromarray((a * 255 + 0.5).astype(np.uint8), mode).save(os.path.join(OUT, name + '.png'))
    print('textures/' + name + '.png', a.shape[1], 'x', a.shape[0])


def mix(a, b, t):
    t = np.asarray(t)[..., None] if np.ndim(t) else t
    return a * (1 - t) + b * t


# ------------------------------------------------------------------------------------ the carpet

def carpet(n=512):
    """The pub's carpet, one repeat to 0.9 m: an old hotel pattern, a maroon ground with a navy
    trellis, gold rosettes where it crosses and a small gold lozenge in each diamond, worn and
    trodden. (The floor in front of the bar is worn to the backing: that's done in the scene.)"""
    ground, navy, gold, cream = hexc('#4a2224'), hexc('#1e2640'), hexc('#b58a3e'), hexc('#d8c7a0')
    img = Image.new('L', (n, n), 0)
    lat = Image.new('L', (n, n), 0)
    ros = Image.new('L', (n, n), 0)
    loz = Image.new('L', (n, n), 0)
    dl, dr, dz = ImageDraw.Draw(lat), ImageDraw.Draw(ros), ImageDraw.Draw(loz)
    cell = n // 2
    for ox in (-n, 0, n):
        for oy in (-n, 0, n):
            # the trellis: diagonals through the cell corners
            for k in range(-4, 5):
                x0 = ox + k * cell
                dl.line([(x0, oy), (x0 + n, oy + n)], fill=255, width=9)
                dl.line([(x0 + n, oy), (x0, oy + n)], fill=255, width=9)
            for cx in range(0, n + 1, cell):
                for cy in range(0, n + 1, cell):
                    x, y = ox + cx, oy + cy
                    # a rosette where the trellis crosses: eight petals round a navy eye
                    for i in range(8):
                        a = i * np.pi / 4
                        px, py = x + np.cos(a) * 30, y + np.sin(a) * 30
                        dr.ellipse([px - 17, py - 17, px + 17, py + 17], fill=255)
                    dr.ellipse([x - 24, y - 24, x + 24, y + 24], fill=255)
                    # in the middle of each diamond, a small lozenge and four dots
                    mx, my = x + cell // 2, y + cell // 2
                    dz.polygon([(mx, my - 26), (mx + 16, my), (mx, my + 26), (mx - 16, my)], fill=255)
                    for (ddx, ddy) in ((0, -46), (46, 0), (0, 46), (-46, 0)):
                        dz.ellipse([mx + ddx - 6, my + ddy - 6, mx + ddx + 6, my + ddy + 6], fill=255)
    eye = Image.new('L', (n, n), 0)
    de = ImageDraw.Draw(eye)
    for ox in (-n, 0, n):
        for oy in (-n, 0, n):
            for cx in range(0, n + 1, cell):
                for cy in range(0, n + 1, cell):
                    de.ellipse([ox + cx - 11, oy + cy - 11, ox + cx + 11, oy + cy + 11], fill=255)
    soften = lambda im: np.asarray(im.filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255.0
    L, Rz, Z, E = soften(lat), soften(ros), soften(loz), soften(eye)
    # the pile: the colours bleed a little, the tufts break every edge
    tuft = noise(n, 1.5) * 0.5 + noise(n, 5) * 0.5
    edge = lambda m: np.clip((m - 0.5 + tuft * 0.18) * 3 + 0.5, 0, 1)
    a = np.broadcast_to(ground, (n, n, 3)).copy()
    a = mix(a, navy, edge(L))
    a = mix(a, gold, edge(Rz))
    a = mix(a, navy, edge(E))
    a = mix(a, gold * 0.92, edge(Z))
    # wear: trodden darker in drifts, a few pale specks of whatever got dropped
    wear = noise(n, 90) * 0.5 + noise(n, 30) * 0.3
    a *= (0.9 + 0.12 * wear)[..., None]
    specks = rng.random((n, n)) > 0.9985
    a[specks] = cream * 0.8
    a *= (1.0 + 0.07 * noise(n, 1.2))[..., None]
    save(a, 'carpet')


def wear(ppm=32):
    """Where the carpet's been walked flat, as a map of the room from above: x 0..16 m across, z
    0..10 m down (the back wall at the top, the front wall and the door at the bottom), 0 none, 1
    worn to the backing. Worst past the door mat, where everyone steps off it, and along the bar,
    where they stand; a lane to the washrooms, a ring round the pool table, a fainter way to 28."""
    W, H = 16 * ppm, 10 * ppm
    im = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(im)
    P = lambda x, z: (x * ppm, z * ppm)
    def lane(pts, width, value):
        layer = Image.new('L', (W, H), 0)
        ImageDraw.Draw(layer).line([P(*q) for q in pts], fill=value, width=int(width * ppm), joint='curve')
        for q in pts:
            r = width * ppm / 2
            ImageDraw.Draw(layer).ellipse([q[0] * ppm - r, q[1] * ppm - r, q[0] * ppm + r, q[1] * ppm + r], fill=value)
        return layer
    layers = [
        lane([(3.2, 8.75), (3.0, 8.1), (2.9, 7.3)], 1.1, 255),              # stepping off the mat
        lane([(2.75, 7.6), (2.75, 1.4)], 0.8, 205),                         # along the bar
        lane([(2.55, 7.4), (2.55, 1.6)], 0.35, 235),                        # feet at the rail
        lane([(2.9, 3.2), (4.4, 1.6), (6.5, 0.4), (6.5, 0.0)], 0.75, 150),  # to the washrooms
        lane([(3.6, 8.3), (6.0, 8.9), (8.2, 8.6)], 0.7, 135),               # to 28
        lane([(3.2, 7.9), (6.0, 6.2), (8.0, 5.3)], 0.6, 140),               # to the pool table
        lane([(13.75, 2.0), (13.75, 2.6)], 0.45, 210),                      # the oche
        lane([(13.2, 0.3), (13.2, 1.3)], 0.6, 150),                         # the jukebox
    ]
    ring = Image.new('L', (W, H), 0)
    dr = ImageDraw.Draw(ring)
    cx, cz, hx, hz = 9.4, 3.9, 1.3 + 0.75, 0.72 + 0.75                     # the pool table and its players
    dr.rounded_rectangle([(cx - hx) * ppm, (cz - hz) * ppm, (cx + hx) * ppm, (cz + hz) * ppm], radius=int(0.6 * ppm), outline=150, width=int(0.55 * ppm))
    layers.append(ring)
    a = np.zeros((H, W), np.float32)
    for l in layers:
        a = np.maximum(a, np.asarray(l.filter(ImageFilter.GaussianBlur(0.3 * ppm)), np.float32) / 255.0)
    # it wears in patches, not in a smooth lane
    n = noise(W, 18)[:H, :W] * 0.6 + noise(W, 5)[:H, :W] * 0.4
    a = np.clip(a * (0.75 + 0.55 * n), 0, 1)
    a = np.clip((a - 0.12) / 0.88, 0, 1)
    Image.fromarray((a * 255 + 0.5).astype(np.uint8), 'L').save(os.path.join(OUT, 'wear.png'))
    print('textures/wear.png', W, 'x', H)


def tape(w=640, h=180):
    """A strip of masking tape on the wall by the door, the night's sum on it in marker: the
    birthday that makes you nineteen tonight (Wednesday 4 November 2026, content/data/props.yaml).
    RGBA: torn ends."""
    r = np.random.default_rng(1104)
    base = hexc('#e2d3a8')
    a = np.ones((h, w, 4), np.float32)
    a[..., :3] = base
    # the crepe of the paper: fine creases across the strip
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    crepe = noise(w, 1.5, (1.0, 6.0), seed=5)[:h, :w]
    a[..., :3] *= (0.96 + 0.05 * crepe)[..., None]
    a[..., :3] *= (0.97 + 0.05 * noise(w, 30, seed=6)[:h, :w])[..., None]
    # torn ends: ragged edges, the fibres a little see-through
    for side in (0, 1):
        edge = 22 + np.cumsum(r.normal(0, 3.0, h)) * 0.5
        edge = edge - edge.mean() + 24
        for y in range(h):
            e = int(np.clip(edge[y], 6, 44))
            if side == 0:
                a[y, :e, 3] = 0.0
                a[y, e:e + 4, 3] = 0.6
            else:
                a[y, w - e:, 3] = 0.0
                a[y, w - e - 4:w - e, 3] = 0.6
    # the marker, in a quick hand: each character on its own tilt
    ink = Image.new('L', (w, h), 0)
    f = font('barlow-condensed-600', 112)
    text = '19 = NOV 4 07'
    x = (w - sum(24 if ch == ' ' else f.getlength(ch) * 0.96 for ch in text)) / 2
    for ch in text:
        if ch == ' ':
            x += 24
            continue
        g = Image.new('L', (160, 200), 0)
        ImageDraw.Draw(g).text((20, 20), ch, font=f, fill=255)
        g = g.rotate(r.uniform(-7, 5), resample=Image.BICUBIC, center=(60, 100))
        ink.paste(255, (int(x - 20), int(-14 + r.uniform(-5, 5))), g)
        x += f.getlength(ch) * 0.96
    m = np.asarray(ink.filter(ImageFilter.GaussianBlur(1.6)), np.float32) / 255.0
    m = np.clip((m - 0.3) * 2.5, 0, 1)                                       # the felt tip's bleed
    a[..., :3] = mix(a[..., :3], hexc('#201d1b'), m * 0.94)
    save(a, 'tape_date')


# ------------------------------------------------------------------------------------ wood

def grain(n, base, dark, light, rings=18, stretch=12.0, seed=None):
    """Wood grain along x: long streaks, the rings wavering, knots here and there."""
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    warp = noise(n, 70, (stretch * 0.25, 1.0), seed=r.integers(1e9)) * 26 + noise(n, 18, (stretch * 0.5, 1.0), seed=r.integers(1e9)) * 3
    ring = np.sin((yy + warp) / n * np.pi * 2 * rings)
    ring = np.abs(ring) ** 0.6 * np.sign(ring)
    streak = noise(n, 2.5, (stretch, 1.0), seed=r.integers(1e9))
    t = np.clip(0.5 + 0.3 * ring + 0.3 * streak, 0, 1)
    a = mix(mix(dark, base, np.clip(t * 2, 0, 1)), light, np.clip(t * 2 - 1, 0, 1))
    a *= (1.0 + 0.05 * noise(n, 1.0, seed=r.integers(1e9)))[..., None]
    return a


def wood(n=512):
    """Old varnished fir for the bar front, the tables and the beams: honey gone brown."""
    a = grain(n, hexc('#7d5534'), hexc('#4a2e1b'), hexc('#9c7045'), rings=14, seed=11)
    save(a, 'wood')


def top(n=512):
    """The bar top and the table tops: darker, the varnish worn through where the elbows go,
    the rings of a thousand glasses."""
    a = grain(n, hexc('#5a3a22'), hexc('#2e1c10'), hexc('#7a5230'), rings=10, stretch=16, seed=12)
    im = Image.new('L', (n, n), 0)
    d = ImageDraw.Draw(im)
    for _ in range(14):
        x, y, rr = rng.integers(0, n), rng.integers(0, n), rng.integers(18, 30)
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.ellipse([x + ox - rr, y + oy - rr, x + ox + rr, y + oy + rr], outline=255, width=2)
    ringm = np.asarray(im.filter(ImageFilter.GaussianBlur(0.8)), dtype=np.float32) / 255.0
    a *= (1.0 - 0.28 * ringm)[..., None]
    wornm = np.clip(noise(n, 40) * 1.5 - 0.4, 0, 1)
    a = mix(a, a * 1.25 + 0.03, wornm * 0.6)
    save(a, 'top')


def panel(n=512):
    """The wainscot to the chair rail: tongue-and-groove boards, a hand's width each, dark stain.
    The boards run up and down (the texture's y is the wall's height)."""
    boards = 9
    a = grain(n, hexc('#5e3d27'), hexc('#35210f'), hexc('#77512f'), rings=6, stretch=10, seed=13)
    a = np.transpose(a, (1, 0, 2)).copy()          # the grain up the board
    xx = np.arange(n)[None, :].repeat(n, 0)
    bw = n / boards
    u = (xx % bw) / bw
    # each board a slightly different stain, the V-groove between them dark, a lit bevel beside it
    tone = rng.uniform(0.86, 1.1, boards)
    a *= tone[(xx // bw).astype(int) % boards][..., None]
    groove = np.clip(1 - np.minimum(u, 1 - u) * bw / 3.0, 0, 1)
    bevel = np.clip(1 - np.abs(u - 0.03) * bw / 2.0, 0, 1)
    a *= (1 - 0.8 * groove)[..., None]
    a += (0.08 * bevel)[..., None]
    save(a, 'panel')


def plaster(n=512):
    """The walls above the rail: plaster painted cream a long time ago, gone the yellow of
    everything that was smoked in here before the law changed; water-stained under the beams."""
    base = hexc('#cdbb8e')
    a = np.broadcast_to(base, (n, n, 3)).copy()
    a *= (1.0 + 0.05 * noise(n, 40) + 0.03 * noise(n, 6) + 0.02 * noise(n, 1.2))[..., None]
    stain = np.clip(noise(n, 70, seed=5) * 1.6 - 0.55, 0, 1)
    a = mix(a, a * np.array([0.82, 0.74, 0.6]), stain * 0.7)
    save(a, 'plaster')


# ------------------------------------------------------------------------------------ signs

def sign_id(w=420, h=560):
    """The card on the vestibule's screen, facing the door: the province's sign, and under it the
    house rule typed and laminated."""
    im = Image.new('RGB', (w, h), (236, 232, 222))
    d = ImageDraw.Draw(im)
    red = (178, 38, 30)
    ink = (29, 28, 25)
    d.rectangle([0, 0, w, 150], fill=red)
    f1 = font('archivo-black-400', 92)
    d.text((w / 2, 78), 'NO', font=f1, fill=(244, 238, 226), anchor='mm')
    f2 = font('archivo-black-400', 70)
    d.text((w / 2, 212), 'MINORS', font=f2, fill=ink, anchor='mm')
    d.line([(34, 262), (w - 34, 262)], fill=ink, width=4)
    f3 = font('barlow-condensed-600', 46)
    d.text((w / 2, 318), 'TWO PIECES OF ID', font=f3, fill=ink, anchor='mm')
    d.text((w / 2, 366), 'ONE WITH A PHOTO', font=f3, fill=ink, anchor='mm')
    f4 = font('ibm-plex-mono-500', 24)
    d.text((w / 2, 440), 'NO PHOTOCOPIES', font=f4, fill=ink, anchor='mm')
    d.text((w / 2, 474), 'NO PICTURES ON PHONES', font=f4, fill=ink, anchor='mm')
    d.text((w / 2, 508), 'NO EXCEPTIONS', font=f4, fill=ink, anchor='mm')
    a = np.asarray(im, dtype=np.float32) / 255.0
    # the laminate's gone cloudy at the corners, and it's been taped up more than once
    yy, xx = np.mgrid[0:h, 0:w]
    cloud = np.clip(noise(max(w, h), 40)[:h, :w] * 0.5 + 0.5, 0, 1) * 0.08
    a = a * (1 - cloud[..., None]) + cloud[..., None] * 0.9
    for (x0, y0) in ((0, 0), (w - 60, 0), (0, h - 34), (w - 60, h - 34)):
        a[y0:y0 + 34, x0:x0 + 60] = a[y0:y0 + 34, x0:x0 + 60] * 0.85 + np.array([0.8, 0.78, 0.66]) * 0.15
    save(a, 'sign_id')


def door_glass(w=512, h=1024):
    """The lettering on the outside of the main door's two leaves, gold leaf, to be read from the
    lot (so from his stool it's backwards): SOVEREIGN over PUB on the left leaf; on the right, the
    hours and a NO MINORS sticker, low. RGBA: the glass is clear where there's nothing."""
    gold = (206, 162, 84, 245)
    for side in ('left', 'right'):
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        if side == 'left':
            d.text((w / 2, 300), 'SOVEREIGN', font=font('anton-400', 84), fill=gold, anchor='mm')
            d.line([(84, 356), (w - 84, 356)], fill=gold, width=6)
            d.text((w / 2, 462), 'PUB', font=font('archivo-black-400', 150), fill=gold, anchor='mm')
        else:
            f = font('barlow-condensed-600', 40)
            d.text((w / 2, 300), 'OPEN 11 AM', font=f, fill=gold, anchor='mm')
            d.text((w / 2, 346), 'LAST CALL 12:30', font=f, fill=gold, anchor='mm')
            sx, sy, sw, sh = 150, 790, 212, 110
            d.rectangle([sx, sy, sx + sw, sy + sh], fill=(236, 232, 222, 250))
            d.rectangle([sx, sy, sx + sw, sy + 40], fill=(178, 38, 30, 250))
            d.text((sx + sw / 2, sy + 21), 'NO MINORS', font=font('archivo-black-400', 26), fill=(244, 238, 226, 255), anchor='mm')
            d.text((sx + sw / 2, sy + 76), '19+', font=font('archivo-black-400', 48), fill=(29, 28, 25, 255), anchor='mm')
        a = np.asarray(im, dtype=np.float32) / 255.0
        # the leaf has worn off the letters in flecks
        fleck = rng.random(a.shape[:2]) > 0.93
        a[..., 3] = np.where(fleck & (a[..., 3] > 0.5) & (a[..., 0] > 0.7) & (a[..., 2] < 0.5), a[..., 3] * 0.2, a[..., 3])
        save(a, 'door_glass_' + side)


# ------------------------------------------------------------------------------------ the phone

def licence_card(w, h):
    """His licence, as the browser build draws it (prototype/web/src/ui/props.js): the red band,
    the photo, the name, the fields; this one came out of a wet wallet."""
    im = Image.new('RGB', (w, h), (234, 229, 216))
    d = ImageDraw.Draw(im)
    s = w / 340.0
    band = int(34 * s)
    d.rectangle([0, 0, w, band], fill=(179, 38, 30))
    d.text((12 * s, band / 2 + 1), "DRIVER'S LICENCE", font=font('archivo-black-400', int(15 * s)), fill=(244, 238, 226), anchor='lm')
    d.text((w - 12 * s, band / 2 + 1), 'CLASS 7N', font=font('ibm-plex-mono-500', int(12 * s)), fill=(244, 238, 226), anchor='rm')
    # the photo: him at seventeen, no hood, straight on
    px0, py0, pw = int(12 * s), band + int(10 * s), int(88 * s)
    ph = int(pw * 5 / 4)
    d.rectangle([px0, py0, px0 + pw, py0 + ph], fill=(206, 200, 186))
    cx = px0 + pw / 2
    d.ellipse([cx - pw * 0.42, py0 + ph * 0.72, cx + pw * 0.42, py0 + ph * 1.35], fill=(92, 94, 100))    # t-shirt
    d.rectangle([cx - pw * 0.1, py0 + ph * 0.55, cx + pw * 0.1, py0 + ph * 0.8], fill=(176, 146, 124))  # neck
    d.ellipse([cx - pw * 0.24, py0 + ph * 0.16, cx + pw * 0.24, py0 + ph * 0.68], fill=(186, 154, 130))  # face
    d.chord([cx - pw * 0.27, py0 + ph * 0.1, cx + pw * 0.27, py0 + ph * 0.52], 180, 360, fill=(70, 52, 40))  # hair
    for ex in (-0.1, 0.1):
        d.ellipse([cx + pw * ex - 3 * s, py0 + ph * 0.4 - 2 * s, cx + pw * ex + 3 * s, py0 + ph * 0.4 + 2 * s], fill=(40, 30, 26))
    d.line([(cx - pw * 0.07, py0 + ph * 0.57), (cx + pw * 0.07, py0 + ph * 0.57)], fill=(120, 80, 70), width=max(1, int(2 * s)))
    # the fields
    fx = px0 + pw + int(14 * s)
    ink = (29, 28, 25)
    d.text((fx, band + int(12 * s)), 'MOFFAT', font=font('archivo-black-400', int(24 * s)), fill=ink, anchor='lt')
    d.text((fx, band + int(42 * s)), 'TYLER JAMES', font=font('work-sans-300', int(15 * s)), fill=ink, anchor='lt')
    for i, (k, v) in enumerate((('DOB', '2007-10-14'), ('EXP', '2030-10-14'), ('ISS', '2025-02-20'), ('HGT', '178 cm'))):
        y = band + int((72 + i * 17) * s)
        d.text((fx, y), k, font=font('ibm-plex-mono-500', int(10 * s)), fill=(106, 102, 92), anchor='lt')
        d.text((fx + int(36 * s), y - int(1 * s)), v, font=font('ibm-plex-mono-500', int(12 * s)), fill=ink, anchor='lt')
    d.text((fx, band + int(146 * s)), 'DL 7340218', font=font('ibm-plex-mono-500', int(12 * s)), fill=ink, anchor='lt')
    # his signature, a scrawl
    pts = [(fx + int(120 * s) + i * 6 * s, band + int(150 * s) + np.sin(i * 1.7) * 5 * s) for i in range(14)]
    d.line(pts, fill=ink, width=max(1, int(2 * s)))
    a = np.asarray(im, dtype=np.float32) / 255.0
    # wet: the laminate lifting in a tide line, a sheen across it
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    tide = np.clip(1 - np.abs((xx / w) * 0.6 + (yy / h) - 0.95 - 0.04 * np.sin(xx / w * 20)) * 30, 0, 1)
    a = a * (1 - 0.12 * tide[..., None])
    sheen = np.clip(1 - np.abs((xx / w) - (yy / h) * 0.5 - 0.35) * 6, 0, 1) ** 2
    a = a + 0.1 * sheen[..., None]
    return np.clip(a, 0, 1)


def phone_screen(w=256, h=560):
    """What's on his phone: the photo of his licence, taken on the kitchen table at home, open
    in the gallery. The status bar says 7:50 and six per cent, in red."""
    a = np.zeros((h, w, 3), dtype=np.float32)
    # the kitchen table: a laminate with a wood print, lit by the kitchen's overhead light
    tbl = grain(512, hexc('#8a6a48'), hexc('#5c4330'), hexc('#a4825c'), rings=9, stretch=14, seed=21)
    tbl = tbl[:h, :w] if h <= 512 else np.array(Image.fromarray((tbl * 255).astype(np.uint8)).resize((w, h)), dtype=np.float32) / 255.0
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    light = 1.05 - 0.45 * (((xx - w * 0.4) / w) ** 2 + ((yy - h * 0.35) / h) ** 2)
    photo = tbl * light[..., None]
    # a mug ring and crumbs
    im = Image.fromarray((np.clip(photo, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    d.ellipse([150, 70, 236, 156], outline=(70, 50, 36), width=3)
    for _ in range(18):
        x, y = rng.integers(10, w - 10), rng.integers(40, h - 40)
        d.ellipse([x, y, x + 3, y + 2], fill=(200, 180, 140))
    # the card, a little crooked, his thumb on its corner
    card = licence_card(340, 214)
    cim = Image.fromarray((card * 255).astype(np.uint8)).convert('RGBA')
    cim = cim.resize((236, 149), Image.LANCZOS).rotate(-7, expand=True, resample=Image.BICUBIC)
    shadow = Image.new('RGBA', cim.size, (0, 0, 0, 0))
    shadow.putalpha(cim.split()[3].point(lambda v: int(v * 0.45)))
    im = im.convert('RGBA')
    ox, oy = (w - cim.size[0]) // 2, int(h * 0.36)
    im.alpha_composite(shadow, (ox + 5, oy + 7))
    im.alpha_composite(cim, (ox, oy))
    d = ImageDraw.Draw(im)
    th = Image.new('RGBA', (60, 110), (0, 0, 0, 0))
    dt = ImageDraw.Draw(th)
    dt.rounded_rectangle([6, 0, 54, 120], radius=24, fill=(178, 140, 114, 255))
    dt.rounded_rectangle([14, 8, 46, 44], radius=13, fill=(206, 176, 156, 255))          # the nail
    th = th.rotate(38, expand=True, resample=Image.BICUBIC)
    im.alpha_composite(th, (ox + cim.size[0] - 70, oy + cim.size[1] - 58))
    # the gallery round it: black bars, the status bar, the arrows
    d.rectangle([0, 0, w, 34], fill=(10, 10, 12, 255))
    d.rectangle([0, h - 44, w, h], fill=(10, 10, 12, 255))
    f = font('ibm-plex-mono-500', 17)
    d.text((14, 17), '7:50', font=f, fill=(230, 230, 232, 255), anchor='lm')
    bx, by = w - 50, 10
    d.rectangle([bx, by, bx + 34, by + 15], outline=(230, 230, 232, 255), width=2)
    d.rectangle([bx + 34, by + 4, bx + 37, by + 11], fill=(230, 230, 232, 255))
    d.rectangle([bx + 3, by + 3, bx + 6, by + 12], fill=(236, 64, 52, 255))
    d.text((bx - 6, 17), '6%', font=font('ibm-plex-mono-500', 14), fill=(236, 64, 52, 255), anchor='rm')
    for i, x in enumerate((w * 0.2, w * 0.5, w * 0.8)):
        d.rounded_rectangle([x - 14, h - 32, x + 14, h - 12], radius=4, outline=(200, 200, 204, 255), width=2)
    a = np.asarray(im.convert('RGB'), dtype=np.float32) / 255.0
    save(a, 'phone_screen')


# ------------------------------------------------------------------------------------ the screens

def hockey(w=512, h=288):
    """What's on the TVs: the hockey, the broadcast's high side view. The rink's white, the blue
    lines and the red, the boards and the crowd dark over them, the score in the corner."""
    im = Image.new('RGB', (w, h), (18, 20, 28))
    d = ImageDraw.Draw(im)
    # the crowd: dark, speckled with faces and jerseys
    for _ in range(1400):
        x, y = rng.integers(0, w), rng.integers(0, int(h * 0.36))
        c = rng.choice([(60, 52, 48), (90, 70, 60), (140, 110, 90), (40, 44, 70), (150, 30, 30), (200, 200, 200)])
        d.rectangle([x, y, x + 2, y + 3], fill=tuple(int(v) for v in c))
    # the boards and the glass
    top, bot = int(h * 0.36), int(h * 0.97)
    d.rectangle([0, top - 4, w, top + 12], fill=(226, 224, 216))
    for i in range(0, w, 64):
        d.rectangle([i + 6, top - 1, i + 56, top + 9], fill=(rng.integers(40, 200), rng.integers(40, 120), rng.integers(40, 120)))
    # the ice, in perspective: wider at the bottom
    ice = [(-40, top + 12), (w + 40, top + 12), (w + 160, bot), (-160, bot)]
    d.polygon(ice, fill=(236, 240, 244))
    def lx(x_top, y):
        # a line across the ice that's at x_top along the far boards
        f = (y - (top + 12)) / (bot - top - 12)
        return w / 2 + (x_top - w / 2) * (1 + 0.55 * f)
    for xt, col, wd in ((w * 0.5, (200, 30, 30), 5), (w * 0.26, (40, 70, 170), 7), (w * 0.74, (40, 70, 170), 7)):
        d.line([(lx(xt, top + 12), top + 12), (lx(xt, bot), bot)], fill=col, width=wd)
    # faceoff circles
    for cx, cy in ((w * 0.5, h * 0.66), (w * 0.14, h * 0.78), (w * 0.86, h * 0.78)):
        d.ellipse([cx - 44, cy - 20, cx + 44, cy + 20], outline=(190, 40, 40), width=2)
    # the players: two teams, dark and white, and the puck
    for i in range(10):
        x, y = rng.uniform(40, w - 40), rng.uniform(top + 30, bot - 20)
        col = (24, 32, 70) if i % 2 else (230, 230, 230)
        s = 0.7 + 0.6 * (y - top) / (bot - top)
        d.ellipse([x - 5 * s, y - 20 * s, x + 5 * s, y - 10 * s], fill=(30, 30, 30))
        d.rectangle([x - 7 * s, y - 12 * s, x + 7 * s, y + 2 * s], fill=col)
        d.line([(x, y + 2 * s), (x - 4 * s, y + 12 * s)], fill=(30, 30, 30), width=max(1, int(3 * s)))
        d.line([(x, y + 2 * s), (x + 4 * s, y + 12 * s)], fill=(30, 30, 30), width=max(1, int(3 * s)))
        d.line([(x + 6 * s, y - 6 * s), (x + 20 * s, y + 10 * s)], fill=(140, 100, 60), width=max(1, int(2 * s)))
    d.ellipse([w * 0.55, h * 0.72, w * 0.55 + 4, h * 0.72 + 2], fill=(0, 0, 0))
    # the score in the corner
    d.rectangle([10, 10, 190, 38], fill=(12, 12, 16))
    f = font('barlow-condensed-600', 22)
    d.text((18, 24), 'HOME 2   AWAY 1', font=f, fill=(240, 240, 240), anchor='lm')
    d.rectangle([190, 10, 262, 38], fill=(190, 30, 30))
    d.text((226, 24), '2ND 12:41', font=font('barlow-condensed-600', 18), fill=(240, 240, 240), anchor='mm')
    a = np.asarray(im, dtype=np.float32) / 255.0
    # the scanlines of an old set, and its glass
    a *= (0.92 + 0.08 * (np.arange(h) % 3 == 0))[:, None, None]
    save(a, 'tv_hockey')


def news(w=512, h=288):
    """The other TV, on the news channel: the weather map, a rainfall warning for the east coast of
    the island tonight, the radar's rain lying along it, the lower third and the ticker."""
    r = np.random.default_rng(1104)
    im = Image.new('RGB', (w, h), (22, 52, 92))
    d = ImageDraw.Draw(im)
    # the island, lying north-west to south-east, the mainland's mountains on the right, the strait between
    island = [(-20, 40), (60, 22), (150, 60), (230, 118), (300, 176), (352, 232), (336, 262), (270, 250),
              (196, 210), (120, 170), (40, 128), (-20, 116)]
    d.polygon(island, fill=(96, 112, 88))
    main = [(260, -10), (w + 10, -10), (w + 10, 200), (470, 186), (430, 140), (380, 96), (320, 52)]
    d.polygon(main, fill=(88, 100, 84))
    # the radar: rain along the east coast, heaviest in the middle
    rain = Image.new('L', (w, h), 0)
    dr = ImageDraw.Draw(rain)
    for _ in range(90):
        t = r.uniform(0, 1)
        x, y = 70 + t * 250 + r.normal(0, 14), 60 + t * 170 + r.normal(0, 12) - 14
        rr = r.uniform(8, 22)
        dr.ellipse([x - rr, y - rr * 0.7, x + rr, y + rr * 0.7], fill=int(120 + 135 * np.exp(-((t - 0.5) / 0.22) ** 2)))
    ra = np.asarray(rain.filter(ImageFilter.GaussianBlur(5)), np.float32) / 255.0
    a = np.asarray(im, np.float32) / 255.0
    for lo, col in ((0.12, (0.25, 0.63, 0.31)), (0.4, (0.86, 0.78, 0.24)), (0.62, (0.8, 0.2, 0.16))):
        m = (ra > lo)[..., None]
        a = np.where(m, a * 0.25 + np.array(col) * 0.75, a)
    im = Image.fromarray((a * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    d.ellipse([228, 146, 236, 154], fill=(250, 250, 250))
    d.text((244, 150), '50-70 mm', font=font('barlow-condensed-600', 24), fill=(250, 250, 250), anchor='lm')
    # the channel's corner and the lower third
    d.rectangle([w - 92, 12, w - 12, 40], fill=(200, 36, 36))
    d.text((w - 52, 26), 'NEWS', font=font('archivo-black-400', 18), fill=(250, 246, 240), anchor='mm')
    d.rectangle([0, h - 86, 300, h - 56], fill=(200, 36, 36))
    d.text((12, h - 71), 'RAINFALL WARNING', font=font('archivo-black-400', 20), fill=(250, 246, 240), anchor='lm')
    d.rectangle([0, h - 56, w, h - 26], fill=(236, 234, 228))
    d.text((12, h - 41), 'EAST COAST OF THE ISLAND  ·  TONIGHT INTO THURSDAY', font=font('barlow-condensed-600', 22), fill=(24, 26, 34), anchor='lm')
    d.rectangle([0, h - 26, w, h], fill=(14, 18, 30))
    d.text((12, h - 13), 'FERRIES: THE 9:15 SAILING IS CANCELLED  ·  THE HIGHWAY: WATER OVER THE ROAD AT THE CREEK  ·', font=font('barlow-condensed-600', 16), fill=(220, 220, 226), anchor='lm')
    a = np.asarray(im, dtype=np.float32) / 255.0
    a *= (0.92 + 0.08 * (np.arange(h) % 3 == 0))[:, None, None]
    save(a, 'tv_news')


def keno(w=256, h=192):
    """The lottery screen on the bar that table 28 plays all afternoon: the draw board, twenty
    numbers lit out of eighty."""
    im = Image.new('RGB', (w, h), (10, 30, 24))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w, 30], fill=(20, 90, 60))
    d.text((w / 2, 15), 'DRAW 2291', font=font('barlow-condensed-600', 22), fill=(236, 240, 200), anchor='mm')
    lit = set(rng.choice(80, 20, replace=False).tolist())
    f = font('ibm-plex-mono-500', 12)
    for i in range(80):
        cx, cy = 14 + (i % 10) * 25, 44 + (i // 10) * 18
        on = i in lit
        if on:
            d.ellipse([cx - 9, cy - 8, cx + 9, cy + 8], fill=(236, 220, 90))
        d.text((cx, cy), str(i + 1), font=f, fill=(20, 20, 20) if on else (120, 170, 140), anchor='mm')
    save(np.asarray(im, dtype=np.float32) / 255.0, 'lotto')


def jukebox(w=512, h=368):
    """The wall jukebox's screen between songs: the most-played covers in a grid, the credit line
    along the bottom. The covers are only colour and shape at this distance."""
    im = Image.new('RGB', (w, h), (18, 16, 26))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w, 44], fill=(38, 30, 52))
    d.text((18, 22), 'MOST PLAYED HERE', font=font('barlow-condensed-600', 30), fill=(236, 226, 240), anchor='lm')
    d.text((w - 18, 22), '7:50', font=font('barlow-condensed-600', 30), fill=(236, 226, 240), anchor='rm')
    covers = [((196, 58, 44), 'band'), ((232, 196, 120), 'sun'), ((40, 70, 120), 'rings'),
              ((226, 222, 210), 'bar'), ((140, 40, 90), 'band'), ((60, 110, 90), 'sun'),
              ((236, 150, 60), 'rings'), ((30, 30, 34), 'bar')]
    cw, ch, gx, gy = 108, 108, 18, 62
    for i, (c, kind) in enumerate(covers):
        x, y = gx + (i % 4) * (cw + 16), gy + (i // 4) * (ch + 40)
        d.rectangle([x, y, x + cw, y + ch], fill=c)
        ink = (20, 18, 22) if sum(c) > 400 else (240, 232, 214)
        if kind == 'band':
            d.rectangle([x, y + ch * 0.62, x + cw, y + ch * 0.8], fill=ink)
        elif kind == 'sun':
            d.ellipse([x + 26, y + 20, x + cw - 26, y + ch - 32], fill=ink)
        elif kind == 'rings':
            for k in range(3):
                r = 14 + k * 12
                d.ellipse([x + cw / 2 - r, y + ch / 2 - r, x + cw / 2 + r, y + ch / 2 + r], outline=ink, width=4)
        else:
            d.rectangle([x + 16, y + 16, x + 30, y + ch - 16], fill=ink)
        d.rectangle([x, y + ch + 8, x + cw * 0.8, y + ch + 16], fill=(120, 112, 130))
        d.rectangle([x, y + ch + 22, x + cw * 0.5, y + ch + 28], fill=(80, 74, 90))
    d.rectangle([0, h - 44, w, h], fill=(214, 60, 120))
    d.text((w / 2, h - 22), 'CREDITS 0   ·   TAP YOUR CARD', font=font('barlow-condensed-600', 30), fill=(250, 240, 246), anchor='mm')
    save(np.asarray(im, dtype=np.float32) / 255.0, 'jukebox')


# ------------------------------------------------------------------------------------ the payphone

def hand(name):
    """One of the build's handwriting fonts (godot/fonts/*.woff2), as a TTF PIL can read."""
    import tempfile
    from fontTools.ttLib import TTFont
    out = os.path.join(tempfile.gettempdir(), name + '.ttf')
    if not os.path.exists(out):
        f = TTFont(os.path.join(HERE, '..', '..', '..', 'godot', 'fonts', name + '.woff2'))
        f.flavor = None
        f.save(out)
    return out


def phone_wall(w=960, h=800):
    """The wall round the dead payphone at the end of the back hall, 1.2 m wide and 1.0 high, 800
    px to the metre, the phone in the middle of it: ink only, and see-through between, so the
    plaster shows. Forty years of it (content/ink/hall.ink): phone numbers with names and without,
    a cab company's, TRUCK FOR SALE, a heart with two sets of initials and a third scratched in
    and scratched out again, and high up, where you'd have to reach, in faded marker, the meeting
    at the church hall. Thickest where a hand rests while the other holds the receiver. Every
    number that can be read is a 555-01 one, the numbers kept for made-up phone books.
    RGBA."""
    r = np.random.default_rng(1986)
    a = np.zeros((h, w, 4), np.float32)
    hand4, hand3 = hand('kalam-400'), hand('kalam-300')
    phone = (384, 272, 576, 608)                      # where the phone covers it, in px
    taken = [phone]                                   # what can still be read, and the phone

    def put(mask, colour, x, y, deg, weight=1.0, keep=False):
        """lay a mask of ink on the wall, its middle at x, y, turned deg"""
        m = mask.rotate(deg, resample=Image.BICUBIC, expand=True)
        x0, y0 = int(x - m.width / 2), int(y - m.height / 2)
        full = Image.new('L', (w, h), 0)
        full.paste(m, (x0, y0))
        t = np.asarray(full, np.float32) / 255.0 * weight
        a[..., :3] = mix(a[..., :3], hexc(colour), np.where(t > a[..., 3], 1.0, t))
        a[..., 3] = np.maximum(a[..., 3], t)
        if keep:
            taken.append((x0 + 6, y0 + 6, x0 + m.width - 6, y0 + m.height - 6))

    def free(x, y, mw, mh, pad=8):
        if x - mw / 2 < 10 or x + mw / 2 > w - 10 or y - mh / 2 < 10 or y + mh / 2 > h - 10:
            return False                                # it thins out before the edge, it doesn't stop at one
        return all(x + mw / 2 + pad < b[0] or x - mw / 2 - pad > b[2] or y + mh / 2 + pad < b[1] or y - mh / 2 - pad > b[3] for b in taken)

    def words(text, face, size, stroke=0):
        f = ImageFont.truetype(face, size)
        box = f.getbbox(text, stroke_width=stroke)
        m = Image.new('L', (box[2] - box[0] + 12, box[3] - box[1] + 12), 0)
        ImageDraw.Draw(m).text((6 - box[0], 6 - box[1]), text, font=f, fill=255, stroke_width=stroke, stroke_fill=255)
        return m

    def gone():
        """a line of writing nobody can read any more: made-up syllables, mostly"""
        out = []
        for k in range(r.integers(1, 4)):
            if r.random() < 0.15:
                out.append('555-01%02d' % r.integers(0, 100))
            else:
                out.append(''.join(r.choice(list('bdklmnprstv')) + r.choice(list('aeiou')) for _ in range(r.integers(1, 4))))
        return ' '.join(out)

    # the things that can still be read, first, so the rest goes round them
    put(words('TUESDAYS 7 PM.  UNITED CHURCH HALL.', hand4, 30, 1), '#7c776d', 470, 52, -1.5, keep=True)
    put(words('YOU ARE NOT THE ONLY ONE.', hand4, 30, 1), '#7c776d', 455, 96, -1.5, keep=True)
    put(words('TRUCK FOR SALE', hand4, 38, 1), '#201d1b', 748, 178, 3, keep=True)
    put(words('555-0172  obo', hand4, 30, 1), '#201d1b', 738, 224, 3, keep=True)
    put(words('CAB  555-0118', hand4, 30, 1), '#23315f', 190, 222, -6, keep=True)
    put(words('24 HRS', hand3, 22), '#23315f', 150, 258, -6, keep=True)
    for text, ink, face, size, x, y, deg in [
            ('SHELLY 555-0164', '#201d1b', hand4, 25, 200, 318, -4),
            ('Rick 555-0131', '#6b665d', hand3, 28, 185, 432, 7),
            ('Tina  555-0157', '#23315f', hand4, 27, 760, 470, -3),
            ('Mom', '#23315f', hand3, 26, 690, 600, 11)]:
        put(words(text, face, size), ink, x, y, deg, keep=True)
    # the heart, two sets of initials in it, and the third scratched in beside them and out again
    hm = Image.new('L', (200, 180), 0)
    d = ImageDraw.Draw(hm)
    t = np.linspace(0, 2 * np.pi, 120)
    hx = 16 * np.sin(t) ** 3
    hy = -(13 * np.cos(t) - 5 * np.cos(2 * t) - 2 * np.cos(3 * t) - np.cos(4 * t))
    d.line([(100 + 5.6 * u, 86 + 5.6 * v) for u, v in zip(hx, hy)] + [(100, 86 - 5.6 * 5)], fill=255, width=4, joint='curve')
    ink_in = words('K.T. + R.B.', hand4, 24)
    hm.paste(255, (100 - ink_in.width // 2, 70 - ink_in.height // 2), ink_in)
    put(hm, '#201d1b', 700, 352, -5, keep=True)
    sc = Image.new('L', (60, 44), 0)
    d = ImageDraw.Draw(sc)
    for stroke in [[(6, 8), (6, 30), (2, 36)], [(14, 36), (16, 36)],                 # a key's J,
                   [(24, 36), (26, 8), (36, 24), (46, 8), (50, 36)], [(54, 36), (56, 36)]]:   # and M
        d.line(stroke, fill=255, width=1)
    put(sc, '#5d5850', 838, 352, 4, keep=True)
    out = Image.new('L', (70, 52), 0)
    d = ImageDraw.Draw(out)
    for k in range(17):                                 # and gone over and over with the key
        d.line([(r.uniform(0, 8) + k * 3.6, r.uniform(2, 10)), (r.uniform(0, 8) + k * 3.6 + r.uniform(-5, 5), r.uniform(42, 50))], fill=255, width=1)
    put(out, '#55504a', 838, 352, 4)

    # numbers without names, at all angles, some crossed out with whatever was to hand
    for k in range(10):
        ink, face = [('#23315f', hand3), ('#6b665d', hand3), ('#201d1b', hand4)][k % 3]
        m = words('555-01%02d' % r.integers(0, 100), face, int(r.uniform(22, 29)))
        if k % 4 == 1:
            ImageDraw.Draw(m).line([(4, m.height * 0.55), (m.width - 4, m.height * 0.45)], fill=255, width=3)
        for tries in range(60):
            x, y = r.uniform(70, w - 70), float(np.clip(r.normal(440, 150), 150, h - 60))
            if free(x, y, m.width + 10, m.height + 10):
                put(m, ink, x, y, r.normal(0, 9), keep=True)
                break

    # and under all of it, the years: writing gone faint, thickest at the height of a hand
    for k in range(170):
        m = words(gone(), hand3, int(r.uniform(12, 17)))
        for tries in range(12):
            x, y = r.normal(480, 250), r.normal(430, 160)
            # fewer the further from the phone, and none right at the edge
            edge = min(x, w - x, y, h - y) / 90.0
            if r.random() < min(1.0, edge) and free(x, y, m.width * 0.8, m.height * 0.6, pad=0):
                put(m, ['#aaa498', '#9ea2a8', '#b1ab9f'][k % 3], x, y, r.normal(0, 6), r.uniform(0.8, 1.0))
                break

    a[..., 3] = np.where(a[..., 3] > 0.5, 1.0, a[..., 3])
    save(a, 'phone_wall')


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:                               # just the ones named: python3 tools/textures.py phone_wall
        for name in sys.argv[1:]:
            globals()[name]()
        sys.exit(0)
    carpet()
    wood()
    top()
    panel()
    plaster()
    sign_id()
    door_glass()
    phone_screen()
    hockey()
    news()
    keno()
    wear()
    tape()
    jukebox()
    phone_wall()
