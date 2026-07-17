# hyprriceitsnice

Hyprland cheat sheet for the dual-monitor Tokyo Night rice — **three peers, side by side** (not replacements for each other):

| Peer | Path | When to use |
|------|------|-------------|
| **Next.js app** | `src/` · `pnpm dev` | Full app, typed data (`src/lib/bindings.ts`), local server |
| **Standalone HTML** | `standalone/hyprriceitsnice.html` | Zero install · cheatsheet **+ flashcards + quiz** (CDN) |
| **Markdown** | `cheatsheet.md` | Static notes / grep / offline plain text |

Also mirrored next to the rice:

- `~/.config/hypr/hyprriceitsnice.html`
- `~/.config/hypr/hyprriceitsnice-cheatsheat.md`

```
hyprriceitsnice/
├── src/                    # Next.js App Router UI
├── standalone/
│   └── hyprriceitsnice.html   # CDN single-page (source of truth for HTML)
├── public/
│   └── hyprriceitsnice.html   # same file, served at /hyprriceitsnice.html
├── cheatsheet.md              # static markdown peer
└── package.json
```

Each UI links to the others in the header when it makes sense.

---

## Next.js app

```bash
pnpm install
pnpm dev          # http://localhost:3000
pnpm build && pnpm start
```

- Interactive: search, filters, virtual keyboard, listen mode, click-to-copy  
- Data: `src/lib/bindings.ts`  
- From the app, open **Standalone HTML →** (`/hyprriceitsnice.html`)

---

## Standalone HTML (peer)

```bash
# open the source file directly
xdg-open standalone/hyprriceitsnice.html

# or via package script
pnpm open:html

# or while Next is running
# http://localhost:3000/hyprriceitsnice.html
# deep links: #cheatsheet | #flashcards | #quiz
```

- One file, vanilla JS  
- Tailwind via `cdn.tailwindcss.com` (needs network)  
- **Modes:** Cheatsheet · Flashcards · Quiz  
- Flashcard/quiz UX lifted from `therobotlearns.com/quiz-app` (MC, T/F, multi-select, fill-in-blank, results) + flashcard flip + 1–4 grade  
- Keep `standalone/` and `public/` in sync after edits:

```bash
pnpm sync:html
```

---

## Markdown peer

```bash
less cheatsheet.md
# or
less ~/.config/hypr/hyprriceitsnice-cheatsheat.md
```

---

## Data source

All three track:

- `~/.config/hypr/hyprland.conf`
- `~/.config/hypr/ai-workspace-extension.conf`

When the rice changes, update **`src/lib/bindings.ts`** (Next) and the data block in **`standalone/hyprriceitsnice.html`**, then `pnpm sync:html`. Refresh `cheatsheet.md` if you still use the markdown peer.
