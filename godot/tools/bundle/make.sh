#!/bin/sh
# Makes the zip to play from on Linux: the game with play.sh beside it, and this Godot project
# beside that to open in the editor (open-in-godot.sh), with README.txt. Needs Godot 4.7.2 on the
# PATH as `godot`, and its export templates.
#
#   sh godot/tools/bundle/make.sh [out-dir]        from the repo's root; out-dir defaults to releases/
#
# A second build the same day takes a name of its own: BUNDLE_NAME=The-Bouncer-2026-10-23b sh ...
set -e
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
OUT=${1:-$ROOT/releases}
NAME=${BUNDLE_NAME:-The-Bouncer-$(date +%Y-%m-%d)}
STAGE=$(mktemp -d)
B="$STAGE/$NAME"
mkdir -p "$B/game" "$B/godot-project" "$OUT"
# the project as it is in the repo, without the editor's cache
tar -C "$ROOT/godot" --exclude=.godot -cf - . | tar -C "$B/godot-project" -xf -
# export from that copy, so the zip's project and its game are the same thing (the first run
# imports it and builds its class cache)
godot --headless --path "$B/godot-project" --editor --quit >/dev/null 2>&1 || true
godot --headless --path "$B/godot-project" --export-release "Linux" "$B/game/TheBouncer.x86_64"
rm -rf "$B/godot-project/.godot"
cp "$ROOT/godot/tools/bundle/play.sh" "$ROOT/godot/tools/bundle/open-in-godot.sh" "$ROOT/godot/tools/bundle/README.txt" "$B/"
chmod +x "$B/play.sh" "$B/open-in-godot.sh" "$B/game/TheBouncer.x86_64"
rm -f "$OUT/$NAME.zip"
(cd "$STAGE" && zip -qr -9 "$OUT/$NAME.zip" "$NAME")
rm -rf "$STAGE"
echo "$OUT/$NAME.zip"
