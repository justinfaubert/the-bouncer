"""The set dressing's pictures: the beer posters, the signs, the corkboard's flyers, the Esso's
window, the beer clock's face, and the labels on the trash. Each is a PNG in textures/, named
dress_*.png, put up in the building by world/dressing.gd.

  python3 tools/dressing.py            (numpy, Pillow; fontTools + brotli to read the woff2 fonts)
  python3 tools/dressing.py boors      (only those)

The brands are made up, parodies that sound like what was in every bar in 1996: BOORS LIGHT,
MILDCAT (the regulars call it Shitty Kitty, and somebody's said so on the poster), LOCHNESS stout,
UNLUCKY LAGER, OLD MILDEW, LABUTT BLUE. No real trademark is on anything.

Drawn the way a screen-printed poster was: flat colours, an ink line, the registration a hair off,
then aged: sun-faded toward the window, yellowed, foxed, creased where it was folded in the tube,
pinholes and tape. Nothing is square. Claude's drafts, all of it.
"""
import math
import os
import sys
import tempfile

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'textures')
FONTS = os.path.join(HERE, '..', 'fonts')
SS = 3                                   # drawn at three times the size, then brought down: smooth edges
_font_cache = {}
_ttf_dir = os.path.join(tempfile.gettempdir(), 'last-call-fonts')


def font(name, size):
    """One of the game's fonts (fonts/*.woff2), at `size` px of the finished picture."""
    key = (name, size)
    if key in _font_cache:
        return _font_cache[key]
    os.makedirs(_ttf_dir, exist_ok=True)
    ttf = os.path.join(_ttf_dir, name + '.ttf')
    if not os.path.exists(ttf):
        from fontTools.ttLib import TTFont
        f = TTFont(os.path.join(FONTS, name + '.woff2'))
        f.flavor = None
        f.save(ttf)
    _font_cache[key] = ImageFont.truetype(ttf, int(size * SS))
    return _font_cache[key]


def rgb(h, a=255):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


class Sheet:
    """A picture being drawn, w x h in finished pixels; everything given in finished pixels."""

    def __init__(self, w, h, ground):
        self.w, self.h = w, h
        self.im = Image.new('RGBA', (w * SS, h * SS), rgb(ground))
        self.d = ImageDraw.Draw(self.im)
        self.rng = np.random.default_rng(abs(hash((w, h, ground))) % (2 ** 32))

    def s(self, pts):
        return [(x * SS, y * SS) for x, y in pts]

    def rect(self, x0, y0, x1, y1, fill, outline=None, width=0):
        self.d.rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=rgb(fill) if fill else None,
                         outline=rgb(outline) if outline else None, width=int(width * SS))

    def ellipse(self, x0, y0, x1, y1, fill, outline=None, width=0):
        self.d.ellipse([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=rgb(fill) if fill else None,
                       outline=rgb(outline) if outline else None, width=int(width * SS))

    def poly(self, pts, fill, outline=None, width=0):
        self.d.polygon(self.s(pts), fill=rgb(fill) if fill else None)
        if outline:
            self.line(pts + [pts[0]], outline, width)

    def line(self, pts, c, width):
        self.d.line(self.s(pts), fill=rgb(c), width=max(1, int(width * SS)), joint='curve')
        r = width * SS / 2.0
        for x, y in (pts[0], pts[-1]):
            self.d.ellipse([x * SS - r, y * SS - r, x * SS + r, y * SS + r], fill=rgb(c))

    def blob(self, pts, fill, outline=None, width=0, closed=True, n=14):
        """A smooth shape through the points (Catmull-Rom), filled and inked."""
        c = spline(pts, closed, n)
        if fill:
            self.d.polygon(self.s(c), fill=rgb(fill))
        if outline:
            self.line(c + ([c[0]] if closed else []), outline, width)

    def text(self, xy, s, f, fill, anchor='la', spacing=0, rot=0.0, stroke=0, stroke_fill=None, track=0.0):
        """Words; `track` adds letter spacing in px; `rot` tilts them about their anchor."""
        if rot == 0.0 and track == 0.0:
            self.d.text((xy[0] * SS, xy[1] * SS), s, font=f, fill=rgb(fill), anchor=anchor, spacing=spacing * SS,
                        stroke_width=int(stroke * SS), stroke_fill=rgb(stroke_fill) if stroke_fill else None)
            return
        # tracked or tilted: drawn on its own layer and pasted
        widths = [f.getlength(ch) + track * SS for ch in s]
        tw = int(sum(widths) + 4 * SS + stroke * 2 * SS)
        asc, desc = f.getmetrics()
        th = int(asc + desc + 4 * SS + stroke * 2 * SS)
        layer = Image.new('RGBA', (tw, th), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        x = 2 * SS + stroke * SS
        for ch, cw in zip(s, widths):
            ld.text((x, 2 * SS + stroke * SS), ch, font=f, fill=rgb(fill), stroke_width=int(stroke * SS),
                    stroke_fill=rgb(stroke_fill) if stroke_fill else None)
            x += cw
        ax = {'l': 0, 'm': 0.5, 'r': 1.0}[anchor[0]]
        ox, oy = tw * ax, th * 0.5
        if rot:
            layer = layer.rotate(rot, resample=Image.BICUBIC, expand=True)
            ox, oy = layer.width * ax, layer.height * 0.5
        self.im.alpha_composite(layer, (int(xy[0] * SS - ox), int(xy[1] * SS - oy)))

    def paste(self, other, x, y):
        self.im.alpha_composite(other.im, (int(x * SS), int(y * SS)))

    def done(self):
        return self.im.resize((self.w, self.h), Image.LANCZOS)


def spline(pts, closed=True, n=14):
    out = []
    m = len(pts)
    rng_ = range(m) if closed else range(m - 1)
    for i in rng_:
        p0 = pts[(i - 1) % m] if closed or i > 0 else pts[0]
        p1 = pts[i]
        p2 = pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if closed or i + 2 < m else pts[-1]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in (0, 1)))
    if not closed:
        out.append(pts[-1])
    return out


# ---------------------------------------------------------------------------------- the ageing

def noise(h, w, scale, seed):
    """Smooth noise, -1..1, features about `scale` px."""
    r = np.random.default_rng(seed)
    gh, gw = max(2, int(h / scale) + 2), max(2, int(w / scale) + 2)
    g = Image.fromarray(((r.random((gh, gw)) * 255)).astype(np.uint8), 'L').resize((w, h), Image.BICUBIC)
    return np.asarray(g, dtype=np.float32) / 127.5 - 1.0


