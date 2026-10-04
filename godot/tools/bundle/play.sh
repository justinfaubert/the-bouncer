#!/bin/sh
# The Bouncer: Wednesday, the test shift. Starts the game.
#
#   ./play.sh                  in a window (the pause menu, Esc, has fullscreen)
#   ./play.sh --fullscreen     straight to fullscreen
#
# Anything else on the line goes to Godot, for example --display-driver wayland to run on
# Wayland itself instead of through XWayland.
cd "$(dirname "$0")" || exit 1
GAME=./game/TheBouncer.x86_64
if [ ! -f "$GAME" ]; then
	echo "The game should be at $GAME, beside this script, and it isn't." >&2
	exit 1
fi
# an unzip that drops the permissions leaves it not runnable
if [ ! -x "$GAME" ]; then
	chmod +x "$GAME" || { echo "Couldn't make $GAME runnable: chmod +x it, then try again." >&2; exit 1; }
fi
exec "$GAME" "$@"
