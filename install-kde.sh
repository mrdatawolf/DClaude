#!/usr/bin/env bash
# Installs Yakuake on an rpm-ostree (Fedora Atomic / Bazzite) KDE Plasma system.
# Safe to re-run. rpm-ostree package layering requires a REBOOT to take effect
# (unlike Debian's apt) — see printed instructions at the end.
#
# Why rpm-ostree instead of Flatpak (Bazzite's usual first choice):
# Yakuake's Flatpak build (org.kde.yakuake) has documented trouble reaching
# the kglobalaccel D-Bus service for global shortcuts, and a sandboxed
# terminal can't run the host `claude` binary without `flatpak-spawn --host`
# plus extra filesystem permissions. Both of those are core to this project,
# so native rpm-ostree layering is the more reliable choice here.
set -euo pipefail

echo "==> Checking prerequisites"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' (Claude Code CLI) was not found on PATH." >&2
  echo "Install it via the official Claude Code instructions first, then re-run this script." >&2
  echo "See: https://docs.claude.com/en/docs/claude-code" >&2
  exit 1
fi

if ! command -v rpm-ostree >/dev/null 2>&1; then
  echo "ERROR: 'rpm-ostree' not found — this script is for an rpm-ostree-based" >&2
  echo "system (Bazzite / Fedora Atomic). Use install.sh instead on Debian/GNOME." >&2
  exit 1
fi

if command -v plasmashell >/dev/null 2>&1; then
  plasma_version="$(plasmashell --version | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
  echo "    Detected Plasma $plasma_version"
fi

echo "==> Installing Yakuake"
if rpm -q yakuake >/dev/null 2>&1; then
  echo "    yakuake is already layered, skipping."
  needs_reboot=false
else
  sudo rpm-ostree install -y yakuake
  needs_reboot=true
fi

cat <<EOF

==> install-kde.sh complete.
EOF

if [ "${needs_reboot:-false}" = "true" ]; then
  cat <<'EOF'
Yakuake was just layered onto the system with rpm-ostree — a REBOOT is
required before it's available.

After rebooting, run ./configure-kde.sh to set the Ctrl+` shortcut and point
Yakuake at the Claude Code CLI.
EOF
else
  echo "Run ./configure-kde.sh to set the Ctrl+\` shortcut and point Yakuake at the Claude Code CLI."
fi
