"""Count the tells that make prose read machine-written, in the Ink's player-facing text.

Narration, spoken lines and choice text only: comments, logic, tags and conditions are skipped, and an
inline {a|b} counts as its first branch. The list and the reasons for it are in bible/13_STYLE.md,
What reads like a machine. A count isn't a verdict: "all the way" and "the way it happened" are
literal, and a character can talk in similes. Read the lines it shows.

  python3 tools/tells.py                          every Ink file, totals
  python3 tools/tells.py content/ink/room.ink     one file
  python3 tools/tells.py --show 'as if/as though' and the lines for one tell (its name as printed)
  python3 tools/tells.py --show 'the way' --top 20
"""
import re, glob, os, sys, json, collections
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'ink')
SPEAKER = re.compile(r'^([A-Z][A-Z0-9_]+):\s*(.*)$')
def text_lines(path):
    out = []
    knot = stitch = ''
    for n, raw in enumerate(open(path, encoding='utf-8'), 1):
        l = raw.rstrip('\n')
        s = l.strip()
        m = re.match(r'^===\s*(?:function\s+)?(\w+)', s)
        if m: knot, stitch = m.group(1), ''; continue
        m = re.match(r'^=\s*(\w+)', s)
        if m: stitch = m.group(1); continue
        if not s or s.startswith('//') or s.startswith('~') or s.startswith('->') or s.startswith('<-') or s.startswith('VAR') or s.startswith('LIST') or s.startswith('CONST') or s.startswith('INCLUDE') or s.startswith('#'):
            continue
        # choices: keep the bracket text as choice
        kind = 'narr'
        if re.match(r'^[*+]', s):
            kind = 'choice'
            b = re.search(r'\[([^\]]*)\]', s)
            s = b.group(1) if b else re.sub(r'^[*+\s]+(\([^)]*\))?\s*(\{[^}]*\})?\s*', '', s)
        s = re.sub(r'^-+\s*(\([^)]*\))?\s*', '', s) if re.match(r'^-', s) else s
        if re.match(r'^[\w ?!=<>&|().,"\'-]+:\s*$', s):  # "- cond:" lines
            continue
        if s in ('{', '}') or s.startswith('{') and s.endswith('}') and '|' not in s and ':' not in s:
            continue
        s = re.sub(r'#.*$', '', s).strip()
        if not s or s.startswith('{') and s.rstrip().endswith(':'):
            continue
        sp = ''
        m = SPEAKER.match(s)
        if m and kind == 'narr':
            sp, s = m.group(1), m.group(2)
            kind = 'line'
        # flatten inline conditionals {a|b} -> a b ; {cond:x} -> x
        s2 = re.sub(r'\{[^{}]*?:([^{}|]*)\|([^{}]*)\}', r'\1', s)
        s2 = re.sub(r'\{[^{}]*?:([^{}]*)\}', r'\1', s2)
        s2 = re.sub(r'\{([^{}]*)\}', lambda m: m.group(1).split('|')[0], s2)
        out.append(dict(file=os.path.basename(path), n=n, knot=knot, stitch=stitch, kind=kind, sp=sp, text=s2))
    return out

PAT = collections.OrderedDict([
 ('the way', r'\bthe way\b'),
 ('as if/as though', r'\bas (if|though)\b'),
 ('like a (simile)', r'\blike (a|an|the|somebody|someone)\b'),
 ('not X. Y.', r'(^|[.!?]\s)(Not|Never) [^.!?]{0,60}[.]\s+[A-Z]'),
 ("wasn't X. was Y.", r"\b(wasn't|weren't|isn't|didn't)\b[^.]{0,60}\.\s+(It|He|She|They|That)\s+(was|were|is|did)\b"),
 ('for a long time/moment/while', r'\bfor a (long time|moment|second|while|minute)\b|\ba long moment\b'),
 ("didn't say anything / without a word", r"\b(didn't say anything|said nothing|without a word|without saying anything|didn't say a word)\b"),
 ("without looking / didn't look", r"\b(without looking|didn't look up|didn't look at|not looking at|without looking up)\b"),
 ('nobody/no one', r'\b(nobody|no one|Nobody|No one)\b'),
 ('never', r'\b[Nn]ever\b'),
 ('always', r'\b[Aa]lways\b'),
 ('every/everybody/everyone', r'\b[Ee]very(body|one|thing)?\b'),
 ('something/somebody/someone', r'\b[Ss]ome(thing|body|one)\b'),
 (', which', r', which\b'),
 ('That\'s (how/what/all/the)', r"\bThat's (how|what|all|the|it)\b|\bThere it is\b"),
 ('the kind of/sort of', r'\bthe (kind|sort) of\b'),
 ('then-start', r'(^|[.!?]\s)Then\b'),
 ('triplet A, B and C', r'\b\w+, [\w\' ]+,? and [\w\' ]+[.,]'),
 ('a little/a bit', r'\b(a little|a bit)\b'),
 ('very still/went quiet', r'\b(very still|went (quiet|still|white|silent)|stood still)\b'),
])
def main(paths, show=None, top=0):
    lines = []
    for p in paths: lines += text_lines(p)
    words = sum(len(l['text'].split()) for l in lines)
    tot = collections.Counter(); per_file = collections.defaultdict(collections.Counter); fw = collections.Counter()
    hits = collections.defaultdict(list)
    for l in lines:
        fw[l['file']] += len(l['text'].split())
        for k, p in PAT.items():
            c = len(re.findall(p, l['text']))
            if c:
                tot[k] += c; per_file[l['file']][k] += c; hits[k].append(l)
    print(f'words {words}')
    for k in PAT: print(f'  {k:38s} {tot[k]:5d}  {1000*tot[k]/max(words,1):6.2f}/1k')
    if show:
        for l in hits[show][:top or 9999]:
            print(f"{l['file']}:{l['n']} {l['knot']}.{l['stitch']} [{l['sp'] or l['kind']}] {l['text'][:200]}")
    return tot, words
if __name__ == '__main__':
    args = sys.argv[1:]
    show = None; top = 0
    if '--show' in args:
        i = args.index('--show'); show = args[i+1]; del args[i:i+2]
    if '--top' in args:
        i = args.index('--top'); top = int(args[i+1]); del args[i:i+2]
    paths = args or sorted(glob.glob(ROOT + '/*.ink'))
    main(paths, show, top)
