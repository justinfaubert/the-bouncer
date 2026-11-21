"""The voice script: every spoken line in the Ink, with the file name its recording goes under.

game/sound.gd plays a recorded line when a file named for it is in audio/: vo_<who>_<8 letters>,
where <who> is the speaker's id (teller for NARRATOR) and the 8 letters are the start of the sha1 of
the line's words (spaces squeezed). Rewrite a line and its name changes, so it needs recording again;
run this after any change to the Ink and the script shows what's new.

Lines with {...} or <> in them change with the night (a name, a count, a choice made earlier). Their
words can't be known here, so they're listed apart: record the bark for that speaker instead, or
ask for the line to be split so the fixed part can be recorded.

  python3 tools/vo_script.py           (writes docs/VOICE_SCRIPT.md)
  python3 tools/vo_script.py --check   (prints the counts only)
"""

import hashlib
import json
import pathlib
import re
import sys

GODOT = pathlib.Path(__file__).resolve().parent.parent
INK = GODOT.parent / "content" / "ink"
CONTENT = GODOT / "data" / "content.json"
OUT = GODOT / "docs" / "VOICE_SCRIPT.md"

SPEAKER = re.compile(r"^([A-Z][A-Z0-9_]*):\s+(.*)$")
LEAD = re.compile(r"^(?:[-*+]\s*)+(?:\([A-Za-z0-9_]+\)\s*)?")


def key(who: str, text: str) -> str:
    """The same as Sound.vo_key in game/sound.gd."""
    words = " ".join(w for w in text.strip().split(" ") if w)
    return "vo_%s_%s" % (who, hashlib.sha1(words.encode("utf-8")).hexdigest()[:8])


def clean(raw: str) -> str:
    s = raw.strip()
    if s.startswith("//") or s.startswith("~") or s.startswith("==") or s.startswith("VAR ") or s.startswith("INCLUDE"):
        return ""
    s = re.sub(r"(?<!:)//.*$", "", s)          # a comment, not a url
    s = re.sub(r"(?<!\\)#.*$", "", s)          # tags
    s = LEAD.sub("", s)                        # gather and choice marks, a gather's label
    s = s.replace("\\#", "#").replace("\\", "")
    return s.strip()


SEQ = ("shuffle", "stopping", "cycle", "once", "shuffle once", "shuffle stopping")


def expand(text: str, limit: int = 12):
    """Every way an Ink line can come out: {a|b} and {shuffle:a|b} give each choice, {cond: a} and
    {cond: a|b} each branch. None if it holds anything else (a variable, glue, nesting)."""
    if "<>" in text:
        return None
    m = re.search(r"\{([^{}]*)\}", text)
    if not m:
        return None if "}" in text else [text]
    body = m.group(1)
    head, colon, rest = body.partition(":")
    if colon and head.strip() in SEQ:
        options = rest.split("|")
    elif body[:1] in "~&!":
        options = body[1:].split("|")
    elif colon and "|" not in head:
        options = rest.split("|")
        if len(options) == 1:
            options.append("")
    elif "|" in body:
        options = body.split("|")
    else:
        return None
    out = []
    for o in options:
        sub = expand(text[:m.start()] + o + text[m.end():], limit)
        if sub is None:
            return None
        out += sub
        if len(out) > limit:
            return None
    return out


