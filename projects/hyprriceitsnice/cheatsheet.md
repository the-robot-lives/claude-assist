# Hyprriceitsnice — Cheat Sheet

Quick reference for `~/.config/hypr/hyprland.conf` (+ AI workspace extension).

**Mod** = `SUPER` (Windows / ⌘ key)

---

## Monitors & workspaces

| Output | Role | Mode | Scale | Position |
|--------|------|------|-------|----------|
| `HDMI-A-1` | MSI 273Q (primary, top) | 2560×1440@120 | 1 | `0x0` |
| `eDP-1` | Laptop OLED (bottom) | 2880×1620@120 | 1.5 → logical 1920×1080 | `320x1440` (centered under MSI) |
| `*` | Hotplug | preferred | 1 | auto-right |

| Workspaces | Monitor |
|------------|---------|
| **1–5** | External (`HDMI-A-1`) |
| **6–9** | Laptop (`eDP-1`) |
| **10** | (bound; no fixed monitor) |
| **special:scratchpad** | Scratchpad |
| **special:ai** | AI floating layout |

Default workspace titles (desktop-snapshots): `1=osx` `2=win` `3=dev` `4=web` `5=ai`

---

## Apps (variables)

| Var | App |
|-----|-----|
| `$terminal` | **ghostty** |
| `$browser` | **chromium** |
| `$fileManager` | **dolphin** |
| `$menu` | **wofi** (drun) |

Also: **foot** server (`foot --server`), **waybar**, **swaync**, **cliphist**, **desktop-snapshots** daemon.

---

## Launch & windows

| Binding | Action |
|---------|--------|
| `SUPER` + `Return` | Terminal (ghostty) |
| `SUPER` + `Space` | App launcher (wofi) — *overrides an earlier ghostty bind on the same key* |
| `ALT` + `Space` | App launcher (wofi / Spotlight-style) |
| `SUPER` + `B` | Browser (chromium) |
| `SUPER` + `E` | File manager (dolphin) |
| `SUPER` + `M` | NoMachine (`nxplayer`) |
| `SUPER` + `RCTRL` + `Q` | Kill active window |
| `SUPER` + `SHIFT` + `V` | Toggle floating |
| `SUPER` + `F` | Fullscreen |
| `SUPER` + `P` | Pseudo-tile (dwindle) |
| `SUPER` + `T` | Toggle split (dwindle) |
| `CTRL` + `ALT` + `P` | Float + **pin** (sticky across workspaces) |

`SUPER` + `SHIFT` + `Q` (exit Hyprland) is **disabled** on purpose.

---

## Dual-monitor foot + tmux

Shared session `main` via `footclient` (needs `foot --server`):

| Binding | Action |
|---------|--------|
| `SUPER` + `SHIFT` + `Return` | Big float on **HDMI** (`foot-big`, 70%×60%) |
| `SUPER` + `ALT` + `Return` | Big float on **laptop** (`foot-pad`, 90%×85%) |

---

## Clipboard & screenshots

| Binding | Action |
|---------|--------|
| `SUPER` + `V` | Clipboard history (cliphist → wofi → wl-copy) |
| `Print` | Region capture → clipboard (`grim` + `slurp`) |
| `SUPER` + `Print` | Fullscreen → clipboard |
| `SUPER` + `SHIFT` + `Print` | Region → `~/Pictures/screenshot-YYYYMMDD-HHMMSS.png` |

---

## Focus / move / resize

Vim-style and arrows are equivalent for focus.

| Binding | Action |
|---------|--------|
| `SUPER` + `H` / `J` / `K` / `L` | Focus left / down / up / right |
| `SUPER` + arrows | Focus |
| `SUPER` + `SHIFT` + `H`/`J`/`K`/`L` | Move window |
| `SUPER` + `CTRL` + `H`/`L` | Resize ±40 px width |
| `SUPER` + `CTRL` + `K`/`J` | Resize ±40 px height |
| `SUPER` + LMB drag | Move window |
| `SUPER` + RMB drag | Resize window |

Also: **resize on border** is on (drag window edges).

---

## Workspaces

