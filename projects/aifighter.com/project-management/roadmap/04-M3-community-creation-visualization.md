---
id: M3
name: "Community, Creation & Visualization"
sequence: 3
depends_on: [M1, M2]
lanes: 3
stories: [US-010, US-024, US-025, US-026, US-027, US-037, US-039, US-081, US-082, US-083, US-084, US-085, US-088, US-089, US-090, US-091, US-092, US-093, US-094, US-095, US-096, US-097, US-098, US-099, US-100]
---

# M3 — Community, Creation & Visualization

The Laboratory and the creator layer — the "Discover and Share" pillar. Build sharing, replay
theater, guide authoring, graph-visualization export, and the streaming/creator toolset that
turns AI Fighter into a spectator and content platform. Sequenced after M1 (replays exist to
share) and M2 (training artifacts and graph history exist to visualize and export).

## Entry criteria

- M1's exit criteria are met: replays, the decision overlay, and share-ready battle output
  exist for the theater and creator tools to build on.
- M2's exit criteria are met: graph version history and export formats exist for the
  visualization and diff features to render.
- The M0 replay contract and M2 training/export contract are frozen — the viz and creator lanes
  key against them.

## Exit criteria

- Build sharing + community feed work: `npm run test:lab` exits 0 for guide authoring, curated
  community feed, tier-list builder, archetype comparison, and replay share links.
- Graph visualization exports cleanly: `npm run test:viz-export` exits 0 for hi-res SVG/PNG
  export, color themes, alignment tools, visual diff, and node-annotation labels.
- Creator/streaming tools produce media: `npm run test:creator` exits 0 for MP4 replay export
  with overlay, theater mode, time-lapse export, and the streamer dashboard.
- A shared graph re-imports: a graph exported from the gallery `file exists` as importable and
  `npm run test:viz-export roundtrip` exits 0.
- All 25 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `npm run test:lab` exits 0
- [ ] `npm run test:viz-export` exits 0 (SVG/PNG, themes, diff, annotations)
- [ ] `npm run test:creator` exits 0 (MP4 + theater + time-lapse + dashboard)
- [ ] `npm run test:viz-export roundtrip` exits 0
- [ ] All 25 M3 stories' acceptance criteria checked off
- [ ] M4 Entry criteria reviewed and satisfied

## Worker lanes

### L3.A — Laboratory & Community Client
- **Zone / exclusive paths:** `client/lab/`, `client/community/`
- **Mission:** The community-and-discovery surface — sharing builds and guides, curated feeds,
  and comparison/analysis tools.
- **Tasks:**
  - T3.A.1 — Build-guide authoring/publishing and one-tap highlight-clip share to social
    (US-025, US-010).
  - T3.A.2 — Curated community "fight of the week" feed and replay share links with a
    decision-overlay preset (US-024, US-039).
  - T3.A.3 — Screenshot export with UI-skin options, tier-list builder, and archetype
    side-by-side comparison (US-026, US-027, US-037).
- **Stories delivered:** US-010, US-024, US-025, US-026, US-027, US-037, US-039
- **Contracts:** provides the sharing/feed surface. Consumes: M1 replay-view components, M2
  export contract, L0.D tokens. Supports: L4.B moderation reviews the curated feed (US-024).

### L3.B — Graph Visualization & Export
- **Zone / exclusive paths:** `client/viz/`, `engine/render-export/`
- **Mission:** Turn the fighter graph into a shareable visual artifact — high-fidelity export,
  cosmetic theming, layout tooling, and versioned visual diff.
- **Tasks:**
  - T3.B.1 — Hi-res SVG/PNG export, alignment/distribution tools, and node-annotation labels
    (US-088, US-093, US-100).
  - T3.B.2 — Graph color-theme cosmetics, gallery sharing, and featured-graph spotlight
    (US-089, US-090, US-098).
  - T3.B.3 — Training-heatmap art print, performance-curve animation export, and graph
    versioning with visual diff (US-091, US-095, US-097).
- **Stories delivered:** US-088, US-089, US-090, US-091, US-093, US-095, US-097, US-098, US-100
- **Contracts:** provides the viz-export renderer [consumed by L3.C creator tools]. Consumes:
  M0 graph contract, M2 training/export contract, L0.D tokens.

### L3.C — Creator & Streaming Tools
- **Zone / exclusive paths:** `client/creator/`, `backend/streaming/`
- **Mission:** The content-creation and streaming toolset — clean recording, media export,
  affiliate/creator programs, and viewer-facing tournament surfaces.
- **Tasks:**
  - T3.C.1 — MP4 replay export with decision overlay, theater mode for clean recording, and
    training time-lapse export (US-081, US-082, US-083).
  - T3.C.2 — Creator affiliate enrollment, tournament bracket mode, and bracket embed for
    external streams (US-084, US-085, US-099).
  - T3.C.3 — Replay sharing with embedded overlay links, streamer dashboard with viewer-facing
    stats, and live decision-overlay commentary mode (US-092, US-094, US-096).
- **Stories delivered:** US-081, US-082, US-083, US-084, US-085, US-092, US-094, US-096, US-099
- **Contracts:** provides creator media exports + streamer surfaces. Consumes: L3.B viz-export
  renderer, M1 replay-view components, M0 replay contract.

## Cross-lane integration tasks

- T3.X.1 (owned by L3.C) — Share-to-stream proof: a build shared through the Laboratory (L3.A),
  rendered by the viz exporter (L3.B), is captured in theater mode and exported as an MP4 with
  the decision overlay and an embeddable bracket (L3.C), then re-imported from its share link.
  Gate: `npm run test:e2e:share` exits 0.