def age(im, seed, sun=0.35, yellow=0.25, fox=0.5, creases=(), pins=(), tape=(), curl=None, grime=0.3, torn=0.0):
    """A picture, aged: faded by the sun (`sun`, more toward the top where the light got it),
    yellowed, foxed with brown spots, folded in the tube (creases: ('h'|'v', where 0..1)), pinholes
    and tape at its corners, grime from hands, edges torn (`torn`, eaten into the alpha)."""
    r = np.random.default_rng(seed)
    a = np.asarray(im.convert('RGBA'), dtype=np.float32) / 255.0
    h, w = a.shape[:2]
    c = a[..., :3]
    yy = np.linspace(0, 1, h)[:, None]
    # the sun takes the colour out first, the blues and reds before the blacks
    fade = sun * (0.65 + 0.35 * (1 - yy)) * (0.8 + 0.2 * noise(h, w, 120, seed + 1))[..., None].squeeze()
    lum = (c * [0.3, 0.55, 0.15]).sum(-1, keepdims=True)
    paper = np.array([0.93, 0.89, 0.78])
    c = c * (1 - fade[..., None]) + (lum * 0.35 + paper * 0.65) * fade[..., None]
    # yellowed, unevenly
    yl = yellow * (0.7 + 0.3 * noise(h, w, 90, seed + 2))
    c = c * (1 - yl[..., None] * 0.4) + np.array([0.78, 0.66, 0.42]) * yl[..., None] * 0.4
    # foxing: small brown spots, a cluster or two
    if fox > 0:
        n = int(fox * w * h / 9000)
        for _ in range(n):
            cx, cy = r.random() * w, r.random() * h
            rad = r.uniform(1.0, 5.0) * (1.6 if r.random() < 0.1 else 1.0)
            yv, xv = np.ogrid[:h, :w]
            d = np.sqrt((xv - cx) ** 2 + (yv - cy) ** 2)
            k = np.clip(1 - d / rad, 0, 1) ** 1.5 * r.uniform(0.15, 0.45)
            c = c * (1 - k[..., None]) + np.array([0.55, 0.38, 0.2]) * k[..., None]
    # grime: hands at the bottom corners, smoke at the top
    g = grime * np.clip(noise(h, w, 50, seed + 3) * 0.5 + 0.5, 0, 1) * (0.4 + 0.6 * np.maximum(yy ** 2, (1 - yy) ** 3))
    c = c * (1 - g[..., None] * 0.35)
    # creases: a bright ridge and a dark valley, with the ink cracked along them
    for kind, where in creases:
        if kind == 'h':
            pos = where * h + noise(1, w, 60, seed + 9)[0] * 2.0
            d = np.arange(h)[:, None] - pos[None, :]
        else:
            pos = where * w + noise(h, 1, 60, seed + 9)[:, 0] * 2.0
            d = np.arange(w)[None, :] - pos[:, None]
        ridge = np.exp(-(d - 1.2) ** 2 / 1.5) * 0.18 - np.exp(-(d + 0.8) ** 2 / 1.2) * 0.22
        crack = (np.abs(d) < 1.2) * (noise(h, w, 3, seed + 10) > 0.35) * 0.5
        c = c + ridge[..., None]
        c = c * (1 - crack[..., None]) + paper * crack[..., None]
    # small scratches through the ink
    for _ in range(int(w * h / 30000)):
        x0, y0 = r.random() * w, r.random() * h
        ang = r.uniform(0, math.pi)
        ln = r.uniform(6, 30)
        for t in np.linspace(0, 1, int(ln)):
            xi, yi = int(x0 + math.cos(ang) * ln * t), int(y0 + math.sin(ang) * ln * t)
            if 0 <= xi < w and 0 <= yi < h:
                c[yi, xi] = c[yi, xi] * 0.4 + paper * 0.6
    out = np.concatenate([np.clip(c, 0, 1), a[..., 3:4]], -1)
    # torn edges: nibbled into the alpha
    if torn > 0:
        e = noise(h, w, 6, seed + 4) * 0.5 + 0.5
        yv, xv = np.ogrid[:h, :w]
        edge = np.minimum(np.minimum(xv, w - 1 - xv), np.minimum(yv, h - 1 - yv)).astype(np.float32)
        out[..., 3] *= (edge > e * torn * 8.0)
    img = Image.fromarray((out * 255 + 0.5).astype(np.uint8), 'RGBA')
    d = ImageDraw.Draw(img)
    for (px, py) in pins:
        x, y = px * w, py * h
        d.ellipse([x - 1.6, y - 1.6, x + 1.6, y + 1.6], fill=(20, 16, 12, 255))
        d.ellipse([x - 4, y - 4, x + 4, y + 4], outline=(110, 90, 70, 90))
    for (tx, ty, tw, th, ang) in tape:
        _tape(img, tx * w, ty * h, tw, th, ang, r)
    return img


def _tape(img, x, y, tw, th, ang, r):
    """A piece of old masking tape, gone amber, torn ends."""
    t = Image.new('RGBA', (int(tw), int(th)), (0, 0, 0, 0))
    a = np.zeros((int(th), int(tw), 4), dtype=np.float32)
    a[..., :3] = np.array([0.82, 0.68, 0.4]) * (0.9 + 0.1 * noise(int(th), int(tw), 6, int(r.integers(1e6)))[..., None])
    a[..., 3] = 0.82
    xs = np.arange(int(tw))
    for end in (0, 1):
        jag = (noise(int(th), 1, 2, int(r.integers(1e6)))[:, 0] * 0.5 + 0.5) * 4
        if end == 0:
            a[..., 3] *= (xs[None, :] > jag[:, None])
        else:
            a[..., 3] *= (xs[None, :] < tw - 1 - jag[:, None])
    t = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), 'RGBA').rotate(ang, resample=Image.BICUBIC, expand=True)
    img.alpha_composite(t, (int(x - t.width / 2), int(y - t.height / 2)))


def misregister(sheet_img, dx=1, dy=1):
    """The ink line printed a hair off the colours: the dark channel shifted."""
    return sheet_img


def round_face(im):
    """Clear everything outside the circle: the clock's face is a disc on a square quad."""
    im = im.convert('RGBA')
    a = np.array(im)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    out = (xx - w / 2 + 0.5) ** 2 + (yy - h / 2 + 0.5) ** 2 > (min(w, h) / 2 - 3) ** 2
    a[out, 3] = 0
    return Image.fromarray(a)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, 'dress_' + name + '.png')
    img.save(p, optimize=True)
    print('textures/dress_' + name + '.png', img.width, 'x', img.height)


# ---------------------------------------------------------------------------------- the girls
#
# The girls are rendered, not drawn: tools/poster_girls (at the repo's root) poses Quaternius's CC0
# base woman and lights her like a studio shoot. Here, before that, her skin with the bikini in the
# brand's colours; after it, her picture printed: the colours pushed toward a four-colour press's,
# a little grain, the edges of her cut out clean.

KIT = os.environ.get('UBC_KIT', '/tmp/claude-0/ubc/Universal Base Characters[Standard]')
WORK = os.environ.get('GIRLS_WORK', os.path.join(tempfile.gettempdir(), 'last-call-girls'))
BIKINI = {'boors': ('8fc0e0', None), 'mildcat': (None, 'leopard'), 'unlucky': ('3f8a6a', None), 'velvet': (None, 'skin')}


def leopard(w, h, seed=7):
    r = np.random.default_rng(seed)
    im = Image.new('RGB', (w, h), rgb('d29a4a')[:3])
    d = ImageDraw.Draw(im)
    for _ in range(int(w * h / 900)):
        x, y = r.random() * w, r.random() * h
        s = r.uniform(7, 14)
        # a rosette: a broken ring of black round a darker middle
        d.ellipse([x - s * 0.6, y - s * 0.5, x + s * 0.6, y + s * 0.5], fill=(150, 92, 40))
        for k in range(r.integers(3, 6)):
            a = r.uniform(0, 2 * math.pi)
            px, py = x + math.cos(a) * s * 0.75, y + math.sin(a) * s * 0.65
            q = s * r.uniform(0.22, 0.38)
            d.ellipse([px - q, py - q * 0.8, px + q, py + q * 0.8], fill=(28, 18, 10))
    return im


