"""The press: makes the textures the print shader needs.

  press/separation.png   how much of each ink prints for any rendered colour: a 33x33x33 table
                         laid out as 33 slices side by side (x = red + 33 * blue, y = green);
                         r = the night ink, g = the lamp ink, b = the neon ink
  press/grain.png        three grain screens, one per ink (r, g, b), 128 px square, tiling
  press/paper.png        the paper: r its tooth and fibres, g and b two slow mottles; 512 px square, tiling

The inks are defined here and again in press.gdshader; change them in both.

  python3 tools/press.py
"""
import numpy as np
from PIL import Image
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'press')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(28)

PAPER = '#eae2cf'                                                           # the build's stock
INKS = {'night': '#1b2130', 'lamp': '#f0a23c', 'neon': '#d9382c'}


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
    """Every mix of the three inks at `steps` levels each, and the colour it prints on the paper."""
    paper = lin(hex_rgb(PAPER))
    ks = [lin(hex_rgb(INKS[k])) for k in ('night', 'lamp', 'neon')]
    c = np.linspace(0.0, 1.0, steps)
    cn, cl, cr = np.meshgrid(c, c, c, indexing='ij')
    cov = np.stack([cn.ravel(), cl.ravel(), cr.ravel()], axis=1)
    col = np.ones((len(cov), 3)) * paper
    for i, k in enumerate(ks):
        col *= 1.0 - cov[:, i:i + 1] * (1.0 - k)                           # inks filter the light they sit on
    return cov, oklab(col)


def separation(n=33, steps=21, chroma=1.5, economy=0.004):
    """For every rendered colour, how much of each ink prints.

    The rendered picture's white is the bare paper and its black is solid night ink, so the whole
    range of the render lands inside what the press can print. A grey in the render prints as a
    tint of the night ink alone; only colour in the render brings in the lamp and neon inks, so the
    warm light prints amber, the sign prints red, and plain shadow stays blue-black.
    """
    cov, lab = mixes(steps)
    # the night ink alone, from bare paper to solid: the print's grey scale
    c1 = np.linspace(0.0, 1.0, 1001)
    solo = np.zeros((1001, 3)); solo[:, 0] = c1
    paper = lin(hex_rgb(PAPER)); night = lin(hex_rgb(INKS['night']))
    axis = oklab(paper * (1.0 - c1[:, None] * (1.0 - night)))                # L falls as c1 rises
    Lp, Lk = axis[0, 0], axis[-1, 0]
    g = np.linspace(0.0, 1.0, n)
    r, gg, b = np.meshgrid(g, g, g, indexing='ij')
    tgt = np.stack([r.ravel(), gg.ravel(), b.ravel()], axis=1)
    t = oklab(lin(tgt))
    L = Lk + np.clip(t[:, 0], 0, 1) * (Lp - Lk)                             # the render's range onto the press's
    na = np.interp(-L, -axis[:, 0], axis[:, 1])                             # the night-ink grey at that lightness
    nb = np.interp(-L, -axis[:, 0], axis[:, 2])
    ch = chroma * (0.55 + 0.45 * np.clip(t[:, 0] / 0.55, 0, 1))              # dark colours keep less of it
    want = np.stack([L, na + t[:, 1] * ch, nb + t[:, 2] * ch], axis=1)
    dim = 1.0 + 2.0 * (1.0 - np.clip(t[:, 0], 0, 1))                          # colour ink costs more in the dark
    cost = economy * (cov[None, :, 1] + cov[None, :, 2])
    best = np.empty((len(tgt), 3))
    for s in range(0, len(tgt), 256):
        d = ((want[s:s + 256, None, :] - lab[None, :, :]) ** 2).sum(axis=2) + cost * dim[s:s + 256, None]
        best[s:s + 256] = cov[d.argmin(axis=1)]
    lut = best.reshape(n, n, n, 3)                                          # [r, g, b, ink]
    # smooth it a little so neighbouring colours don't jump between very different mixes
    k = np.array([0.25, 0.5, 0.25])
    for ax in range(3):
        pad = [(0, 0)] * 4
        pad[ax] = (1, 1)
        p = np.pad(lut, pad, mode='edge')
        sl = lambda a, b: tuple(slice(a, b) if i == ax else slice(None) for i in range(4))
        lut = k[0] * p[sl(0, -2)] + k[1] * p[sl(1, -1)] + k[2] * p[sl(2, None)]
    img = np.zeros((n, n * n, 3))
    for bi in range(n):
        img[:, bi * n:(bi + 1) * n, :] = lut[:, :, bi, :].transpose(1, 0, 2)  # y = green, x = red
    Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8)).save(os.path.join(OUT, 'separation.png'))
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
    lut = separation()
    grain()
    paper()
    # a check: how a few colours print
    for name, rgb in [('white', (1, 1, 1)), ('black', (0, 0, 0)), ('mid grey', (0.5, 0.5, 0.5)),
                      ('lamp-lit wall', (0.78, 0.6, 0.4)), ('neon on gravel', (0.5, 0.12, 0.12)),
                      ('night lot', (0.12, 0.13, 0.17)), ('sodium', (0.9, 0.6, 0.25)), ('cool TV', (0.6, 0.7, 0.85)),
                      ('dark red', (0.2, 0.05, 0.05)), ('dark warm', (0.2, 0.14, 0.09)), ('felt', (0.3, 0.4, 0.3)),
                      ('skin lit', (0.85, 0.66, 0.52)), ('deep shadow', (0.04, 0.04, 0.05))]:
        i = [int(round(v * 32)) for v in rgb]
        print(f'{name:16s} night {lut[i[0], i[1], i[2], 0]:.2f}  lamp {lut[i[0], i[1], i[2], 1]:.2f}  neon {lut[i[0], i[1], i[2], 2]:.2f}')
