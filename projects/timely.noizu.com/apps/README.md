# Timely App Surfaces

This directory contains the initial implementation scaffolds for Timely's four product surfaces.

| Surface | Path | Purpose | Current State |
|---------|------|---------|---------------|
| macOS app | `macos/` | Desktop capture agent, menu/status, permissions, local capture state | SwiftUI scaffold |
| Android app | `android/` | Mobile companion for review, idle prompts, and reporting checks | Kotlin Compose scaffold |
| Web app | `web-app/` | Authenticated dashboard, timeline review, billing/reporting workspace | Dependency-free prototype |
| Web portal | `web-portal/` | Public product portal for positioning, trust, and alpha signup | Dependency-free prototype |

The dependency-free web surfaces can be opened directly in a browser, though a local static server is cleaner for loading shared fixtures.

```bash
cd projects/timely.noizu.com
python3 -m http.server 4173
```

Then open:

- `http://127.0.0.1:4173/apps/web-app/`
- `http://127.0.0.1:4173/apps/web-portal/`

