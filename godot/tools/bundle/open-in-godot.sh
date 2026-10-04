#!/usr/bin/env bash
# Opens the game's Godot project (godot-project/, beside this script) in the Godot editor.
#
# It was made in Godot 4.7.2. A Godot 4.7 on your PATH (Arch's godot package) or in Flatpak is used if
# there is one. If there isn't, this offers to fetch the official 4.7.2 editor (a 78 MB download)
# into tools/ here, checks it against its fingerprint, and uses that from then on.
set -u
cd "$(dirname "$0")" || exit 1
HERE=$(pwd)
PROJECT="$HERE/godot-project"
BIN="Godot_v4.7.2-stable_linux.x86_64"
LOCAL="$HERE/tools/$BIN"
SHA_BIN="8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e"
URLS=(
	"https://github.com/godotengine/godot/releases/download/4.7.2-stable/$BIN.zip"
	"https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/$BIN.zip"
	"https://sourceforge.net/projects/godot-engine.mirror/files/4.7.2-stable/$BIN.zip/download"
)

if [ ! -f "$PROJECT/project.godot" ]; then
	echo "The project should be at $PROJECT, beside this script, and it isn't." >&2
	exit 1
fi

open_with() {
	echo "Opening the project with $* ..."
	exec "$@" --editor --path "$PROJECT"
}

# 1. a Godot 4.7 already here
other=""
for g in godot godot4 godot-4; do
	if command -v "$g" >/dev/null 2>&1; then
		v=$("$g" --version 2>/dev/null | head -n 1)
		case "$v" in
			4.7.*) open_with "$g" ;;
			*) other="$g"; echo "Found $g, Godot $v. The project wants 4.7." ;;
		esac
	fi
done
if [ -x "$LOCAL" ]; then
	open_with "$LOCAL"
fi
if command -v flatpak >/dev/null 2>&1 && flatpak info org.godotengine.Godot >/dev/null 2>&1; then
	v=$(flatpak run org.godotengine.Godot --version 2>/dev/null | head -n 1)
	case "$v" in
		4.7.*) open_with flatpak run --filesystem="$HERE" org.godotengine.Godot ;;
		*) echo "Found Godot $v in Flatpak. The project wants 4.7." ;;
	esac
fi

# 2. none: offer to fetch 4.7.2
echo
if [ -n "$other" ]; then
	echo "Godot 4.7 isn't installed. You can open the project with $other anyway (a newer Godot"
	echo "will offer to upgrade it; an older one may not open it), or fetch 4.7.2 for it."
	read -r -p "[F]etch Godot 4.7.2 (78 MB) into tools/, [o]pen with $other, or [q]uit? " a
	case "$a" in
		[oO]*) open_with "$other" ;;
		[qQ]*) exit 0 ;;
	esac
else
	echo "Godot 4.7 isn't installed."
	read -r -p "Fetch the official Godot 4.7.2 editor (78 MB) into tools/ here and open with it? [Y/n] " a
	case "$a" in
		[nN]*) echo "Then get Godot 4.7 from godotengine.org, and open godot-project/project.godot in it."; exit 0 ;;
	esac
fi

mkdir -p "$HERE/tools"
tmp="$HERE/tools/godot-4.7.2.zip.part"
got=""
for u in "${URLS[@]}"; do
	echo "Fetching $u"
	if command -v curl >/dev/null 2>&1; then
		curl -fL --retry 2 -o "$tmp" "$u" && got=1
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$tmp" "$u" && got=1
	else
		echo "Neither curl nor wget is installed." >&2; exit 1
	fi
	[ -n "$got" ] && break
done
if [ -z "$got" ]; then
	rm -f "$tmp"
	echo "Couldn't fetch it. Get Godot 4.7.2 from godotengine.org and open godot-project/project.godot in it." >&2
	exit 1
fi
echo "Unpacking ..."
if command -v unzip >/dev/null 2>&1; then
	unzip -o -q "$tmp" -d "$HERE/tools"
elif command -v bsdtar >/dev/null 2>&1; then
	bsdtar -xf "$tmp" -C "$HERE/tools"
else
	python3 -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$tmp" "$HERE/tools"
fi
rm -f "$tmp"
if [ ! -f "$LOCAL" ]; then
	echo "The download didn't have $BIN in it." >&2; exit 1
fi
sum=$(sha256sum "$LOCAL" | cut -d ' ' -f 1)
if [ "$sum" != "$SHA_BIN" ]; then
	rm -f "$LOCAL"
	echo "What came down isn't the official Godot 4.7.2 (its fingerprint is wrong), so it's been deleted." >&2
	exit 1
fi
chmod +x "$LOCAL"
echo "Godot 4.7.2 is in tools/ and checks out."
open_with "$LOCAL"
