"""Find the echo tell: two sentences side by side that open the same way.

"The door was the job. The door was always the job." "He knew the type. He knew all the types."
Hutch, 23 November 2026: "a lot of the writing still has AIisms in it like.. 'X was the Y. X was
always the Y'". This lists every pair of neighbouring sentences (in one line, or across two
narration lines in a row) whose first two words match, and flags the worst kind, where the
second sentence is the first with one word slipped in (always, still, just, only, never, all).

  python3 tools/echoes.py                      every Ink file, worst first
  python3 tools/echoes.py content/ink/door.ink one file
  python3 tools/echoes.py --count              totals per file only
"""
import re, sys, os, glob, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tells import text_lines, ROOT
SLIP = {'always','still','just','only','never','all','really','also','even','ever','already','both'}
SENT = re.compile(r'[^.!?]+[.!?]+["”]?')
def words(s): return re.findall(r"[a-z0-9']+", s.lower())
def sentences(t): return [x.strip() for x in SENT.findall(t) if x.strip()]
def judge(a, b):
    wa, wb = words(a), words(b)
    if len(wa) < 2 or len(wb) < 2: return None
    if wa[:2] != wb[:2]: return None
    if wa[:2] in (['i', 'don\'t'],) : pass
    # slip-in: b == a with one or two extra words, or same frame "X was the Y" / "X was always the Z"
    extra = [w for w in wb if w not in wa]
    worst = any(w in SLIP for w in wb[2:4]) or (len(wa) <= 8 and len(wb) <= 10 and len(set(wa) & set(wb)) >= len(wa) - 2)
    return 'WORST' if worst else 'echo'
def scan(path):
    rows = text_lines(path); hits = []
    prev = None
    for r in rows:
        ss = sentences(r['text'])
        pairs = list(zip(ss, ss[1:]))
        if prev and prev['kind'] == r['kind'] == 'narr' and prev['n'] == r['n'] - 1 and ss:
            ps = sentences(prev['text'])
            if ps: pairs.insert(0, (ps[-1], ss[0]))
        for a, b in pairs:
            j = judge(a, b)
            if j: hits.append((j, r['file'], r['n'], r['sp'], a, b))
        prev = r
    return hits
if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    files = args or sorted(glob.glob(os.path.join(ROOT, '*.ink')))
    allh = []
    for f in files: allh += scan(f)
    if '--count' in sys.argv:
        c = collections.Counter((h[1], h[0]) for h in allh)
        for f in sorted({h[1] for h in allh}): print(f'{f:16} worst {c[(f,"WORST")]:3}  echo {c[(f,"echo")]:3}')
        print('total', len(allh), 'worst', sum(1 for h in allh if h[0]=='WORST'))
    else:
        for h in sorted(allh, key=lambda h: (h[0] != 'WORST', h[1], h[2])):
            print(f'{h[0]:5} {h[1]}:{h[2]} {h[3]+": " if h[3] else ""}{h[4]} | {h[5]}')