def girl_skins():
    os.makedirs(WORK, exist_ok=True)
    src = Image.open(os.path.join(KIT, 'Base Characters', 'Textures', 'T_Superhero_Female_Light_BaseColor.png')).convert('RGB')
    a = np.asarray(src, dtype=np.float32) / 255.0
    # the bikini is the bluish grey; skin is warm
    mask = (a[..., 2] > a[..., 0] * 0.98).astype(np.float32)
    mask = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255.0
    lum = (a * [0.3, 0.59, 0.11]).sum(-1)
    shade = np.clip(lum / max(np.percentile(lum[mask > 0.5], 85), 1e-3), 0.25, 1.15)
    # warm the skin a little, the way a studio's tungsten did
    skin = a * [1.0, 0.97, 0.93]
    for name, (col, pattern) in BIKINI.items():
        if pattern == 'leopard':
            fab = np.asarray(leopard(a.shape[1], a.shape[0]), dtype=np.float32) / 255.0
        elif pattern == 'skin':
            # nothing on: the bikini's place in her own skin's tone (the velvet painting)
            fab = np.ones_like(a) * np.median(skin[mask < 0.2].reshape(-1, 3), axis=0) * 0.93
        else:
            fab = np.ones_like(a) * (np.array(rgb(col)[:3]) / 255.0)
        out = skin * (1 - mask[..., None]) + fab * shade[..., None] * mask[..., None]
        Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(os.path.join(WORK, 'girl_skin_' + name + '.png'))
        print(WORK + '/girl_skin_' + name + '.png')
    lab = can_label('boors', 512, 256)
    lab.convert('RGB').save(os.path.join(WORK, 'can_label.png'))


def printed(im, seed, levels=10, warm=0.08, grain=0.028):
    """A render printed: colours stepped toward a press's, the blacks lifted to ink, the whites to
    paper, grain."""
    a = np.asarray(im.convert('RGBA'), dtype=np.float32) / 255.0
    c = a[..., :3]
    c = np.round(c * levels) / levels * 0.6 + c * 0.4
    c = 0.08 + c * 0.86
    c = c * (1 - warm) + np.array([0.95, 0.82, 0.62]) * warm
    g = np.random.default_rng(seed).standard_normal(c.shape[:2])[..., None] * grain
    c = np.clip(c + g, 0, 1)
    return Image.fromarray((np.concatenate([c, a[..., 3:]], -1) * 255).astype(np.uint8), 'RGBA')


def girl(name, h=None, crop=None):
    p = os.path.join(WORK, 'girl_' + name + '.png')
    im = Image.open(p).convert('RGBA')
    if crop:
        im = im.crop(crop)
    im = im.crop(im.getbbox())
    if h:
        im = im.resize((int(im.width * h / im.height), h), Image.LANCZOS)
    return printed(im, len(name))


# ---------------------------------------------------------------------------------- the brands

def can_label(brand, w, h):
    sh = Sheet(w, h, {'boors': 'c9d3da', 'mildcat': 'd98a2a', 'unlucky': '2f6a52', 'mildew': 'e6dcc0'}[brand])
    if brand == 'boors':
        for i in range(0, w, 6):
            sh.rect(i, 0, i + 2, h, 'b7c3cb')
        sh.rect(0, h * 0.62, w, h * 0.8, '1f3a6a')
        sh.text((w / 2, h * 0.36), 'BOORS', font('archivo-black-400', h * 0.32), '1f3a6a', anchor='mm')
        sh.text((w / 2, h * 0.71), 'LIGHT', font('anton-400', h * 0.13), 'e8eef2', anchor='mm', track=6)
    elif brand == 'mildcat':
        sh.text((w / 2, h * 0.42), 'MILDCAT', font('anton-400', h * 0.34), '1a120c', anchor='mm')
        sh.rect(0, h * 0.7, w, h * 0.76, '1a120c')
    elif brand == 'unlucky':
        sh.text((w / 2, h * 0.4), 'UNLUCKY', font('zilla-slab-600', h * 0.3), 'e8dcb0', anchor='mm')
        sh.text((w / 2, h * 0.7), 'LAGER', font('barlow-condensed-600', h * 0.14), 'e8dcb0', anchor='mm', track=8)
    return sh.done()


def mountains(sh, y0, w, seed, snow='eef4f8', rock='5a7a96', far='8fb0c8'):
    r = np.random.default_rng(seed)
    for layer, col, amp, base in ((0, far, 90, y0 - 40), (1, rock, 150, y0)):
        pts = [(0, base + 80)]
        x = 0
        while x < w:
            x += r.uniform(40, 90)
            pts.append((x, base - r.uniform(0.3, 1.0) * amp))
            x += r.uniform(30, 70)
            pts.append((x, base - r.uniform(0.0, 0.35) * amp))
        pts += [(w, base + 80), (w, h_big := base + 400), (0, h_big)]
        sh.poly(pts, col)
        if layer == 1:
            # snow on the peaks
            for i in range(1, len(pts) - 3, 2):
                px, py = pts[i]
                sh.poly([(px, py), (px - 26, py + 34), (px - 10, py + 28), (px + 4, py + 40), (px + 22, py + 30)], snow)


def boors(w=600, h=900):
    sh = Sheet(w, h, 'cfe3ee')
    # the sky to the mountains, the snowfield she stands in
    for i in range(40):
        y = i * h / 80
        c = np.array(rgb('8fb8d6')[:3]) * (1 - i / 40) + np.array(rgb('e8f1f6')[:3]) * (i / 40)
        sh.rect(0, y, w, y + h / 80 + 1, '%02x%02x%02x' % tuple(int(v) for v in c))
    mountains(sh, 470, w, 3)
    sh.rect(0, 560, w, h, 'eef3f6')
    sh.ellipse(-80, 520, w + 80, 640, 'eef3f6')
    g = girl('boors', h=700)
    sh.im.alpha_composite(g.resize((g.width * SS, g.height * SS), Image.LANCZOS), (int((w / 2 - g.width / 2 + 10) * SS), int(150 * SS)))
    # the brand: big, slanted, the silver stripe through it
    sh.text((w / 2, 74), 'COLD AS YOUR EX.', font('anton-400', 54), '1f3a6a', anchor='mm', track=3)
    sh.rect(0, 750, w, h, '1f3a6a')
    sh.rect(0, 744, w, 750, 'c9d3da')
    sh.text((w / 2, 800), 'BOORS', font('archivo-black-400', 84), 'eef3f6', anchor='mm', stroke=2, stroke_fill='c9d3da')
    sh.text((w / 2, 850), 'L I G H T', font('barlow-condensed-600', 30), 'c9d3da', anchor='mm')
    sh.text((w / 2, 882), 'Brewed with Rocky Mountain water and regret.  Drink responsibly, or at least quietly.  © 1996', font('barlow-condensed-400', 12.5), '8fa6c0', anchor='mm')
    im = age(sh.done(), 11, sun=0.42, yellow=0.3, fox=0.7, creases=[('h', 0.5), ('v', 0.5)],
             pins=[(0.03, 0.02), (0.97, 0.025), (0.03, 0.975)], tape=[(0.95, 0.97, 60, 18, 35)], torn=0.4)
    save(im, 'boors')


