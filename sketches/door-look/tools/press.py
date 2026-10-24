"""The press: makes the textures the print shader needs.

  press/separation.png   how much of each ink prints for any rendered colour: a 33x33x33 table
                         laid out as 33 slices side by side (x = red + 33 * blue, y = green);
                         r = the night ink, g = the lamp ink, b = the neon ink
  press/separation_b.png the same table for the other two inks: r = the cold ink, g = the earth ink
  press/grain.png        three grain screens, one per ink (r, g, b), 128 px square, tiling
  press/paper.png        the paper: r its tooth and fibres, g and b two slow mottles; 512 px square, tiling

The inks are defined here and again in press.gdshader; change them in both. The game reads its
own copies of these from godot/press/: copy them over after a change.

  python3 tools/press.py [--separation]    (--separation: only the two tables, not the grain and paper)
"""
import itertools
import numpy as np
from PIL import Image
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'press')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(28)

PAPER = '#eae2cf'                                                           # the build's stock
# night: the key block, blue-black. lamp: amber, the warm light itself. neon: red, the sign and blood
# and nothing else. cold: the green-white of fluorescent tubes and TV light. earth: brick and sepia,
# for skin, wood, leather and beer, the warm things the light falls on.
INKS = {'night': '#1b2130', 'lamp': '#f0a23c', 'neon': '#d9382c', 'cold': '#8fc7b8', 'earth': '#9a5a3c'}
ORDER = ('night', 'lamp', 'neon', 'cold', 'earth')


def hex_rgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lin(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def oklab(rgb_lin):
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = rgb_lin @ m1.T
    return np.cbrt(np.maximum(lms, 0.0)) @ m2.T


# ------------------------------------------------------------------ separation

def mixes(steps):
    """The mixes the press prints: the night ink with up to two of the colour inks, each at `steps`
    levels, and the colour each mix prints on the paper. Never three colours on one spot: the
    print stays clean, the way a few inks on a poster are."""
    paper = lin(hex_rgb(PAPER))
    ks = [lin(hex_rgb(INKS[k])) for k in ORDER]
    c = np.linspace(0.0, 1.0, steps)
    sets = []
    for i, j in itertools.combinations(range(1, len(ORDER)), 2):
        cn, ci, cj = np.meshgrid(c, c, c, indexing='ij')
        cov = np.zeros((cn.size, len(ORDER)))
        cov[:, 0], cov[:, i], cov[:, j] = cn.ravel(), ci.ravel(), cj.ravel()
        sets.append(cov)
    cov = np.unique(np.concatenate(sets), axis=0)
    col = np.ones((len(cov), 3)) * paper
    for i, k in enumerate(ks):
        col *= 1.0 - cov[:, i:i + 1] * (1.0 - k)                           # inks filter the light they sit on
    return cov, oklab(col)


def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def separation(n=33, steps=21, chroma=1.5, green=2.4, economy=0.004, lamp_dark=3.0, cold_cheap=0.6, earth_dark=0.6,
               red_gate=0.08):
    """For every rendered colour, how much of each ink prints.

    The rendered picture's white is the bare paper and its black is solid night ink, so the whole
    range of the render lands inside what the press can print. A grey in the render prints as a
    tint of the night ink alone; only colour in the render brings in the colour inks, each where it
    belongs: the lamp ink for warm light (it costs more the darker the colour, so what the light
    falls on, a face, the bar, a jacket, prints in the earth ink instead), the cold ink for the
    tubes' and the screens' green-white (a green-white is a faint colour, so greens are taken
    stronger than the rest, and the cold ink is cheap), and the neon ink only for a red as strong
    as the sign's (anything less red pays for it heavily).
    """
    cov, lab = mixes(steps)
    # the night ink alone, from bare paper to solid: the print's grey scale
    c1 = np.linspace(0.0, 1.0, 1001)
    paper = lin(hex_rgb(PAPER)); night = lin(hex_rgb(INKS['night']))
    axis = oklab(paper * (1.0 - c1[:, None] * (1.0 - night)))                # L falls as c1 rises
    Lp, Lk = axis[0, 0], axis[-1, 0]
    g = np.linspace(0.0, 1.0, n)
    r, gg, b = np.meshgrid(g, g, g, indexing='ij')
    tgt = np.stack([r.ravel(), gg.ravel(), b.ravel()], axis=1)
    t = oklab(lin(tgt))
    tL = np.clip(t[:, 0], 0, 1)
    L = Lk + tL * (Lp - Lk)                                                 # the render's range onto the press's
    na = np.interp(-L, -axis[:, 0], axis[:, 1])                             # the night-ink grey at that lightness
    nb = np.interp(-L, -axis[:, 0], axis[:, 2])
    C = np.hypot(t[:, 1], t[:, 2])
    hue = np.degrees(np.arctan2(t[:, 2], t[:, 1]))
    greens = smooth(hue, 90.0, 125.0) * (1.0 - smooth(hue, 185.0, 215.0))
    ch = (chroma + (green - chroma) * greens) * (0.55 + 0.45 * np.clip(tL / 0.55, 0, 1))   # dark colours keep less
    want = np.stack([L, na + t[:, 1] * ch, nb + t[:, 2] * ch], axis=1)
    # what each ink costs at each colour
    dim = 1.0 + 2.0 * (1.0 - tL)                                            # colour ink costs more in the dark
    sat = C / np.maximum(tL, 0.12)
    red = smooth(sat, 0.14, 0.24) * (1.0 - smooth(hue, 36.0, 46.0)) * (1.0 - smooth(-hue, 40.0, 60.0))
    w = np.zeros((len(tgt), len(ORDER)))
    # the lamp ink is the light itself: bright, or a strong yellow-orange even where it's dim (the
    # sodium's pool far off); a dim, weak or redder warm is a thing the light's on, in the earth ink
    light = smooth(sat, 0.14, 0.2) * smooth(hue, 60.0, 66.0)
    w[:, 1] = economy * dim * (1.0 + lamp_dark * (1.0 - smooth(tL, 0.55, 0.85)) * (1.0 - light))
    w[:, 2] = economy * dim + red_gate * (1.0 - red)
    w[:, 3] = economy * dim * cold_cheap
    w[:, 4] = economy * (1.0 + earth_dark * (1.0 - tL))                      # the earth's for the half-lit warm things
    # nearest mix: |want - lab|^2 + cost, as products so it's quick
    lab32 = lab.astype(np.float32)
    ll = (lab32 ** 2).sum(axis=1)
    covT = cov.T.astype(np.float32)
    best = np.empty((len(tgt), len(ORDER)))
    for s in range(0, len(tgt), 1024):
        wt = want[s:s + 1024].astype(np.float32)
        d = ll[None, :] - 2.0 * (wt @ lab32.T) + w[s:s + 1024].astype(np.float32) @ covT
        best[s:s + 1024] = cov[d.argmin(axis=1)]
    lut = best.reshape(n, n, n, len(ORDER))                                 # [r, g, b, ink]
    # smooth it a little so neighbouring colours don't jump between very different mixes
    k = np.array([0.25, 0.5, 0.25])
    for ax in range(3):
        pad = [(0, 0)] * 4
        pad[ax] = (1, 1)
        p = np.pad(lut, pad, mode='edge')
        sl = lambda a, b: tuple(slice(a, b) if i == ax else slice(None) for i in range(4))
        lut = k[0] * p[sl(0, -2)] + k[1] * p[sl(1, -1)] + k[2] * p[sl(2, None)]
    for name, inks in (('separation.png', (0, 1, 2)), ('separation_b.png', (3, 4))):
        img = np.zeros((n, n * n, 3))
        for bi in range(n):
            sl = lut[:, :, bi, :].transpose(1, 0, 2)                        # y = green, x = red
            for ch_i, ink in enumerate(inks):
                img[:, bi * n:(bi + 1) * n, ch_i] = sl[:, :, ink]
        Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8)).save(os.path.join(OUT, name))
    return lut


