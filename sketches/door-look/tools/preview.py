"""Preview the press on a rendered picture, without Godot: python3 tools/preview.py in.png out.png"""
import sys, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import press as P

def load_lut(n=33):
    img = np.asarray(Image.open(os.path.join(P.OUT, 'separation.png')).convert('RGB')).astype(np.float64) / 255.0
    lut = np.zeros((n, n, n, 3))
    for bi in range(n):
        lut[:, :, bi, :] = img[:, bi * n:(bi + 1) * n, :].transpose(1, 0, 2)
    return lut

def trilinear(lut, rgb):
    n = lut.shape[0]
    x = np.clip(rgb, 0, 1) * (n - 1)
    i0 = np.floor(x).astype(int); i0 = np.clip(i0, 0, n - 2); f = x - i0
    out = 0
    for dr in (0, 1):
        for dg in (0, 1):
            for db in (0, 1):
                w = (f[..., 0] if dr else 1 - f[..., 0]) * (f[..., 1] if dg else 1 - f[..., 1]) * (f[..., 2] if db else 1 - f[..., 2])
                out = out + w[..., None] * lut[i0[..., 0] + dr, i0[..., 1] + dg, i0[..., 2] + db]
    return out

def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

def main(src, dst, soft=0.12, gscale=1.6, levels=0, crop_w=None):
    img = np.asarray(Image.open(src).convert('RGB')).astype(np.float64) / 255.0
    if crop_w:
        img = img[:, :crop_w]
    h, w, _ = img.shape
    lut = load_lut()
    grain = np.asarray(Image.open(os.path.join(P.OUT, 'grain.png')).convert('RGB')).astype(np.float64) / 255.0
    paper = np.asarray(Image.open(os.path.join(P.OUT, 'paper.png')).convert('L')).astype(np.float64) / 255.0
    offs = [(0, 0), (1, -1), (-1, 1)]
    ink = [P.lin(P.hex_rgb(P.INKS[k])) for k in ('night', 'lamp', 'neon')]
    col = np.ones((h, w, 3)) * P.lin(P.hex_rgb(P.PAPER))
    yy, xx = np.mgrid[0:h, 0:w]
    for i in range(3):
        sh = np.roll(np.roll(img, offs[i][1], axis=0), offs[i][0], axis=1)
        c = trilinear(lut, sh)[..., i]
        if levels:
            c = np.round(c * levels) / levels
        gy = (yy / gscale).astype(int) % grain.shape[0]; gx = (xx / gscale).astype(int) % grain.shape[1]
        g = grain[gy, gx, i]
        k = smoothstep(g - soft, g + soft, c)
        col *= 1.0 - k[..., None] * (1.0 - ink[i])
    py = yy % paper.shape[0]; px = xx % paper.shape[1]
    col *= (0.93 + 0.1 * paper[py, px])[..., None]
    out = np.where(col <= 0.0031308, col * 12.92, 1.055 * np.power(np.clip(col, 0, None), 1 / 2.4) - 0.055)
    Image.fromarray(np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8)).save(dst)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], crop_w=int(sys.argv[3]) if len(sys.argv) > 3 else None)