def mildcat(w=600, h=900):
    sh = Sheet(w, h, 'd8902c')
    # a bar's back wall gone gold, a spot of light behind her
    sh.ellipse(60, 160, 540, 720, 'e8aa4a')
    sh.ellipse(140, 240, 460, 640, 'f0bf62')
    # the band across the top: tiger stripes, black on the gold
    sh.rect(0, 0, w, 108, 'e0a040')
    r = np.random.default_rng(9)
    x = -20
    while x < w + 20:
        top = r.uniform(-10, 10)
        wd = r.uniform(10, 22)
        lean = r.uniform(-18, 18)
        sh.blob([(x, top), (x + wd, top), (x + wd * 0.6 + lean, 54 + r.uniform(-8, 20)), (x + lean * 0.5, 40)], '1a120c', n=8)
        sh.blob([(x + lean, 112), (x + wd + lean, 112), (x + wd * 0.5, 62 + r.uniform(-10, 10))], '1a120c', n=8)
        x += r.uniform(34, 56)
    sh.rect(0, 104, w, 112, '1a120c')
    g = girl('mildcat', h=650)
    sh.im.alpha_composite(g.resize((g.width * SS, g.height * SS), Image.LANCZOS), (int((w / 2 - g.width / 2 - 20) * SS), int(120 * SS)))
    sh.text((w / 2, 56), 'UNLEASH THE MILD.', font('anton-400', 50), '1a120c', anchor='mm', stroke=3, stroke_fill='f0bf62', track=2)
    sh.rect(0, 742, w, h, '1a120c')
    sh.text((w / 2 + 4, 812), 'MILDCAT', font('anton-400', 104), 'd8902c', anchor='mm', track=4)
    sh.text((w / 2, 870), 'PREMIUM DOMESTIC.  MOSTLY.', font('barlow-condensed-600', 22), 'f0bf62', anchor='mm', track=3)
    im = sh.done()
    # what the regulars think of it, in marker, across her shins and the logo
    mk = Sheet(w, h, '000000')
    mk.im = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))
    mk.d = ImageDraw.Draw(mk.im)
    mk.text((300, 700), 'SHITTY KITTY', font('kalam-400', 58), '141018', anchor='mm', rot=7)
    mk.line([(430, 640), (470, 600), (452, 598)], '141018', 3.5)
    mk.line([(470, 600), (466, 620)], '141018', 3.5)
    im.alpha_composite(mk.done())
    im = age(im, 12, sun=0.3, yellow=0.3, fox=0.5, creases=[('h', 0.5)], pins=[(0.04, 0.02), (0.96, 0.02)],
             tape=[(0.06, 0.97, 54, 17, -20), (0.94, 0.975, 54, 17, 25)], torn=0.3)
    save(im, 'mildcat')


def unlucky(w=600, h=900):
    """The calendar: Miss March, 1998, the days crossed off to the thirteenth and no further."""
    sh = Sheet(w, h, 'ece4d0')
    # the photo, top half: a dusk sky, a gravel lot, the jade truck and her
    for i in range(30):
        y = 30 + i * 15
        c = np.array(rgb('6a7a9a')[:3]) * (1 - i / 30) + np.array(rgb('e0a070')[:3]) * (i / 30)
        sh.rect(24, y, w - 24, y + 16, '%02x%02x%02x' % tuple(int(v) for v in c))
    sh.rect(24, 400, w - 24, 520, '6a6258')
    g = girl('unlucky', h=480, crop=(0, 120, 900, 1290))
    gx = int(w / 2 - g.width / 2)
    sh.im.alpha_composite(g.resize((g.width * SS, g.height * SS), Image.LANCZOS), (gx * SS, 40 * SS))
    sh.rect(0, 0, 24, 520, 'ece4d0')
    sh.rect(w - 24, 0, w, 520, 'ece4d0')
    sh.rect(0, 0, w, 30, 'ece4d0')
    sh.text((40, 470), 'GET UNLUCKY.', font('zilla-slab-600', 40), 'f2e6c0', stroke=2, stroke_fill='2f3a30')
    sh.text((w - 40, 506), 'MISS MARCH', font('barlow-condensed-600', 18), 'f2e6c0', anchor='rm', track=4)
    # the grid
    sh.rect(24, 528, w - 24, 590, '2f6a52')
    sh.text((44, 560), 'UNLUCKY LAGER', font('zilla-slab-600', 30), 'ece4d0', anchor='lm')
    sh.text((w - 44, 560), 'MARCH 1998', font('barlow-condensed-600', 34), 'ece4d0', anchor='rm', track=2)
    days = 'SUN MON TUE WED THU FRI SAT'.split()
    cw = (w - 48) / 7
    for i, d in enumerate(days):
        sh.text((24 + cw * (i + 0.5), 606), d, font('barlow-condensed-600', 15), '2f6a52', anchor='mm')
    # March 1998 began on a Sunday
    for day in range(1, 32):
        k = day - 1
        col, row = k % 7, k // 7
        x0, y0 = 24 + cw * col, 618 + row * 52
        sh.rect(x0, y0, x0 + cw, y0 + 52, None, 'b8ae98', 1)
        sh.text((x0 + 6, y0 + 4), str(day), font('barlow-condensed-600', 17), '3a3a34')
        if day <= 13:
            # crossed off in ballpoint, each a little differently
            jx = (day * 37 % 7) - 3
            sh.line([(x0 + 10 + jx, y0 + 12), (x0 + cw - 10, y0 + 46 - jx)], '2a3a6a', 2.2)
            sh.line([(x0 + cw - 12, y0 + 10 + jx), (x0 + 12, y0 + 44)], '2a3a6a', 2.2)
    # in pencil, on the fourteenth
    x0, y0 = 24 + cw * 6, 618 + 52
    sh.text((x0 + cw / 2, y0 + 34), 'D.', font('kalam-300', 18), '6a6a6a', anchor='mm', rot=-6)
    sh.text((w / 2, 888), 'Brewed on the island since whenever.  Unlucky Lager is not responsible for anything.', font('barlow-condensed-400', 12), '6a6458', anchor='mm')
    im = age(sh.done(), 13, sun=0.25, yellow=0.4, fox=0.8, creases=[], pins=[(0.5, 0.012)], torn=0.15, grime=0.4)
    save(im, 'unlucky')


def lochness(w=500, h=750):
    sh = Sheet(w, h, '15120f')
    # a pint of it, the head on it, and in the head, something
    cx = w / 2
    sh.poly([(cx - 112, 170), (cx + 112, 170), (cx + 92, 600), (cx - 92, 600)], '1e1814', outline='3a302a', width=3)
    sh.poly([(cx - 108, 178), (cx + 108, 178), (cx + 90, 590), (cx - 90, 590)], '0c0908')
    sh.poly([(cx - 110, 170), (cx + 110, 170), (cx + 106, 238), (cx - 106, 238)], 'e8dcc0')
    # the humps and the neck, coming up out of the foam
    for hx in (cx - 60, cx - 18):
        sh.blob([(hx - 22, 206), (hx - 10, 182), (hx + 10, 180), (hx + 22, 206)], '2a2420', '0c0908', 2)
    sh.blob([(cx + 20, 210), (cx + 28, 150), (cx + 46, 112), (cx + 72, 100), (cx + 86, 112), (cx + 70, 120),
             (cx + 56, 140), (cx + 48, 178), (cx + 50, 210)], '2a2420', '0c0908', 2)
    sh.ellipse(cx + 70, 104, cx + 76, 110, 'e8dcc0')
    sh.rect(cx - 112, 168, cx + 112, 172, 'f4ecd8')
    # the harp's place: a wee loch crest
    sh.text((cx, 64), 'LOCHNESS', font('zilla-slab-600', 66), 'e8dcc0', anchor='mm', track=6)
    sh.text((cx, 112), 'IRISH-ISH  STOUT', font('barlow-condensed-600', 20), 'b8a070', anchor='mm', track=6)
    sh.text((cx, 650), 'Something dark lives in here.', font('cormorant-garamond-400-italic', 36), 'e8dcc0', anchor='mm')
    sh.text((cx, 698), "Seen it?  Neither has anyone sober.", font('barlow-condensed-400', 18), 'b8a070', anchor='mm')
    sh.text((cx, 728), 'BREWED IN THE DARK SINCE 1759, PROBABLY', font('barlow-condensed-600', 11), '6a5a40', anchor='mm', track=3)
    sh.rect(10, 10, w - 10, h - 10, None, 'b8a070', 2)
    im = age(sh.done(), 14, sun=0.15, yellow=0.2, fox=0.3, creases=[('v', 0.5)], pins=[(0.03, 0.02), (0.97, 0.02), (0.97, 0.98)], torn=0.2, grime=0.5)
    save(im, 'lochness')


