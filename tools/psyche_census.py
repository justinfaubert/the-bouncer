#!/usr/bin/env python3
"""psyche_census.py: enumerate the relational psyche states for The Bouncer.

Five voices are "in the room." Each of the ten relationships between them is
allied (+1) or at odds (-1). This script:

  1. enumerates all 2^10 = 1024 configurations,
  2. folds them into the 34 states that are distinct up to relabeling voices,
  3. folds those into the 7 classes that are distinct up to "switching"
     (one voice reversing all of its loyalties at once),
  4. computes tension (the frustration index: the fewest conflicts left
     after any combination of loyalty reversals, range 0-4),
  5. checks the properties the design relies on,
  6. writes data/psyche_states.json and prints a summary.

Requires numpy (for the spectrum used to order the classes).
Usage: python3 tools/psyche_census.py [--out data/psyche_states.json]
"""
import argparse
import itertools
import json
from pathlib import Path

import numpy as np

VOICES = range(5)
EDGES = list(itertools.combinations(VOICES, 2))  # the ten relationships
EIDX = {e: i for i, e in enumerate(EDGES)}
PERMS = list(itertools.permutations(VOICES))
SUBSETS = [frozenset(c) for r in range(6) for c in itertools.combinations(VOICES, r)]
LETTERS = "ABCDEFG"


def relabel(sig, perm):
    out = [0] * 10
    for (a, b), i in EIDX.items():
        x, y = sorted((perm[a], perm[b]))
        out[EIDX[(x, y)]] = sig[i]
    return tuple(out)


def canon(sig):
    """Canonical form of a configuration up to relabeling the voices."""
    return min(relabel(sig, p) for p in PERMS)


def switch(sig, subset):
    """Every voice in `subset` reverses all its loyalties to voices outside it."""
    return tuple(-x if ((a in subset) != (b in subset)) else x
                 for (a, b), x in zip(EDGES, sig))


def tension(sig):
    return min(sum(x < 0 for x in switch(sig, s)) for s in SUBSETS)


def class_key(sig):
    return min(canon(switch(sig, s)) for s in SUBSETS)


def mirror(sig):
    """Every relationship reversed at once."""
    return tuple(-x for x in sig)


def spectrum(sig):
    m = np.zeros((5, 5))
    for (a, b), i in EIDX.items():
        m[a, b] = m[b, a] = sig[i]
    return [round(float(v), 3) for v in np.linalg.eigvalsh(m)]


def conflicts(sig):
    return [list(e) for e, x in zip(EDGES, sig) if x < 0]


def degrees(sig):
    d = [0] * 5
    for a, b in (e for e, x in zip(EDGES, sig) if x < 0):
        d[a] += 1
        d[b] += 1
    return sorted(d)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default="data/psyche_states.json")
    args = ap.parse_args()

    labeled = list(itertools.product([1, -1], repeat=10))

    # 34 states, with how many of the 1024 configurations land on each
    counts = {}
    for s in labeled:
        c = canon(s)
        counts[c] = counts.get(c, 0) + 1

    # 7 classes, ordered by tension, then by largest eigenvalue (descending)
    groups = {}
    for c in counts:
        groups.setdefault(class_key(c), []).append(c)
    ordered = sorted(groups, key=lambda k: (tension(k), -max(spectrum(k)), k))
    letter_of_key = {k: LETTERS[i] for i, k in enumerate(ordered)}
    class_of_state = {c: letter_of_key[k] for k, members in groups.items() for c in members}

    # checks the design relies on
    step, reversal = set(), set()
    for s in labeled:
        t = tension(s)
        for i in range(10):
            u = list(s)
            u[i] = -u[i]
            step.add(tension(tuple(u)) - t)
        for v in VOICES:
            reversal.add(tension(switch(s, {v})) - t)
    assert len(counts) == 34, len(counts)
    assert len(groups) == 7, len(groups)
    assert step == {-1, 1}, step
    assert reversal == {0}, reversal

    # state ids: S01..S34, ordered by class, then number of conflicts
    states = sorted(counts, key=lambda c: (class_of_state[c], sum(x < 0 for x in c), c))
    sid = {c: f"S{i + 1:02d}" for i, c in enumerate(states)}

    def note(c):
        n = sum(x < 0 for x in c)
        if n == 0:
            return "all allied"
        if n == 10:
            return "all at odds"
        if canon(mirror(c)) == c:
            return ("conflicts form a five-cycle (the pentagon); its own mirror"
                    if degrees(c) == [2, 2, 2, 2, 2] else "the 'bull'; its own mirror")
        return ""

    out_states = [{
        "id": sid[c],
        "class": class_of_state[c],
        "tension": tension(c),
        "conflicts": conflicts(c),
        "n_conflicts": len(conflicts(c)),
        "conflict_degrees": degrees(c),
        "configurations": counts[c],
        "share": round(counts[c] / 1024, 5),
        "mirror": sid[canon(mirror(c))],
        "note": note(c),
    } for c in states]

    out_classes = []
    for k in ordered:
        members = sorted(groups[k], key=lambda c: sid[c])
        n = sum(counts[c] for c in members)
        out_classes.append({
            "class": letter_of_key[k],
            "tension": tension(k),
            "states": [sid[c] for c in members],
            "configurations": n,
            "share": round(n / 1024, 5),
            "spectrum": spectrum(k),
            "mirror": letter_of_key[class_key(mirror(k))],
        })

    doc = {
        "about": ("Relational psyche states for The Bouncer. Five voices; each of ten "
                  "relationships allied (+1) or at odds (-1). 'conflicts' lists the "
                  "at-odds pairs (voices 0-4) in a canonical labeling. 'tension' is the "
                  "frustration index (0-4). 'configurations' counts how many of the 1024 "
                  "labeled configurations land on the state. 'mirror' is the state or "
                  "class with every relationship reversed."),
        "verified": {
            "states": 34,
            "classes": 7,
            "one_relationship_change_moves_tension_by": sorted(step),
            "one_voice_reversing_all_loyalties_moves_tension_by": sorted(reversal),
        },
        "classes": out_classes,
        "states": out_states,
    }

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, indent=2) + "\n")

    print(f"34 states, 7 classes; checks passed. Wrote {out}")
    print(f"{'class':<6}{'states':>7}{'configs':>9}{'share':>9}{'tension':>9}  mirror  spectrum")
    for c in out_classes:
        print(f"{c['class']:<6}{len(c['states']):>7}{c['configurations']:>9}"
              f"{c['share']:>9.4f}{c['tension']:>9}  {c['mirror']:<6}  {c['spectrum']}")


if __name__ == "__main__":
    main()
