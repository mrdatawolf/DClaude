#!/usr/bin/env bash
# Configures Yakuake: a dedicated Konsole profile that runs `claude` in a
# chosen starting directory, sets Yakuake to autostart, and binds Ctrl+` as
# the global toggle shortcut. Run this AFTER install-kde.sh and AFTER
# rebooting (rpm-ostree layering requires a reboot before yakuake exists).
#
# Usage: ./configure-kde.sh [starting-directory]
#   Prompts for the directory Claude Code should start in if not given as an
#   argument (defaults to $HOME on an empty prompt answer).
set -euo pipefail

if ! command -v yakuake >/dev/null 2>&1; then
  echo "ERROR: yakuake is not installed." >&2
  echo "Run ./install-kde.sh first, reboot, then re-run this script." >&2
  exit 1
fi

kwriteconfig="kwriteconfig6"
if ! command -v "$kwriteconfig" >/dev/null 2>&1; then
  if command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig="kwriteconfig5"
    echo "NOTE: kwriteconfig6 not found, falling back to kwriteconfig5 (older Plasma?)." >&2
  else
    echo "ERROR: neither kwriteconfig6 nor kwriteconfig5 found." >&2
    exit 1
  fi
fi

claude_path="$(command -v claude)"

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

echo "==> Writing Konsole profile"
profile_dir="$HOME/.local/share/konsole"
profile_name="ClaudeCode.profile"
mkdir -p "$profile_dir"
cat > "$profile_dir/$profile_name" <<EOF
[General]
Name=ClaudeCode
Parent=FALLBACK/
Command=$claude_path
Directory=$start_dir
EOF

echo "==> Pointing Yakuake at that profile"
"$kwriteconfig" --file yakuakerc --group "Desktop Entry" --key DefaultProfile "$profile_name"

echo "==> Setting the Ctrl+\` global shortcut"
"$kwriteconfig" --file kglobalshortcutsrc --group yakuake --key toggle-window-state \
  'Ctrl+`,Ctrl+`,Open/Retract Yakuake'

echo "==> Enabling Yakuake autostart (so the shortcut has something to toggle)"
autostart_dir="$HOME/.config/autostart"
mkdir -p "$autostart_dir"
src_desktop=""
for f in /usr/share/applications/org.kde.yakuake.desktop /usr/share/applications/yakuake.desktop; do
  if [ -f "$f" ]; then
    src_desktop="$f"
    break
  fi
done
if [ -n "$src_desktop" ]; then
  cp "$src_desktop" "$autostart_dir/$(basename "$src_desktop")"
else
  echo "WARNING: could not find yakuake's .desktop file to enable autostart; add it manually via System Settings > Autostart." >&2
fi

echo "==> Starting Yakuake now"
if ! pgrep -x yakuake >/dev/null 2>&1; then
  setsid yakuake >/dev/null 2>&1 &
  disown
fi

cat <<'EOF'

==> configure-kde.sh complete.

The new global shortcut requires a fresh kglobalaccel session to take
effect. Log out and back in, then press Ctrl+` to toggle the Claude Code
terminal (the `claude` process keeps running in the background when hidden).
EOF