def labutt(w=480, h=300):
    """A tin sign, embossed once, rusting at the screw holes."""
    sh = Sheet(w, h, '1f4a8a')
    sh.rect(10, 10, w - 10, h - 10, None, 'e8eef2', 4)
    sh.text((w / 2, 110), 'LABUTT', font('archivo-black-400', 90), 'f2f4f6', anchor='mm', stroke=3, stroke_fill='0e2a54')
    sh.text((w / 2, 180), 'BLUE', font('anton-400', 54), 'e8c84a', anchor='mm', track=12)
    sh.text((w / 2, 245), 'Out of the blue.  Into the ditch.', font('cormorant-garamond-400-italic', 26), 'e8eef2', anchor='mm')
    im = sh.done()
    a = np.asarray(im, dtype=np.float32) / 255.0
    r = np.random.default_rng(5)
    hh, ww = a.shape[:2]
    yv, xv = np.ogrid[:hh, :ww]
    for (sx, sy) in ((18, 18), (ww - 18, 18), (18, hh - 18), (ww - 18, hh - 18)):
        d = np.sqrt((xv - sx) ** 2 + (yv - sy) ** 2)
        k = np.clip(1 - d / r.uniform(18, 34), 0, 1) * (0.7 + 0.3 * noise(hh, ww, 4, 9))
        a[..., :3] = a[..., :3] * (1 - k[..., None]) + np.array([0.42, 0.24, 0.12]) * k[..., None]
        a[..., :3] *= (1 - (d < 4)[..., None] * 0.9)
    # a dent, where something was thrown at it
    d = np.sqrt((xv - ww * 0.7) ** 2 + ((yv - hh * 0.35) * 1.3) ** 2)
    a[..., :3] *= (1 - 0.25 * np.exp(-d ** 2 / 300) * (xv > ww * 0.7))[..., None]
    a[..., :3] += (0.18 * np.exp(-d ** 2 / 300) * (xv <= ww * 0.7))[..., None]
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), 'RGBA')
    im = age(im, 15, sun=0.2, yellow=0.1, fox=0.0, grime=0.5)
    save(im, 'labutt')


def mildew_clock(n=512):
    """The beer clock's face, lit from behind: OLD MILDEW, IT'S ALWAYS TIME."""
    sh = Sheet(n, n, 'f2ead2')
    c = n / 2
    sh.ellipse(4, 4, n - 4, n - 4, 'f2ead2', '3a2a1a', 6)
    sh.ellipse(40, 40, n - 40, n - 40, None, '7a5a2a', 3)
    for k in range(12):
        a = k / 12 * 2 * math.pi
        x, y = c + math.sin(a) * (n * 0.4), c - math.cos(a) * (n * 0.4)
        sh.text((x, y), str(12 if k == 0 else k), font('zilla-slab-600', 34), '3a2a1a', anchor='mm')
    sh.text((c, c - 70), 'OLD', font('barlow-condensed-600', 30), '7a5a2a', anchor='mm', track=10)
    sh.text((c, c - 30), 'MILDEW', font('zilla-slab-600', 58), '3a2a1a', anchor='mm')
    sh.text((c, c + 70), "it's always time", font('cormorant-garamond-400-italic', 30), '7a5a2a', anchor='mm')
    sh.text((c, c + 104), 'MILWAUKEE-ISH, 1955', font('barlow-condensed-400', 14), '7a5a2a', anchor='mm', track=4)
    im = sh.done()
    # flies dead inside the cover, down at the bottom
    d = ImageDraw.Draw(im)
    r = np.random.default_rng(2)
    for _ in range(5):
        x, y = c + r.uniform(-120, 120), n * 0.78 + r.uniform(-20, 40)
        d.ellipse([x - 3, y - 2, x + 3, y + 2], fill=(30, 24, 20, 255))
    im = age(im, 16, sun=0.0, yellow=0.45, fox=0.4, grime=0.5)
    save(round_face(im), 'mildew')


# ---------------------------------------------------------------------------------- the house's signs

def sign(name, w, h, ground, lines, marker=None, seed=0, border=None):
    """A printed sign: lines of (text, font, size, colour, y); and in marker, what someone added."""
    sh = Sheet(w, h, ground)
    if border:
        sh.rect(8, 8, w - 8, h - 8, None, border, 3)
    for (t, f, sz, col, y) in lines:
        sh.text((w / 2, y), t, font(f, sz), col, anchor='mm')
    im = sh.done()
    if marker:
        mk = Sheet(w, h, '000000')
        mk.im = Image.new('RGBA', (w * SS, h * SS), (0, 0, 0, 0))
        mk.d = ImageDraw.Draw(mk.im)
        for (t, sz, x, y, rot) in marker:
            mk.text((x, y), t, font('kalam-400', sz), '16121a', anchor='mm', rot=rot)
        im.alpha_composite(mk.done())
    im = age(im, 30 + seed, sun=0.15, yellow=0.35, fox=0.3, grime=0.45, pins=[], tape=[(0.08, 0.06, 40, 14, -30), (0.92, 0.06, 40, 14, 30)])
    save(im, name)


def signs():
    sign('reserve', 420, 300, 'efe8d6', [
        ('WE RESERVE', 'anton-400', 52, '1a1814', 56), ('THE RIGHT', 'anton-400', 52, '1a1814', 112),
        ('TO REFUSE SERVICE', 'anton-400', 40, '1a1814', 164), ('TO ANYONE', 'anton-400', 52, '1a1814', 216)],
        marker=[('and we do.  - G.', 30, 300, 266, -4)], seed=1, border='1a1814')
    sign('forget', 360, 300, '1f2a3a', [
        ('IF YOU ARE', 'barlow-condensed-600', 34, 'e8dcc0', 50), ('DRINKING TO FORGET', 'anton-400', 38, 'e8c84a', 98),
        ('PLEASE', 'barlow-condensed-600', 34, 'e8dcc0', 150), ('PAY IN ADVANCE', 'anton-400', 44, 'e8dcc0', 200)],
        marker=None, seed=2, border='e8c84a')
    sign('minors', 300, 380, 'f4f0e4', [
        ('MINORS', 'anton-400', 66, '1a1814', 70), ('PROHIBITED', 'anton-400', 46, '1a1814', 130),
        ('Persons under 19 years of age', 'barlow-condensed-400', 20, '1a1814', 190),
        ('are not permitted on', 'barlow-condensed-400', 20, '1a1814', 216), ('these premises.', 'barlow-condensed-400', 20, '1a1814', 242),
        ('LIQUOR CONTROL AND LICENSING', 'barlow-condensed-600', 15, '3a3a34', 330), ('Licence No. 0028-S', 'barlow-condensed-400', 13, '3a3a34', 350)],
        seed=3, border='1a1814')
    sign('noshirt', 380, 280, 'e8e2d0', [
        ('NO SHIRT', 'anton-400', 58, '1a1814', 60), ('NO SHOES', 'anton-400', 58, '1a1814', 124),
        ('NO SERVICE', 'anton-400', 58, '1a1814', 188)],
        marker=[('no pants: ask Gary', 30, 200, 244, -3)], seed=4)
    sign('cash', 300, 200, 'e8c84a', [
        ('CASH ONLY', 'anton-400', 52, '1a1814', 64), ('the debit machine', 'barlow-condensed-600', 26, '1a1814', 116),
        ('is a liar', 'barlow-condensed-600', 26, '1a1814', 146)], seed=5)


# ---------------------------------------------------------------------------------- the corkboard