def main() -> None:
    content = json.loads(CONTENT.read_text(encoding="utf-8"))
    names = {}
    kinds = {}
    for kind in ("voices", "characters"):
        for sid, d in content.get(kind, {}).items():
            names[sid.upper()] = sid
            kinds[sid] = kind
            d = d or {}
            names.setdefault("_label_" + sid, str(d.get("label") or d.get("name") or sid).title())
    lines = {}       # who -> [(key, text, where)]
    varies = {}      # who -> [(text, where)]

    def add(who: str, text: str, where: str) -> None:
        texts = expand(text)
        if texts is None:
            varies.setdefault(who, []).append((text, where))
            return
        for t in texts:
            if t.strip():
                lines.setdefault(who, []).append((key(who, t), " ".join(t.split()), where))

    for f in sorted(INK.glob("*.ink")):
        for n, raw in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            s = clean(raw)
            m = SPEAKER.match(s)
            if not m:
                continue
            label, text = m.group(1), m.group(2).strip()
            if label == "NARRATOR":
                who = "teller"
            elif label in names:
                who = names[label]
            else:
                continue
            add(who, text, "%s:%d" % (f.name, n))
    # the voices' barks between scenes (content/rules/barks.yaml) and what he overhears in the room
    # (content/rules/talk.yaml)
    for b in content.get("barks", []):
        if b.get("speaker") and b.get("text"):
            add(str(b["speaker"]), str(b["text"]), "barks.yaml %s" % b.get("id", ""))
    for t in content.get("talk", []):
        for ln in t.get("lines", []):
            for who, text in ln.items():
                add(str(who), str(text), "talk.yaml %s" % t.get("id", ""))

    order = sorted(lines.keys() | varies.keys(),
                   key=lambda w: (w != "teller", kinds.get(w) != "voices", -len(lines.get(w, []))))
    total = sum(len(v) for v in lines.values())
    unique = len({k for v in lines.values() for k, _, _ in v})
    vtotal = sum(len(v) for v in varies.values())
    if "--check" in sys.argv:
        print("%d lines to record (%d files), %d that change with the night, %d speakers" % (total, unique, vtotal, len(order)))
        return

    out = ["# The voice script", "",
           "Made by `tools/vo_script.py` from `content/ink/` and the barks and overheard talk in `content/rules/`. Don't edit by hand: run it again after the Ink changes.", "",
           "Each line's recording goes in `godot/audio/` under the name given, as .ogg, .wav or .mp3. A second take",
           "of the same line goes under the same name with `_2`, `_3` on the end, and the game picks between them.",
           "Lines said the same way in more than one place share a file. Record the teller first: his lines are few",
           "and they carry the most.", "",
           "Besides the lines, each speaker can have **barks**, `bark_<id>` (a sound under their breath: a grunt, a",
           "laugh, a word that isn't in the script), which play now and then under their unrecorded lines, and each",
           "voice in his head a **whisper**, `whisper_<id>`, the same for theirs. A few takes of each go a long way.", "",
           "%d lines to record (%d files) for %d speakers. %d more change with the night and are listed after each speaker." % (total, unique, len(order), vtotal), ""]
    out += ["| Speaker | id | Lines | Changing | Bark file |", "|---|---|---|---|---|"]
    for w in order:
        label = "The teller (NARRATOR)" if w == "teller" else str(names.get("_label_" + w, w))
        kind = "" if w == "teller" else (" (a voice in his head)" if kinds.get(w) == "voices" else "")
        bark = "" if w == "teller" else ("`whisper_%s`" % w if kinds.get(w) == "voices" else "`bark_%s`" % w)
        out.append("| %s%s | %s | %d | %d | %s |" % (label, kind, w, len(lines.get(w, [])), len(varies.get(w, [])), bark))
    out.append("")
    for w in order:
        label = "The teller" if w == "teller" else str(names.get("_label_" + w, w))
        out += ["## %s (`%s`)" % (label, w), ""]
        seen = set()
        for k, text, where in lines.get(w, []):
            if k in seen:
                continue
            seen.add(k)
            out.append("- `%s` %s  _(%s)_" % (k, text, where))
        if varies.get(w):
            out += ["", "Changing with the night (record the %s instead, or ask for these to be split):" % ("bark" if w != "teller" else "steady part"), ""]
            for text, where in varies[w]:
                out.append("- %s  _(%s)_" % (text.replace("|", "\\|"), where))
        out.append("")
    OUT.write_text("\n".join(out), encoding="utf-8")
    print("wrote %s: %d lines (%d files), %d changing" % (OUT.relative_to(GODOT), total, unique, vtotal))


if __name__ == "__main__":
    main()
