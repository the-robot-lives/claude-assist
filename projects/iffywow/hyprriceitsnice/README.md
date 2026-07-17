# hyprriceitsnice

Interactive single-page **Hyprland cheat sheet** for the dual-monitor Tokyo Night rice in `~/.config/hypr`.

## Features

- **Search** binds, apps, tags (`Ctrl/⌘+K`)
- **Category filters** (launch, focus, workspaces, AI, screenshots, …)
- **Virtual keyboard** lights up on bind hover
- **Listen mode** — press combos to flash matching rows
- **Click to copy** `KEYS → action`
- **Monitor map** + **AI workspace layout** diagram
- Apps, rice tokens, autostart summary

## Dev

```bash
cd hyprriceitsnice
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build

```bash
pnpm build && pnpm start
```

## Data source

Bindings are modeled in `src/lib/bindings.ts` from:

- `~/.config/hypr/hyprland.conf`
- `~/.config/hypr/ai-workspace-extension.conf`

Update that file when the rice changes.
