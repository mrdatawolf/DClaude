# DClaude — Ctrl+` Claude Code Quake Terminal

A global `Ctrl+`` `` (Ctrl+backtick) hotkey that drops down a persistent terminal
running the Claude Code CLI (`claude`), on Debian 13 / GNOME 48. Designed to
work identically on two machines: one running a native Wayland GNOME session,
one running an Xlibre (X11 fork) GNOME session.

## How it works

- [`quake-terminal`](https://github.com/diegodario88/quake-terminal) is a
  GNOME Shell extension that drives an *external* terminal app's window into
  dropdown position using Mutter's window-management APIs. Positioning is
  done by the compositor (Shell/Mutter), not by the terminal app itself —
  which is why this works the same on Wayland and X11/Xlibre: Wayland only
  restricts *clients* from positioning themselves, not the compositor moving
  them.
- Hiding the dropdown calls `minimize()` on the window, not close — so the
  `claude` process and your conversation survive every toggle. The extension
  reuses one window (spawned once) rather than respawning per toggle.
- The terminal emulator is **Alacritty**, not GNOME 48's default (Ptyxis).
  Ptyxis shares one process across all its windows, which breaks
  `quake-terminal`'s per-window tracking (see [upstream issue
  #69](https://github.com/diegodario88/quake-terminal/issues/69)). Alacritty
  uses the classic one-process-per-window model this extension expects.
- `claude` is launched as the terminal's command directly (via Alacritty's
  `-e` flag through `quake-terminal`'s `launch-args-map` setting), so it's
  already running the moment the dropdown appears — you don't type `claude`
  yourself each time.

Same extension version and same `gsettings` config apply unmodified on both
machines — Xlibre is binary/protocol-compatible with X11, so nothing here is
Wayland- or Xlibre-specific beyond what's already described above.

## Before you run anything

Check **Settings → Keyboard → Keyboard Shortcuts** on each box (and
Alacritty's own config, if you've customized it) for anything already bound
to Ctrl+`` ` ``. This varies per machine and isn't something these scripts
try to detect or override automatically — if something's already using that
binding, either free it up or change `terminal-shortcut` in `configure.sh` to
something else.

## Usage

```sh
./install.sh      # installs Alacritty + the quake-terminal extension, enables it
```

Then restart GNOME Shell — required before a newly installed extension is
active:
- **Xlibre/X11 session:** Alt+F2, type `r`, Enter.
- **Wayland session:** log out and back in (Wayland can't restart Shell in
  place).

```sh
./configure.sh    # sets the Ctrl+` keybinding, points the terminal at `claude`
```

`configure.sh` prompts for the directory Claude Code should start in
(defaults to `$HOME` on an empty answer). To skip the prompt — e.g. when
re-running it — pass the directory as an argument instead:
`./configure.sh ~/Documents/Github/Personal/DClaude`. Re-running it with a
new directory simply overwrites the old one.

Press **Ctrl+`\`** to bring the terminal down; press it again to hide it
(the `claude` process keeps running in the background).

## Tuning

Everything `quake-terminal` exposes is a `gsettings` key under
`org.gnome.shell.extensions.quake-terminal`. `configure.sh` only sets
`terminal-shortcut`, `terminal-id`, and `launch-args-map` (which also carries
the `--working-directory` flag for the starting directory you gave it);
these are left at their defaults and are safe to change by hand:

| Key | Default | Meaning |
|---|---|---|
| `auto-hide-window` | `true` | hide the dropdown when it loses focus |
| `skip-taskbar` | `true` | hide it from the overview / Alt+Tab |
| `always-on-top` | `false` | keep it above other windows |
| `vertical-size` / `horizontal-size` | `50` / `100` | size as a percentage |
| `monitor-screen` | `0` | which display it renders on |

`gsettings` doesn't know about extension schemas by default — they live
inside the extension's own directory, not the system schema registry — so
hand-editing any of these needs `--schemadir` pointed at it:

```sh
gsettings --schemadir ~/.local/share/gnome-shell/extensions/quake-terminal@diegodario88.github.io/schemas \
  set org.gnome.shell.extensions.quake-terminal always-on-top true
```

## Reversing

```sh
gnome-extensions disable quake-terminal@diegodario88.github.io
gnome-extensions uninstall quake-terminal@diegodario88.github.io
sudo apt remove alacritty   # optional
```

## Troubleshooting

- **Nothing happens on Ctrl+`\`:** confirm the extension is enabled
  (`gnome-extensions list --enabled`) and that GNOME Shell was restarted
  after `install.sh`.
- **Window opens but `claude` isn't running / you get a plain shell:**
  re-check `launch-args-map` — it must be keyed by the *exact* `.desktop`
  filename `configure.sh` printed as `terminal-id`.
- **Considering switching away from Alacritty:** avoid Ptyxis (see above,
  issue #69). Any classic one-process-per-window terminal emulator should
  work.
