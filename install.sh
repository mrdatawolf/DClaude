#!/usr/bin/env bash
# Installs Alacritty and the quake-terminal GNOME Shell extension, then enables it.
# Safe to re-run. After this completes, GNOME Shell must be restarted
# before ./configure.sh will work — see printed instructions at the end.
set -euo pipefail

EXTENSION_UUID="quake-terminal@diegodario88.github.io"
EXTENSION_TAG="v1.2.5"
EXTENSION_REPO="https://github.com/diegodario88/quake-terminal.git"

echo "==> Checking prerequisites"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' (Claude Code CLI) was not found on PATH." >&2
  echo "Install it via the official Claude Code instructions first, then re-run this script." >&2
  echo "See: https://docs.claude.com/en/docs/claude-code" >&2
  exit 1
fi

if ! command -v gnome-extensions >/dev/null 2>&1; then
  echo "ERROR: 'gnome-extensions' not found — this script requires a GNOME Shell session." >&2
  exit 1
fi

if command -v gnome-shell >/dev/null 2>&1; then
  shell_version="$(gnome-shell --version | grep -oE '[0-9]+' | head -1 || true)"
  if [ -n "$shell_version" ] && { [ "$shell_version" -lt 45 ] || [ "$shell_version" -gt 50 ]; }; then
    echo "WARNING: GNOME Shell $shell_version is outside quake-terminal's declared 45-50 support range." >&2
    echo "         Continuing anyway, but check https://github.com/diegodario88/quake-terminal for updates." >&2
  fi
fi

echo "==> Installing Alacritty"
sudo apt-get update
sudo apt-get install -y alacritty make git

echo "==> Fetching quake-terminal ${EXTENSION_TAG}"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
git clone --branch "$EXTENSION_TAG" --depth 1 "$EXTENSION_REPO" "$build_dir/quake-terminal"

echo "==> Building and installing the extension"
make -C "$build_dir/quake-terminal" install

echo "==> Enabling the extension"
if ! gnome-extensions enable "$EXTENSION_UUID"; then
  echo "NOTE: enabling failed — this is expected if GNOME Shell hasn't picked up the new" >&2
  echo "extension yet. Restart your session (see below), then run:" >&2
  echo "  gnome-extensions enable $EXTENSION_UUID" >&2
fi

cat <<'EOF'

==> install.sh complete.

GNOME Shell must restart before the extension is active:
  - Xlibre/X11 session: press Alt+F2, type 'r', press Enter.
  - Wayland session: log out and log back in (Wayland cannot restart Shell in place).

After restarting, run ./configure.sh to set the Ctrl+` keybinding and point the
terminal at the Claude Code CLI.
EOF
