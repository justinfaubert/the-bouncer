"""The gas station south of the Sov, made over: LESSO (less of everything), its oval, its store
sign, the cardboard woman with the slush at the door, the sandwich board, the dead charger's bag,
the air machine, the paper box, the firewood and the washer fluid, a sticker on the pump, and the
end wall round the payphone. Into textures/dress_lesso_*.png, the same way as dressing.py's.

  python3 tools/lesso.py [logo sign standee board_a board_b ev air news wood fluid pump phone]

The standee is the posed girl render tools/poster_girls makes (the "slush" pose), from GIRLS_WORK.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dressing import Sheet, age, font, noise, save  # noqa: E402
from dressing2 import _layer  # noqa: E402

WORK = os.environ.get('GIRLS_WORK', '/tmp/claude-0/work')
RED, BLUE, CREAM, INK = 'd4232e', '1f3f8f', 'f4efe0', '1a1814'


def logo(w=640, h=320):
    """The oval: red, a blue rim, LESSO across it in white. Read from the highway at night."""
    sh = _layer(w, h)
    sh.ellipse(4, 4, w - 4, h - 4, BLUE)
    sh.ellipse(22, 22, w - 22, h - 22, 'f6f4ee')
    sh.ellipse(34, 34, w - 34, h - 34, RED)
    sh.text((w / 2, h / 2 + 6), 'LESSO', font('archivo-black-400', 150), 'f6f4ee', anchor='mm', track=4)
    save(sh.done(), 'lesso_logo')


def sign(w=1600, h=110):
    """The store's band: LESSO MARKET, OPEN 24 HOURS*."""
    sh = Sheet(w, h, 'f6f4ee')
    sh.rect(0, 0, w, 14, RED)
    sh.rect(0, h - 14, w, h, BLUE)
    sh.text((40, h / 2), 'LESSO', font('archivo-black-400', 64), RED, anchor='lm')
    sh.text((330, h / 2 + 2), 'MARKET', font('anton-400', 60), BLUE, anchor='lm', track=6)
    sh.text((w - 60, h / 2), 'OPEN 24 HOURS*', font('anton-400', 54), INK, anchor='rm')
    sh.text((w * 0.52, h / 2), 'GAS  ·  SMOKES  ·  LOTTO  ·  ICE  ·  REGRET', font('barlow-condensed-600', 34), INK, anchor='mm')
    save(age(sh.done(), 301, sun=0.25, yellow=0.1, fox=0.0, grime=0.5), 'lesso_sign')


def standee():
    """The cardboard woman by the door, holding out a slush: BRAIN FREEZE, any size 99 cents."""
    src = Image.open(os.path.join(WORK, 'girl_slush.png')).convert('RGBA')
    bb = src.getbbox()
    girl = src.crop(bb)
    w, h = 520, 1100
    gh = 880
    girl = girl.resize((int(girl.width * gh / girl.height), gh), Image.LANCZOS)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gx = (w - girl.width) // 2
    im.alpha_composite(girl, (gx, 70))
    # the base panel she stands on, and the headline over her
    sh = _layer(w, h)
    sh.rect(10, 900, w - 10, h - 6, RED)
    sh.rect(10, 900, w - 10, 912, 'f6f4ee')
    sh.text((w / 2, 960), 'BRAIN FREEZE', font('anton-400', 70), 'f6f4ee', anchor='mm')
    sh.text((w / 2, 1022), 'ANY SIZE  99¢', font('archivo-black-400', 40), 'f4d84a', anchor='mm')
    sh.text((w / 2, 1068), 'feel nothing for a minute', font('barlow-condensed-600', 30), 'f6f4ee', anchor='mm')
    sh.text((w / 2, 38), 'NEW!  CHERRY BLAST', font('anton-400', 44), RED, anchor='mm')
    im.alpha_composite(sh.done())
    # cut out round all of it, the cardboard's white margin, then the brown edge of the board
    a = np.asarray(im)[..., 3]
    m = Image.fromarray(((a > 20) * 255).astype(np.uint8))
    white = m.filter(ImageFilter.MaxFilter(15))
    edge = white.filter(ImageFilter.MaxFilter(5))
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste((150, 112, 70, 255), (0, 0), edge)
    out.paste((246, 244, 236, 255), (0, 0), white)
    out.alpha_composite(im)
    # sun through the window has had her for a few summers: the blue's gone first, then the red
    o = np.asarray(out, dtype=np.float32)
    rgbv = o[..., :3] / 255.0
    rgbv = rgbv * np.array([1.0, 0.93, 0.8]) + 0.08
    o[..., :3] = np.clip(rgbv, 0, 1) * 255
    out = Image.fromarray(o.astype(np.uint8), 'RGBA')
    save(age(out, 302, sun=0.3, yellow=0.25, fox=0.2, grime=0.5), 'lesso_standee')