def flyer(name, w, h, ground, draw, seed, tabs=0, torn_tabs=()):
    sh = Sheet(w, h, ground)
    draw(sh, w, h)
    if tabs:
        tw = w / tabs
        for i in range(tabs):
            x0 = i * tw
            sh.line([(x0, h - 70), (x0, h)], '9a9488', 1)
            sh.text((x0 + tw / 2, h - 35), sh_tab.get(name, '250-555-0148'), font('barlow-condensed-400', 11), '2a2a28', anchor='mm', rot=90)
        sh.line([(0, h - 70), (w, h - 70)], '9a9488', 1)
    im = sh.done()
    # the tabs somebody took
    if torn_tabs:
        a = np.asarray(im, dtype=np.float32)
        tw = w / tabs
        for i in torn_tabs:
            x0, x1 = int(i * tw) + 1, int((i + 1) * tw) - 1
            jag = (noise(1, x1 - x0, 3, seed + i)[0] * 4 + 6).astype(int)
            for k, x in enumerate(range(x0, x1)):
                a[h - 70 + jag[k]:, x, 3] = 0
        im = Image.fromarray(a.astype(np.uint8), 'RGBA')
    im = age(im, 50 + seed, sun=0.2, yellow=0.3, fox=0.3, grime=0.25, pins=[(0.5, 0.03)])
    save(im, 'fly_' + name)


sh_tab = {'cat': 'PICKLES 250-555-0193', 'room': 'Gary, at the bar', 'smoker': 'Sid  250-555-0177'}


def flyers():
    def band(sh, w, h):
        sh.rect(0, 0, w, h * 0.45, '1a1a1a')
        # a drum kit, in silhouette, from the front: the bass drum's head, the toms, the cymbals
        cx = w / 2
        sh.ellipse(cx - 46, 70, cx + 46, 162, 'e8e2d0')
        sh.ellipse(cx - 40, 76, cx + 40, 156, '1a1a1a')
        sh.text((cx, 116), 'DS', font('anton-400', 30), 'e8e2d0', anchor='mm')
        sh.ellipse(cx - 70, 52, cx - 30, 80, 'e8e2d0')
        sh.ellipse(cx + 30, 52, cx + 70, 80, 'e8e2d0')
        sh.line([(cx - 96, 40), (cx - 50, 28)], 'e8e2d0', 4)
        sh.line([(cx + 50, 22), (cx + 104, 36)], 'e8e2d0', 4)
        sh.text((cx, h * 0.52), 'THE DOWNSTROKES', font('anton-400', 30), '1a1a1a', anchor='mm')
        sh.text((cx, h * 0.6), 'classic rock.  covers of covers.', font('barlow-condensed-600', 17), '1a1a1a', anchor='mm')
        sh.text((cx, h * 0.7), 'SATURDAY  9 PM', font('anton-400', 26), '1a1a1a', anchor='mm')
        sh.text((cx, h * 0.78), 'at the Sov.  No cover.', font('barlow-condensed-400', 17), '1a1a1a', anchor='mm')
        sh.text((cx, h * 0.84), '(get it)', font('barlow-condensed-400', 14), '4a4a48', anchor='mm')
        sh.text((cx, h * 0.93), 'JIM ON DRUMS', font('barlow-condensed-600', 15), '1a1a1a', anchor='mm', track=3)
    flyer('band', 240, 330, 'e8e2d0', band, 1)

    def smoker(sh, w, h):
        sh.rect(10, 10, w - 10, h - 10, None, '1a1814', 3)
        sh.text((w / 2, 42), 'SMOKER', font('anton-400', 52), '1a1814', anchor='mm', track=4)
        sh.text((w / 2, 82), 'at the fish plant', font('barlow-condensed-600', 20), '1a1814', anchor='mm')
        sh.line([(30, 100), (w - 30, 100)], '1a1814', 2)
        sh.text((w / 2, 128), 'SUNDAY  8 PM', font('anton-400', 28), '1a1814', anchor='mm')
        sh.text((w / 2, 162), '3 rounds.  $200 to the last', font('barlow-condensed-400', 18), '1a1814', anchor='mm')
        sh.text((w / 2, 184), 'man standing.', font('barlow-condensed-400', 18), '1a1814', anchor='mm')
        sh.text((w / 2, 214), 'bring your own mouthguard', font('barlow-condensed-600', 16), '1a1814', anchor='mm')
        sh.text((w / 2, 236), 'NO REFEREE.  NO REFUNDS.', font('barlow-condensed-600', 14), '1a1814', anchor='mm', track=2)
    flyer('smoker', 230, 340, 'd8d2c0', smoker, 2, tabs=6, torn_tabs=(0, 1, 2, 4))

    def meat(sh, w, h):
        sh.text((w / 2, 40), 'MEAT DRAW', font('anton-400', 40), '2a4a2a', anchor='mm')
        sh.text((w / 2, 82), 'every Sunday 4 pm', font('barlow-condensed-600', 20), '1a1814', anchor='mm')
        sh.text((w / 2, 112), 'ROYAL CANADIAN LEGION', font('barlow-condensed-600', 15), '1a1814', anchor='mm', track=2)
        sh.text((w / 2, 132), 'Branch 71', font('barlow-condensed-400', 16), '1a1814', anchor='mm')
        sh.text((w / 2, 170), 'hams  roasts  a turkey', font('barlow-condensed-400', 17), '1a1814', anchor='mm')
        sh.text((w / 2, 194), 'and the 50/50', font('barlow-condensed-400', 17), '1a1814', anchor='mm')
        sh.text((w / 2, 236), 'proceeds to the poppy fund', font('cormorant-garamond-400-italic', 18), '3a3a34', anchor='mm')
    flyer('meat', 220, 270, 'f2eedc', meat, 3)

    def cat(sh, w, h):
        sh.text((w / 2, 34), 'LOST CAT', font('anton-400', 40), '1a1814', anchor='mm')
        # the photocopy of a photo of a cat: grey, mostly toner
        sh.rect(30, 62, w - 30, 190, '7a7670')
        sh.ellipse(70, 92, 160, 176, '3a3632')
        sh.poly([(80, 104), (92, 70), (104, 98)], '3a3632')
        sh.poly([(126, 98), (140, 70), (150, 104)], '3a3632')
        sh.ellipse(94, 116, 104, 126, 'c8c4a0')
        sh.ellipse(124, 116, 134, 126, 'c8c4a0')
        sh.text((w / 2, 214), 'PICKLES', font('anton-400', 30), '1a1814', anchor='mm')
        sh.text((w / 2, 244), 'answers to nothing.', font('barlow-condensed-400', 17), '1a1814', anchor='mm')
        sh.text((w / 2, 266), 'has done this before.', font('barlow-condensed-400', 17), '1a1814', anchor='mm')
    flyer('cat', 220, 360, 'f0f0ec', cat, 4, tabs=5, torn_tabs=(2,))

    def room(sh, w, h):
        lines = ['ROOM FOR RENT', 'upstairs.  weekly.', 'shared bath.', 'no drugs no pets', 'no drama.', '', 'ask at the bar']
        for i, t in enumerate(lines):
            sh.text((18, 26 + i * 28), t, font('kalam-400', 20 if i == 0 else 18), '2a2a5a')
    flyer('room', 200, 260, 'f6f2e2', room, 5)

    def darlene(sh, w, h):
        sh.rect(0, 0, w, h, None, '6a6458', 6)
        sh.text((w / 2, 36), 'in loving memory', font('cormorant-garamond-400-italic', 22), '3a3a34', anchor='mm')
        sh.text((w / 2, 74), 'DARLENE', font('zilla-slab-600', 40), '1a1814', anchor='mm', track=4)
        sh.text((w / 2, 112), 'a celebration of life', font('cormorant-garamond-400-italic', 20), '3a3a34', anchor='mm')
        sh.text((w / 2, 150), 'at the Sov.  Saturday March 28.  2 pm.', font('barlow-condensed-400', 16), '1a1814', anchor='mm')
        sh.text((w / 2, 176), 'potluck.  bring a story.', font('barlow-condensed-400', 16), '1a1814', anchor='mm')
        sh.text((w / 2, 220), 'she would have hated this', font('kalam-300', 16), '4a4a6a', anchor='mm', rot=-3)
    flyer('darlene', 240, 250, 'ece6d4', darlene, 6)

    def karaoke(sh, w, h):
        sh.rect(0, 0, w, h, '2a1a3a')
        sh.text((w / 2, 50), 'KARAOKE', font('anton-400', 46), 'e8c84a', anchor='mm', track=3)
        sh.text((w / 2, 96), 'TUESDAYS', font('anton-400', 30), 'e8dcc0', anchor='mm', track=3)
        sh.text((w / 2, 134), 'with DJ SANDY', font('barlow-condensed-600', 22), 'e8dcc0', anchor='mm')
        sh.text((w / 2, 176), 'you are not as good', font('barlow-condensed-400', 18), 'b8a8c8', anchor='mm')
        sh.text((w / 2, 198), 'as you think you are.', font('barlow-condensed-400', 18), 'b8a8c8', anchor='mm')
        sh.text((w / 2, 230), 'sing anyway.', font('cormorant-garamond-400-italic', 22), 'e8c84a', anchor='mm')
    flyer('karaoke', 220, 260, '2a1a3a', karaoke, 7)

    def drywall(sh, w, h):
        sh.text((14, 22), 'PREMIUM DRYWALL', font('archivo-black-400', 15), '1a1814')
        sh.text((14, 46), 'no job too small', font('barlow-condensed-400', 13), '1a1814')
        sh.text((14, 62), 'holes punched in walls', font('barlow-condensed-400', 13), '1a1814')
        sh.text((14, 78), 'a specialty.  Darrell', font('barlow-condensed-400', 13), '1a1814')
        sh.text((14, 100), '250-555-0110', font('barlow-condensed-600', 14), '1a1814')
    flyer('drywall', 190, 124, 'f4f2ea', drywall, 8)


