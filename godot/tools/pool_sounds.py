"""The pool table's own sounds, rendered to audio/ as .wav (placeholders until the real table is
recorded; a recording of the same name in audio/ replaces one). Built from tools/dart_sounds.py's
pieces: a transient for the contact, then the modes of whatever rings, damped, a little different
from take to take.

Kept low and round on purpose: a bar's pool table heard from across the room is wood and slate
and a thick cloth, not a shriek. The click of two balls is the one bright thing, and even that is
short and has a body under it.

  python3 tools/pool_sounds.py      (numpy and scipy)
"""
import numpy as np
import dart_sounds as d
from dart_sounds import buf, band, lp, hp, modes, click, friction, takes

rng = d.rng


# two balls: phenolic on phenolic, a short click with a hollow knock under it (the balls are solid,
# but the table's bed answers)
def ball_click(k):
    o = buf(0.25)
    click(o, 0, 1800, 6500, 0.0007, 0.8)
    modes(o, 0, [(2350, 0.006, 0.5), (3900, 0.004, 0.25), (1150, 0.012, 0.35), (420, 0.03, 0.22)], 1.0, 0.05)
    o = lp(o, 6500)
    return o


# the cue's tip on the cue ball: leather, a soft thock, the shaft's ring after it, low
def cue_hit(k):
    o = buf(0.35)
    click(o, 0, 600, 3200, 0.0012, 0.7)
    modes(o, 0, [(780, 0.02, 0.45), (1460, 0.01, 0.25), (260, 0.05, 0.35), (2900, 0.004, 0.12)], 1.0, 0.06)
    return lp(o, 4500)


# the break: the tip, then the rack going, a cluster of clicks spreading out and a rumble of the
# table taking it
def break_shot(k):
    o = buf(1.4)
    ch = cue_hit(k)
    o[:len(ch)] += ch
    t = 0.035
    for i in range(22):
        sub = ball_click(i)
        i0 = int(t * d.SR)
        n = min(len(sub), len(o) - i0)
        o[i0:i0 + n] += sub[:n] * (1.0 if i < 5 else 0.75 ** ((i - 4) * 0.5)) * rng.uniform(0.5, 1.0)
        t += rng.exponential(0.012 if i < 8 else 0.045)
        if t > 1.1:
            break
    # the table's body: a low thud and the slate under it
    modes(o, 0.04, [(70, 0.12, 0.5), (115, 0.08, 0.35), (180, 0.05, 0.2)], 1.0, 0.04)
    return lp(o, 7000)


# a ball into a cushion: rubber under cloth on a wooden rail, a dull thump with the rail's wood in it
def rail(k):
    o = buf(0.3)
    click(o, 0, 120, 900, 0.004, 0.6)
    modes(o, 0, [(150, 0.05, 0.6), (240, 0.035, 0.4), (520, 0.015, 0.2), (95, 0.08, 0.3)], 1.0, 0.05)
    return lp(o, 1400)


# a ball rattling in the jaws: the facing's wood, harder than the cushion, two or three knocks
def jaw(k):
    o = buf(0.35)
    t = 0.0
    for i in range(2 + k % 2):
        click(o, t, 300, 2400, 0.002, 0.6 / (i + 1))
        modes(o, t, [(330, 0.025, 0.5), (690, 0.012, 0.25), (1300, 0.006, 0.12)], 1.0 / (i + 1), 0.05)
        t += rng.uniform(0.035, 0.06)
    return lp(o, 3000)


# into the pocket: the ball drops off the slate's edge into the coin-op's plastic gully, a hollow
# clunk, then it rolls off down the return
def drop(k):
    o = buf(1.1)
    click(o, 0, 200, 1600, 0.003, 0.5)
    modes(o, 0.0, [(190, 0.06, 0.6), (310, 0.04, 0.45), (620, 0.02, 0.2), (110, 0.1, 0.3)], 1.0, 0.06)
    # it rolls away: a low rumble in the channel, thinning out
    friction(o, 0.06, 0.8, 80, 600, 0.22, rate=34.0 + 8 * k)
    return lp(o, 2200)


# along the return and into the window at the foot: the rumble, then a knock on the ones already there
def gully(k):
    o = buf(1.0)
    friction(o, 0.0, 0.55, 70, 500, 0.3, rate=28.0 + 6 * k)
    for i in range(1 + k % 2):
        t = 0.55 + i * 0.07
        click(o, t, 900, 4500, 0.0008, 0.35 / (i + 1))
        modes(o, t, [(2100, 0.006, 0.3 / (i + 1)), (400, 0.03, 0.25 / (i + 1))], 1.0, 0.05)
    return lp(o, 4500)


# off the table onto the boards: a heavy thud, a bounce, a roll
def floor(k):
    o = buf(1.3)
    for i, (t, v) in enumerate([(0.0, 1.0), (0.21, 0.45), (0.33, 0.2)]):
        click(o, t, 80, 700, 0.006, 0.5 * v)
        modes(o, t, [(95, 0.08, 0.7 * v), (160, 0.05, 0.4 * v), (340, 0.02, 0.15 * v)], 1.0, 0.05)
    friction(o, 0.4, 0.8, 60, 400, 0.12, rate=22.0)
    return lp(o, 1500)


# a ball landing back on the slate after a jump: a knock with the bed in it
def bounce(k):
    o = buf(0.3)
    click(o, 0, 150, 1500, 0.003, 0.6)
    modes(o, 0, [(120, 0.05, 0.5), (260, 0.03, 0.35), (560, 0.012, 0.15)], 1.0, 0.05)
    return lp(o, 2000)


if __name__ == '__main__':
    takes('pool_click', 4, ball_click)
    takes('pool_cue', 3, cue_hit)
    takes('pool_break', 2, break_shot)
    takes('pool_rail', 3, rail)
    takes('pool_jaw', 2, jaw)
    takes('pool_drop', 3, drop)
    takes('pool_gully', 2, gully)
    takes('pool_floor', 2, floor)
    takes('pool_bounce', 2, bounce)
    print('pool sounds written')
