#!/usr/bin/env bash
# Applies quake-terminal gsettings: Ctrl+` keybinding, Alacritty as the target
# terminal, and `claude` as the command it launches. Run this AFTER install.sh
# and AFTER restarting GNOME Shell (see install.sh's final message).
#
# Usage: ./configure.sh [starting-directory]
#   Prompts for the directory Claude Code should start in if not given as an
#   argument (defaults to $HOME on an empty prompt answer).
set -euo pipefail

SCHEMA="org.gnome.shell.extensions.quake-terminal"
EXTENSION_UUID="quake-terminal@diegodario88.github.io"
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/schemas"

if ! gnome-extensions list --enabled | grep -qx "$EXTENSION_UUID"; then
  echo "ERROR: $EXTENSION_UUID is not enabled." >&2
  echo "Run ./install.sh first, restart GNOME Shell, then re-run this script." >&2
  exit 1
fi

# gsettings only searches the system schema registry by default. Extension
# schemas live inside the extension's own directory instead, so they need to
# be pointed at explicitly with --schemadir (this is why a plain `gsettings
# set org.gnome.shell.extensions.quake-terminal ...` fails with "No such
# schema" even once the extension is installed and enabled).
if [ ! -f "$SCHEMA_DIR/gschemas.compiled" ]; then
  echo "ERROR: compiled schema not found at $SCHEMA_DIR/gschemas.compiled" >&2
  echo "Re-run ./install.sh — the extension may not have installed correctly." >&2
  exit 1
fi
gsettings() { command gsettings --schemadir "$SCHEMA_DIR" "$@"; }

echo "==> Starting directory"
raw_dir="${1:-}"
if [ -z "$raw_dir" ]; then
  read -rp "Directory to open the Claude Code terminal in [$HOME]: " raw_dir
  raw_dir="${raw_dir:-$HOME}"
fi
raw_dir="${raw_dir/#\~/$HOME}"
if [ ! -d "$raw_dir" ]; then
  echo "ERROR: '$raw_dir' is not a directory." >&2
  exit 1
fi
start_dir="$(realpath "$raw_dir")"
echo "    Using: $start_dir"

echo "==> Locating Alacritty's .desktop file"
desktop_id=""
for f in /usr/share/applications/Alacritty.desktop /usr/share/applications/alacritty.desktop; do
  if [ -f "$f" ]; then
    desktop_id="$(basename "$f")"
    break
  fi
done
if [ -z "$desktop_id" ]; then
  found="$(find /usr/share/applications "$HOME/.local/share/applications" -iname '*alacritty*.desktop' 2>/dev/null | head -1 || true)"
  [ -n "$found" ] && desktop_id="$(basename "$found")"
fi
if [ -z "$desktop_id" ]; then
  echo "ERROR: could not find Alacritty's .desktop file. Is Alacritty installed? (run ./install.sh)" >&2
  exit 1
fi
echo "    Using terminal-id: $desktop_id"

echo "==> Applying quake-terminal settings"
launch_args="--working-directory \"$start_dir\" -e claude"
gsettings set "$SCHEMA" terminal-shortcut "['<Control>grave']"
gsettings set "$SCHEMA" terminal-id "'$desktop_id'"
gsettings set "$SCHEMA" launch-args-map "{'$desktop_id': '$launch_args'}"

cat <<EOF

==> Done. Press Ctrl+\` to toggle the Claude Code terminal.

Left at defaults (see README.md to tune): auto-hide-window (true), skip-taskbar
(true), always-on-top (false), vertical-size/horizontal-size/monitor-screen
(50/100/0).
EOF
