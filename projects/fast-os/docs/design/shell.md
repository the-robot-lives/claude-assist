# fast-os Shell UX — "Scenes"

Status: v0.1 · 2026-07-07 · The human-facing desktop shell. Design partner deliverable for: reloadable workspaces (apps/files spin back up), Hyprland-class layout control, keyboard-only navigation, and a replacement for the Start-menu/launcher paradigm. Implements the UI half of [graphics-display.md](../graphics-display.md) and rides the agent surface in [agent-integration.md](../agent-integration.md).

Design system: **Minimal Tech** (barely-there UI, single accent, structural whitespace) — the right signal for a performance/AI-first OS, and it keeps chrome out of the way of content. Accent: violet `#7C3AED` (AI/innovation). Keyboard-first like Raycast/Linear.

## 1. Core concept: the Scene

The organizing unit is not a "window" or a "desktop" — it's a **Scene**: a named, restorable arrangement of apps, files, and layout. A Scene is a first-class OS object (a subvolume snapshot + a layout manifest + capability bundle), so it is:

- **Reloadable**: closing a Scene tears down its processes; reopening it *spins the apps and files back up* into the same layout, scroll positions and all, from the Scene's saved state. This is the headline ask — "reload workspaces with apps/files spinning up" — and it's cheap because it reuses fastfs snapshots ([fastfs-design.md](../fastfs-design.md) §4) and inferd/agent context handles.
- **Named & searchable**: "invoice-review", "kernel-hacking", "morning-triage". Not "Desktop 3".
- **Portable**: a Scene manifest hands off between your devices (mDNS discovery, [networking.md](../networking.md) §4) — resume "kernel-hacking" on the laptop exactly as you left it on the desktop.
- **Scoped**: each Scene carries its own capability bundle ([security.md](../security.md)) — the "banking" Scene can reach the bank; the "playground" Scene can't reach your files.

Replaces virtual desktops *and* session managers *and* project switchers with one concept.

## 2. Layout: tiling with intent (Hyprland-class, calmer)

Dynamic tiling, but declarative and keyboard-driven rather than mouse-dragged:

- **Binary space partitioning** by default (like Hyprland/sway): new windows split the focused tile; ratios adjustable by keyboard.
- **Named layout presets** per Scene: `dev` (editor 60% + terminal + logs), `read` (single centered column, 72ch), `compare` (2×2 grid), `focus` (one maximized, others parked). `Super+L` cycles; presets are just manifests, users author their own.
- **Gaps/animation**: 8px gaps, 150ms ease-out tile transitions (respects `prefers-reduced-motion` → instant). Restraint over the flashy Hyprland default.
- **Floating escape hatch**: `Super+Shift+Space` floats the focused tile for dialogs/media. Tiling is default, not mandatory.
- **Direct scanout** for a maximized/`focus` tile → zero compositor overhead ([graphics-display.md](../graphics-display.md) §4), so full-screen work is literally free.

## 3. Navigation: keyboard-complete, mouse-optional

Every action reachable without the mouse. Modifier is **Super** (Cmd on Apple hardware).

| Keys | Action |
|---|---|
| `Super+H/J/K/L` | Focus tile left/down/up/right (vim directions) |
| `Super+Shift+H/J/K/L` | Move tile |
| `Super+1..9` | Jump to Scene N |
| `Super+Tab` | Scene switcher (MRU, hold to preview) |
| `Super+L` | Cycle layout preset |
| `Super+Enter` | New terminal in focused tile |
| `Super+Space` | **The Bar** (see §4) — launcher/command/intent |
| `Super+/` | Keybinding cheat-sheet overlay |
| `Super+F` | Toggle focus (maximize) |
| `Super+W` | Close tile |

Discoverability (the usual keyboard-UI weakness): a persistent, dimmable **hint rail** shows the 4–5 most relevant bindings for the current context; `Super+/` opens the full searchable map. New users mouse; the hint rail teaches; muscle memory takes over. No hidden knowledge.

## 4. The Bar — replacing the Start menu

One surface, invoked with `Super+Space`, that unifies launch + search + command + intent. It is *not* a grid of icons. You type; it classifies (reflex model, <50 ms, [agent-integration.md](../agent-integration.md) §6) into one of four lanes and shows results ranked across all of them:

1. **Launch** — apps and Scenes ("figma", "kernel-hacking"). Frequency + recency ranked, so the things you actually use surface first — no hunting a menu tree.
2. **Find** — files, settings, docs, semantically ("that postgres config from last week" resolves via memoryd).
3. **Command** — verbs on the current context ("split right", "move to Scene 2", "add mirror redundancy to this folder"). Exposes the Tool Bus as typed commands.
4. **Intent** — natural language that plans ("compress logs older than a week and schedule it weekly") → shows a **plan preview** (the actual Tool Bus calls + capabilities it will use) → Enter to run per policy, staged effects gated ([security.md](../security.md) §4).

The Bar is the launcher, Spotlight, command palette, and agent prompt collapsed into one muscle-memory keystroke. First result is always selectable with Enter; arrow/Ctrl-N to walk; each lane visually tagged so you always know whether you're about to *launch*, *change something*, or *ask*.

## 5. Chrome: barely there

- **No persistent taskbar/dock.** A single **status thread** (top-right, 24px): clock, battery, net, active agent-task count, and a recording/synthetic-input indicator (trusted-overlay-drawn, un-spoofable — [graphics-display.md](../graphics-display.md) §4). Everything else is `Super+Space` away.
- **Scene ribbon** (top edge, auto-hides): the named Scenes as text chips, current one accented. Appears on `Super` hold or pointer-to-edge.
- **Agent presence**: when a Scene's copilot is working, a thin violet progress underline on the affected tile — motion as communication, not a chat window hijacking space.

## 6. Novelty budget (90/10 rule)

90% familiar: tiling WM conventions (vim keys, BSP, presets), command-palette pattern, MRU switching. 10% novel and justified: **Scenes as reloadable capability-scoped objects** (solves workspace-reload + security + handoff at once) and **the four-lane Bar** (collapses five tools, and it's the natural home for the agent surface this OS is built around). Each novelty replaces multiple existing patterns rather than adding chrome.

## 7. Accessibility

Keyboard-complete by construction (WCAG 2.2 AA keyboard nav is the *primary* path, not a bolt-on). All motion respects reduced-motion. Hint rail + `Super+/` address the cognitive-load risk of modal keyboard UIs. Focus is always visible (accent ring on the active tile, 3:1 contrast). Screen-reader: tiles and Bar results are semantic, labeled via the Tool Bus scene graph. High-contrast theme ships alongside light/dark.

See [shell-mockup.svg](shell-mockup.svg) for the grayscale-to-accent visual, and [bar-mockup.svg](bar-mockup.svg) for the Bar.