# ------------------------------------------------------------------ grain and paper

def tiling_noise(size, lo, hi, aniso=(1.0, 1.0)):
    """Noise that tiles, keeping the features between lo and hi pixels across."""
    w = rng.standard_normal((size, size))
    f = np.fft.fftfreq(size)
    fx, fy = np.meshgrid(f / aniso[0], f / aniso[1])
    rad = np.sqrt(fx ** 2 + fy ** 2)
    band = np.exp(-(rad * lo) ** 2 * 4.0) - np.exp(-(rad * hi) ** 2 * 4.0) if hi else np.exp(-(rad * lo) ** 2 * 4.0)
    return np.real(np.fft.ifft2(np.fft.fft2(w) * band))


def ranked(a):
    """Spread values evenly over 0..1, so a threshold at c covers a fraction c."""
    flat = a.ravel()
    out = np.empty_like(flat)
    out[flat.argsort()] = (np.arange(flat.size) + 0.5) / flat.size
    return out.reshape(a.shape)


def grain(size=128):
    ch = [ranked(tiling_noise(size, 0.9, 5.0)) for _ in range(3)]          # clumps of a pixel or two
    img = np.stack(ch, axis=2)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, 'grain.png'))


def paper(size=512):
    """r: the tooth and the fibres; g and b: two slow mottles, for how unevenly the ink lies."""
    tooth = tiling_noise(size, 0.0, 3.0)
    fibres = sum(tiling_noise(size, 0.0, 22.0, aniso) for aniso in ((6.0, 1.0), (1.0, 5.0), (4.0, 2.5)))
    def norm(a):
        return (a - a.mean()) / (a.std() + 1e-9)
    r = 0.5 + 0.16 * norm(tooth) + 0.12 * norm(fibres)
    g = 0.5 + 0.2 * norm(tiling_noise(size, 0.0, 70.0))
    b = 0.5 + 0.2 * norm(tiling_noise(size, 0.0, 70.0))
    img = np.stack([r, g, b], axis=2)
    Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8)).save(os.path.join(OUT, 'paper.png'))


if __name__ == '__main__':
    import sys
    lut = separation()
    if '--separation' not in sys.argv:
        grain()
        paper()
    # a check: how a few colours print
    for name, rgb in [('white', (1, 1, 1)), ('black', (0, 0, 0)), ('mid grey', (0.5, 0.5, 0.5)),
                      ('lamp-lit wall', (0.78, 0.6, 0.4)), ('neon on gravel', (0.5, 0.12, 0.12)),
                      ('night lot', (0.12, 0.13, 0.17)), ('sodium', (0.9, 0.6, 0.25)), ('cool TV', (0.6, 0.7, 0.85)),
                      ('dark red', (0.2, 0.05, 0.05)), ('dark warm', (0.2, 0.14, 0.09)), ('felt', (0.3, 0.4, 0.3)),
                      ('skin lit', (0.85, 0.66, 0.52)), ('skin shade', (0.45, 0.3, 0.22)), ('bar top', (0.42, 0.24, 0.12)),
                      ('tube-lit wall', (0.82, 0.92, 0.86)), ('hi-vis', (0.75, 0.85, 0.2)), ('sign red', (0.95, 0.25, 0.15)),
                      ('deep shadow', (0.04, 0.04, 0.05))]:
        i = [int(round(v * 32)) for v in rgb]
        print(f'{name:16s} ' + '  '.join(f'{k} {lut[i[0], i[1], i[2], j]:.2f}' for j, k in enumerate(ORDER)))