def _chalk(name, lines, seed):
    w, h = 400, 560
    sh = Sheet(w, h, '1c201e')
    for t, f, sz, col, y in lines:
        sh.text((w / 2, y), t, font(f, sz), col, anchor='mm', rot=float(np.sin(y + seed) * 1.5))
    im = sh.done()
    a = np.asarray(im, dtype=np.float32)
    # chalk: broken up, and the ghosts of what was rubbed off under it
    n = noise(h, w, 2, seed)
    a[..., :3] = a[..., :3] * (0.72 + 0.28 * n[..., None]) + 14 * noise(h, w, 30, seed + 1)[..., None]
    save(age(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA'), seed, sun=0.0, yellow=0.0, fox=0.0, grime=0.6), name)


def boards():
    c = 'efece2'
    _chalk('lesso_board_a', [('LIVE BAIT', 'anton-400', 66, c, 70), ('COLD POP', 'anton-400', 56, 'f0c8c8', 150),
                             ('ICE', 'anton-400', 56, 'c8e0f0', 222), ('NALOXONE', 'anton-400', 56, 'f4e08a', 300),
                             ('free.  ask.', 'kalam-400', 36, c, 360), ('no lecture.', 'kalam-400', 36, c, 404),
                             ('(the worms are $4.99)', 'kalam-300', 28, c, 480)], 311)
    _chalk('lesso_board_b', [('NIGHTCRAWLERS', 'anton-400', 50, c, 70), ('$4.99 / dozen', 'kalam-400', 40, 'f4e08a', 136),
                             ('our worms are local', 'kalam-400', 34, c, 220), ('(so are we.  sorry.)', 'kalam-300', 30, c, 264),
                             ('ASK ABOUT', 'anton-400', 40, 'f0c8c8', 360), ('OUR HOT DOGS', 'anton-400', 40, 'f0c8c8', 410),
                             ("they're fine", 'kalam-400', 30, c, 470)], 312)


def _card(name, w, h, ground, lines, seed, rot=0.0, tape=True):
    sh = Sheet(w, h, ground)
    for t, f, sz, col, y in lines:
        sh.text((w / 2, y), t, font(f, sz), col, anchor='mm', rot=rot)
    tp = [(0.5, 0.04, 60, 16, -4)] if tape else ()
    save(age(sh.done(), seed, sun=0.35, yellow=0.2, fox=0.2, grime=0.4, tape=tp), name)


def small():
    k = 'kalam-400'
    _card('lesso_ev', 360, 260, 'f4f4ee', [('OUT OF ORDER', 'anton-400', 52, INK, 60), ('since the rebate ended', k, 28, INK, 124),
                                           ('- mgmt', k, 26, INK, 164), ('the gas pumps work fine :)', k, 22, '2a3a8a', 216)], 321)
    _card('lesso_air', 300, 300, 'f4d84a', [('AIR', 'anton-400', 110, INK, 82), ('$2', 'anton-400', 80, RED, 178),
                                            ('it used to be free', 'barlow-condensed-600', 26, INK, 236), ('so did a lot of things', 'barlow-condensed-600', 26, INK, 268)], 322, tape=False)
    _card('lesso_wood', 340, 240, 'e8dcc0', [('FIREWOOD', 'anton-400', 56, '5a2a14', 52), ('$9  dry-ish', 'anton-400', 40, INK, 112),
                                             ('honour system', k, 28, INK, 164), ('(there is a camera)', k, 24, INK, 198), ('(it is a box)', k, 20, '6a6a6a', 226)], 323)
    _card('lesso_fluid', 300, 200, 'f4f4ee', [('-40° WASHER', 'anton-400', 42, BLUE, 46), ('2 for $9', 'anton-400', 48, RED, 104),
                                              ("it has never once been -40 here", 'barlow-condensed-600', 21, INK, 150), ("but you never know, do you", 'barlow-condensed-400', 20, INK, 178)], 324)
    _card('lesso_pump', 220, 140, 'f4f4ee', [('PAY INSIDE', 'anton-400', 34, RED, 34), ('card reader', 'barlow-condensed-600', 24, INK, 74),
                                             ('has feelings', 'barlow-condensed-600', 24, INK, 102), ('swipe gently', k, 20, '2a3a8a', 128)], 325)


def news(w=360, h=300):
    """Through the paper box's window: the top half of the front page."""
    sh = Sheet(w, h, 'efeadc')
    sh.text((w / 2, 30), 'THE ISLAND SENTINEL', font('zilla-slab-600', 30), INK, anchor='mm')
    sh.rect(14, 50, w - 14, 52, INK)
    sh.text((w / 2, 64), 'TOMORROW  ·  $2.50  ·  WEATHER: YES', font('barlow-condensed-600', 15), INK, anchor='mm')
    sh.text((w / 2, 104), 'LOCAL MAN READS', font('anton-400', 38), INK, anchor='mm')
    sh.text((w / 2, 144), 'HEADLINE, LEAVES', font('anton-400', 38), INK, anchor='mm')
    sh.rect(18, 172, 190, 286, '8a8478')
    sh.ellipse(70, 190, 130, 250, '5a554c')
    sh.rect(80, 240, 120, 286, '5a554c')
    for i in range(9):
        sh.rect(200, 176 + i * 12, w - 18, 182 + i * 12, 'a8a294')
    sh.text((275, 290), 'Ferry cancelled, A3', font('barlow-condensed-400', 14), INK, anchor='mm')
    save(age(sh.done(), 331, sun=0.2, yellow=0.35, fox=0.1, grime=0.2), 'lesso_news')


def phone(w=1400, h=1000):
    """The end wall round the payphone, in Sharpie and key, and a sticker or two."""
    sh = _layer(w, h)
    k = lambda sz: font('kalam-400', int(sz * 1.4))
    sh.text((700, 70), 'THIS PHONE HAS NOT BEEN CONNECTED SINCE 2012', font('anton-400', 40), INK, anchor='mm', rot=1)
    sh.text((760, 120), 'so who keeps calling', k(34), '2a3a8a', anchor='mm', rot=-2, stroke=1, stroke_fill=None)
    sh.text((260, 240), 'GAS WAS $1.09', font('archivo-black-400', 34), INK, anchor='mm', rot=3)
    sh.text((250, 284), 'I was there', k(26), INK, anchor='mm', rot=1, stroke=1, stroke_fill=None)
    sh.text((300, 318), "you're old", k(22), '7a1a14', anchor='mm', rot=-4, stroke=1, stroke_fill=None)
    sh.text((1150, 250), 'the kid inside', k(32), INK, anchor='mm', rot=-1, stroke=1, stroke_fill=None)
    sh.text((1160, 292), 'is a robot', k(32), INK, anchor='mm', rot=-1, stroke=1, stroke_fill=None)
    sh.text((1190, 336), "I'm not. - the kid", k(24), '2a5a3a', anchor='mm', rot=2, stroke=1, stroke_fill=None)
    sh.text((1210, 370), '(four cents)', k(20), '2a5a3a', anchor='mm', rot=2, stroke=1, stroke_fill=None)
    sh.text((700, 470), 'GOD IS A PAYPHONE', font('anton-400', 46), '4a1a5a', anchor='mm', rot=-2)
    sh.text((710, 520), 'you have to put something in', k(30), '4a1a5a', anchor='mm', rot=-1, stroke=1, stroke_fill=None)
    sh.text((740, 556), 'and nobody picks up', k(24), INK, anchor='mm', rot=2, stroke=1, stroke_fill=None)
    sh.text((250, 640), 'TAXES DONE', font('anton-400', 36), INK, anchor='mm', rot=-3)
    sh.text((250, 680), 'cash, no questions', k(26), INK, anchor='mm', rot=-3, stroke=1, stroke_fill=None)
    sh.text((250, 714), 'ask for Ron (not that Ron)', k(22), INK, anchor='mm', rot=-3, stroke=1, stroke_fill=None)
    sh.text((1150, 650), "I'm leaving this island", k(30), INK, anchor='mm', rot=1, stroke=1, stroke_fill=None)
    sh.text((1170, 690), '- everybody, every spring', k(24), INK, anchor='mm', rot=1, stroke=1, stroke_fill=None)
    sh.text((700, 860), 'CALL YR MOTHER', font('archivo-black-400', 54), INK, anchor='mm', rot=-1)
    sh.text((740, 920), 'she knows you read this', k(26), '7a1a14', anchor='mm', rot=2, stroke=1, stroke_fill=None)
    # a sticker: BRING BACK THE MILL, half peeled
    sh.rect(1040, 790, 1290, 880, '2a5a3a', 'f2ead2', 3)
    sh.text((1165, 820), 'BRING BACK', font('barlow-condensed-600', 26), 'f2ead2', anchor='mm')
    sh.text((1165, 856), 'THE MILL', font('anton-400', 32), 'f2ead2', anchor='mm')
    sh.d.polygon(sh.s([(1230, 790), (1290, 790), (1290, 850)]), fill=(0, 0, 0, 0))
    im = sh.done()
    a = np.asarray(im, dtype=np.float32)
    a[..., 3] *= 0.9 * (0.78 + 0.22 * noise(h, w, 6, 341))
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA'), 'lesso_phone')


ALL = {'logo': logo, 'sign': sign, 'standee': standee, 'boards': boards, 'small': small, 'news': news, 'phone': phone}

if __name__ == '__main__':
    for k in sys.argv[1:] or ALL:
        ALL[k]()