# ---------------------------------------------------------------------------------- the Esso

def esso_ads():
    def ad(name, w, h, ground, lines, seed, band=None):
        sh = Sheet(w, h, ground)
        if band:
            sh.rect(0, 0, w, h * 0.22, band)
        for (t, f, sz, col, y) in lines:
            sh.text((w / 2, y), t, font(f, sz), col, anchor='mm')
        im = age(sh.done(), 70 + seed, sun=0.45, yellow=0.2, fox=0.1, grime=0.2, tape=[(0.1, 0.05, 50, 16, -20), (0.9, 0.05, 50, 16, 20)])
        save(im, 'esso_' + name)
    ad('ice', 360, 480, 'e8f2f6', [('ICE', 'anton-400', 150, '1f4a8a', 140), ('2 BAGS', 'anton-400', 60, '1f4a8a', 280),
                                   ('$5', 'anton-400', 110, '1a1814', 380), ('it is still just water', 'barlow-condensed-400', 20, '1f4a8a', 455)], 1)
    ad('smokes', 400, 300, 'f4efe0', [('SMOKES', 'anton-400', 60, '1a1814', 70), ('behind the counter.  ask.', 'barlow-condensed-600', 26, '1a1814', 130),
                                       ('PRICES UP AGAIN', 'anton-400', 44, '8a4a1a', 190), ('not our fault.  ask Ottawa.', 'barlow-condensed-400', 22, '1a1814', 248)], 2)
    ad('lotto', 400, 520, '1f3a6a', [('LOTTO MOST', 'anton-400', 60, 'e8c84a', 70), ('TONIGHT', 'barlow-condensed-600', 34, 'f4efe0', 130),
                                      ('$40', 'anton-400', 150, 'f4efe0', 260), ('MILLION', 'anton-400', 60, 'e8c84a', 370),
                                      ('somebody has to.', 'cormorant-garamond-400-italic', 30, 'f4efe0', 440), ('it won’t be you.', 'barlow-condensed-400', 18, '8fa6c0', 480)], 3, band='14284a')
    ad('grill', 380, 300, 'f6e6c0', [('ROLLER GRILL', 'anton-400', 48, '6a3a1a', 56), ('2 for $4', 'anton-400', 80, '1a1814', 140),
                                      ('since this morning', 'barlow-condensed-600', 26, '6a3a1a', 214), ('(the morning before)', 'barlow-condensed-400', 18, '6a3a1a', 252)], 4)
    ad('night', 300, 400, 'f4f4f0', [('NIGHT WINDOW', 'anton-400', 38, '1a1814', 48), ('11 PM - 6 AM', 'barlow-condensed-600', 30, '1a1814', 100),
                                      ('Staff carry no more', 'barlow-condensed-400', 20, '1a1814', 160), ('than $40 cash.', 'barlow-condensed-400', 20, '1a1814', 186),
                                      ('This store is', 'barlow-condensed-400', 20, '1a1814', 232), ('under video surveillance.', 'barlow-condensed-400', 20, '1a1814', 258),
                                      ('(the camera is a box)', 'kalam-300', 20, '2a2a6a', 330)], 5)
    ad('wash', 340, 220, 'e8eef2', [('SQUEEGEE IS FREE', 'anton-400', 36, '1f4a8a', 56), ('wash your windshield.', 'barlow-condensed-600', 26, '1a1814', 116),
                                     ('your sins are', 'barlow-condensed-600', 26, '1a1814', 150), ('your own business.', 'barlow-condensed-600', 26, '1a1814', 184)], 6)
    ad('id', 300, 200, 'f4efe0', [('WE ID', 'anton-400', 58, '1a1814', 60), ('everyone under 30', 'barlow-condensed-600', 26, '1a1814', 116),
                                   ('and anyone who argues', 'barlow-condensed-400', 20, '1a1814', 156)], 7)


# ---------------------------------------------------------------------------------- the trash

