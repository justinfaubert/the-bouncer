# Packs Godot's web export into files a Claude artifact can hold: the engine's wasm and the game's
# pck gzipped and cut into parts under 14 MB (an artifact takes files up to 15 MB), put back
# together by the page (page.html) as they stream in. The parts are named .wasm, gzip or not,
# because an artifact serves a file only by the types it knows and serves that one byte for byte;
# the page reads them as bytes.
#
#   python3 godot/tools/web/pack.py build/web build/web-artifact
#
# Publish the-bouncer.html from the output folder with the other files beside it; local.html is
# the same page as a whole document, for trying it with any static server.
import gzip, json, os, re, shutil, sys
src, out = sys.argv[1], sys.argv[2]
page_path = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(os.path.abspath(__file__)), 'page.html')
PART = 14_000_000
os.makedirs(out, exist_ok=True)
for f in os.listdir(out):
    os.remove(os.path.join(out, f))
for f in ['index.js', 'index.audio.worklet.js', 'index.audio.position.worklet.js']:
    shutil.copy(os.path.join(src, f), os.path.join(out, f))
html = open(os.path.join(src, 'index.html')).read()
cfg = json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});', html).group(1))
parts = {}
for name, typ in [('index.wasm', 'application/wasm'), ('index.pck', 'application/octet-stream')]:
    raw = open(os.path.join(src, name), 'rb').read()
    z = gzip.compress(raw, 9, mtime=0)
    stem = name.replace('index.', '')
    files = []
    for k in range(0, len(z), PART):
        fn = f'{stem}.gz.{k // PART}.wasm'
        open(os.path.join(out, fn), 'wb').write(z[k:k + PART])
        files.append(fn)
    parts[name] = {'parts': files, 'size': len(raw), 'type': typ}
    print(name, len(raw), '->', len(z), files)
page = open(page_path).read()
total = sum(os.path.getsize(os.path.join(out, f)) for f in os.listdir(out))
page = page.replace('/*GODOT_CONFIG*/', json.dumps(cfg)).replace('/*PARTS*/', json.dumps(parts)).replace('/*MB*/', str(round(total / 1e6)))
open(os.path.join(out, 'the-bouncer.html'), 'w').write(page)
# the same page in a document, for trying it here
open(os.path.join(out, 'local.html'), 'w').write(
    '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"></head><body>'
    + page + '</body></html>')
print('ok')