| Binding | Action |
|---------|--------|
| `SUPER` + `1`…`9` / `0` | Go to workspace 1–9 / 10 |
| `SUPER` + `SHIFT` + `1`…`0` | Move window to workspace |
| `SUPER` + `Tab` | Next workspace |
| `SUPER` + `SHIFT` + `Tab` | Previous workspace |
| `SUPER` + scroll down/up | Next / previous workspace |
| 3-finger horizontal swipe | Workspace switch |

### Scratchpad

| Binding | Action |
|---------|--------|
| `SUPER` + `S` | Toggle **special:scratchpad** |
| `SUPER` + `SHIFT` + `S` | Send focused window → scratchpad |

### AI workspace (`special:ai`)

| Binding | Action |
|---------|--------|
| `SUPER` + `A` | Toggle AI workspace |
| `SUPER` + `SHIFT` + `A` | Launch layout (`ai-workspace-launch`) |
| `SUPER` + `ALT` + `C` | Move focused → AI workspace (silent) |
| `SUPER` + `ALT` + `M` | Move focused from special → current workspace |

**AI layout** (floats, %-based on focused monitor):

- Chrome/Chromium — left ~58%×72%
- Obsidian — right ~40%×97%
- foot / kitty — under chrome ~58%×22%

Launcher opens ChatGPT / Claude / Perplexity / Cerebras / Groq / z.ai tabs + Obsidian vault + terminal.

---

## Extra UI

| Binding | Action |
|---------|--------|
| `SUPER` + `ALT` + `W` | Waybar notch-dock toggle (config profile 6 only) |
| `SUPER` + `CTRL` + `5` | Desktop snapshots **overview** |

---

## Media / hardware

| Key | Action |
|-----|--------|
| Vol ↑/↓ | ±5% volume (`wpctl`, cap 100%) |
| Mute | Toggle sink mute |
| Mic mute | Toggle source mute |
| Brightness ↑/↓ | ±5% (`brightnessctl`) |
| Play/Pause / Next / Prev | `playerctl` |

---

## Gestures & input

- Touchpad: natural scroll, tap-to-click
- Workspace swipe distance 700, cancel ratio 0.5
- KB: US, repeat 50 Hz after 300 ms
- Focus follows mouse

---

## Autostart stack

| Process | Role |
|---------|------|
| waybar | Status bar (only under Hyprland) |
| swaync | Notifications |
| polkit-gnome | Auth agent |
| wl-paste → cliphist | Clipboard store (text + image) |
| desktop-snapshots daemon | Workspace snapshot cache |
| foot --server | Fast `footclient` terminals |

---

## Window rules (highlights)

| Match | Behavior |
|-------|----------|
| pavucontrol, nm-connection-editor, blueman-manager | Float |
| Open/Save File dialogs | Float |
| Desktop Snapshots | Float + center |
| VS Code / JetBrains | Force tile |
| Picture-in-Picture | Float + pin |
| foot-big / foot-pad | Float, size, pin to monitor |

---

## Look (rice snapshot)

- **Layout:** dwindle (`smart_split`, `preserve_split`, `pseudotile`)
- **Gaps:** in 3 / out 6 · **border:** 1 · **rounding:** 8
- **Active border:** blue→purple gradient (`#7aa2f7` → `#bb9af7`, Tokyo Night-ish)
- **Blur:** on (size 8, 4 passes) · **shadows:** on
- **VRR:** off · **NVIDIA** env vars set (libva / gbm / GLX / software cursors)

---

## Handy CLI

```bash
hyprctl reload                          # reload config
hyprctl monitors                        # layout check
hyprctl clients                         # windows
hyprctl dispatch workspace 3            # jump WS
~/.config/hypr/bin/ai-workspace-launch  # rebuild AI layout
~/.config/hypr/bin/desktop-snapshots overview
```

---

## Config files

| Path | What |
|------|------|
| `~/.config/hypr/hyprland.conf` | Main config + binds |
| `~/.config/hypr/ai-workspace-extension.conf` | AI special workspace |
| `~/.config/hypr/bin/ai-workspace-launch` | AI app layout script |
| `~/.config/hypr/bin/desktop-snapshots` | Snapshot daemon + overview |
| `~/.config/wofi/` | Launcher style |
| `~/.config/waybar/` | Bar profiles |

---

*Generated from the live hyprland config. Binding collisions: `SUPER`+`Space` is declared twice (terminal then menu); the later bind wins → launcher.*