def trash(n=1024):
    """One sheet of everything thrown on the ground, in a 4 x 4 grid of 256 squares."""
    t = 256
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))

    def cell(i, sub):
        im.alpha_composite(sub.resize((t, t), Image.LANCZOS), ((i % 4) * t, (i // 4) * t))
    # the cans' labels at the shape they go round a can, squeezed into a square
    cell(0, can_label('boors', 2 * t, t))
    cell(1, can_label('mildcat', 2 * t, t))
    cell(2, can_label('unlucky', 2 * t, t))
    # a chip bag
    sh = Sheet(t, t, 'c8a83a')
    sh.rect(0, 0, t, 30, '8a5a1a')
    sh.rect(0, t - 30, t, t, '8a5a1a')
    sh.text((t / 2, 110), 'RUFFIANS', font('anton-400', 48), '6a1a1a', anchor='mm')
    sh.text((t / 2, 160), 'SALT & VINEGAR', font('barlow-condensed-600', 22), '1a1814', anchor='mm')
    sh.text((t / 2, 196), '30% more air', font('barlow-condensed-400', 16), '1a1814', anchor='mm')
    cell(3, sh.done())
    # a coffee cup
    sh = Sheet(t, t, 'e8e2d0')
    sh.rect(0, 70, t, 190, '6a2a1a')
    sh.text((t / 2, 130), 'Tom Hortons', font('cormorant-garamond-400-italic', 42), 'f2ead8', anchor='mm')
    sh.text((t / 2, 220), 'ROLL UP THE RIM TO LOSE', font('barlow-condensed-600', 14), '6a2a1a', anchor='mm')
    cell(4, sh.done())
    # a cigarette pack
    sh = Sheet(t, t, 'efe8d6')
    sh.rect(0, 0, t, 90, '1a3a2a')
    sh.text((t / 2, 46), 'MATADOR', font('zilla-slab-600', 40), 'efe8d6', anchor='mm', track=3)
    sh.rect(10, 120, t - 10, t - 10, 'f4f4f0', '1a1814', 2)
    for i, ln in enumerate(['WARNING', 'Cigarettes cause', 'mouth cancer.', 'And bad decisions.']):
        sh.text((t / 2, 144 + i * 26), ln, font('barlow-condensed-600', 20 if i == 0 else 17), '1a1814', anchor='mm')
    cell(5, sh.done())
    # a scratch ticket
    sh = Sheet(t, t, 'e8c84a')
    sh.text((t / 2, 36), "SCRATCH 'N' LOSE", font('anton-400', 26), '1a1814', anchor='mm')
    for k in range(6):
        x0, y0 = 22 + (k % 3) * 74, 70 + (k // 3) * 80
        sh.rect(x0, y0, x0 + 64, y0 + 64, '9aa0a3')
        sh.text((x0 + 32, y0 + 32), ['$1', 'X', '$2', 'X', 'X', '$1'][k], font('anton-400', 26), '3a3a34', anchor='mm')
    cell(6, sh.done())
    # a newspaper page
    sh = Sheet(t, t, 'd8d2c2')
    sh.text((14, 24), 'ISLAND TIDE', font('zilla-slab-600', 28), '1a1814')
    sh.text((14, 64), 'FERRY FARES UP', font('anton-400', 26), '1a1814')
    sh.text((14, 92), 'AGAIN', font('anton-400', 26), '1a1814')
    for k in range(10):
        y = 128 + k * 12
        sh.rect(14, y, 120, y + 5, '8a867a')
        sh.rect(132, y, 242, y + 5, '8a867a')
    cell(7, sh.done())
    # a burger wrapper, greased through
    sh = Sheet(t, t, 'e6d8b0')
    for k in range(0, t, 32):
        sh.text((k + 16, 60 + (k % 64)), 'BURGER', font('barlow-condensed-600', 16), 'b06a2a', anchor='mm', rot=30)
        sh.text((k + 16, 180 - (k % 64)), 'BARN', font('barlow-condensed-600', 16), 'b06a2a', anchor='mm', rot=30)
    cell(8, age(sh.done(), 81, sun=0.0, yellow=0.6, fox=2.5, grime=0.6))
    # a condom wrapper
    sh = Sheet(t, t, '2a2a3a')
    sh.rect(8, 8, t - 8, t - 8, None, '8a8aa0', 3)
    sh.ellipse(78, 78, 178, 178, None, '6a6a80', 4)
    sh.text((t / 2, 40), 'SPARTAN', font('archivo-black-400', 30), 'd8c88a', anchor='mm', track=2)
    sh.text((t / 2, 222), 'ribbed for her indifference', font('barlow-condensed-400', 15), 'b8b8c8', anchor='mm')
    cell(9, sh.done())
    # a takeout menu
    sh = Sheet(t, t, 'f0e0c0')
    sh.text((t / 2, 40), 'GOLDEN DRAGON', font('anton-400', 30), '8a3a1a', anchor='mm')
    sh.text((t / 2, 74), 'chinese & canadian food', font('barlow-condensed-600', 16), '1a1814', anchor='mm')
    for k in range(8):
        sh.text((24, 104 + k * 18), ['ginger beef', 'chop suey', 'egg rolls (2)', 'fries', 'chicken balls', 'the special', 'more fries', 'fortune cookie'][k], font('barlow-condensed-400', 14), '1a1814')
        sh.text((t - 24, 104 + k * 18), ['11.95', '9.50', '3.25', '4.00', '8.75', 'ask', '4.00', 'free'][k], font('barlow-condensed-400', 14), '1a1814', anchor='ra')
    cell(10, sh.done())
    # a parking ticket from the town
    sh = Sheet(t, t, 'f2ece0')
    sh.rect(0, 0, t, 40, 'e8b84a')
    sh.text((t / 2, 20), 'NOTICE OF VIOLATION', font('barlow-condensed-600', 20), '1a1814', anchor='mm')
    for k in range(7):
        sh.rect(14, 56 + k * 26, t - 14, 56 + k * 26 + 18, None, '8a867a', 1)
    sh.text((24, 66), 'BYLAW 14(b)', font('courier-prime-700', 13), '2a2a6a')
    cell(11, sh.done())
    # a beer case's end, torn off for a sign: CLOSED SUNDAY in marker
    sh = Sheet(t, t, 'b88a4a')
    sh.text((t / 2, 60), 'BOORS', font('archivo-black-400', 40), '1f3a6a', anchor='mm')
    sh.text((t / 2, 100), '24 CANS', font('barlow-condensed-600', 22), '1f3a6a', anchor='mm')
    sh.text((t / 2, 170), 'CLOSED SUNDAY', font('kalam-400', 30), '141018', anchor='mm', rot=4)
    cell(12, sh.done())
    # a gum wrapper / receipt
    sh = Sheet(t, t, 'f4f4f0')
    for k, ln in enumerate(['ESSO #4471', 'PUMP 3  $40.00', 'SMOKES  $16.50', 'ICE  $5.00', 'LOTTO  $10.00', '', 'TOTAL  $71.50', 'CASH', '', 'THANK YOU', 'COME AGAIN']):
        sh.text((20, 16 + k * 21), ln, font('courier-prime-400', 15), '3a3a3a')
    cell(13, sh.done())
    # a flattened pop can (no brand, sun-gone), and a blank wet paper
    sh = Sheet(t, t, 'c8c8c0')
    sh.rect(0, 80, t, 180, '6a7a3a')
    sh.text((t / 2, 130), 'GINGER ALE', font('barlow-condensed-600', 28), 'e8e8e0', anchor='mm')
    cell(14, age(sh.done(), 82, sun=0.6))
    cell(15, age(Image.new('RGBA', (t, t), (230, 226, 214, 255)), 83, sun=0.0, yellow=0.5, fox=3.0, grime=0.8))
    save(im, 'trash')


ALL = {
    'girls': girl_skins,
    'boors': boors, 'mildcat': mildcat, 'unlucky': unlucky, 'lochness': lochness, 'labutt': labutt, 'mildew': mildew_clock,
    'signs': signs, 'flyers': flyers, 'esso': esso_ads, 'trash': trash,
}



def cork(n=256):
    """The corkboard's cork, tiling: crumbs of light and dark."""
    r = np.random.default_rng(4)
    a = np.ones((n, n, 3), dtype=np.float32) * np.array([0.6, 0.44, 0.28])
    for sc, amt in ((2, 0.12), (5, 0.08), (14, 0.05)):
        k = r.standard_normal((n // sc + 1, n // sc + 1))
        k = np.kron(k, np.ones((sc, sc)))[:n, :n]
        a *= (1 + k[..., None] * amt)
    # holes from years of pins
    for _ in range(140):
        x, y = r.integers(0, n, 2)
        a[max(0, y - 1):y + 1, max(0, x - 1):x + 1] *= 0.45
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, 'dress_cork.png'))
    print('textures/dress_cork.png')


ALL['cork'] = cork


if __name__ == '__main__':
    which = sys.argv[1:] or [k for k in ALL if k != 'girls']
    for k in which:
        ALL[k]()
