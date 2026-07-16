---
id: M5
name: Collaboration, Cloud & Integrations
sequence: 5
depends_on: [M4]
lanes: 3
stories: [US-074, US-075, US-076, US-077, US-078, US-079, US-080, US-081, US-096, US-097, US-098, US-099, US-100]
---

# M5 — Collaboration, Cloud & Integrations

The outermost layer: move knowledge in and out (bundles, Anki, external notes), sync and share
it (cloud accounts, team KBs, team dashboards), and wire the local KB into the wider tool
ecosystem (git, MCP, `$EDITOR`). Sequenced last because every feature here assumes a healthy,
backed-up, scalable local KB from M4.

## Entry criteria

- M4's exit criteria are met.
- The knowledge-article **[C-ARTICLE]**, flashcard-deck **[C-DECK]**, quiz **[C-QUIZ]**,
  learning-plan **[C-PLAN]**, and backup-archive **[C-BACKUP]** contracts are all frozen and
  merged (export/sync reuse these formats).
- The search interface **[C-SEARCH]** is available for the MCP server to expose.

## Exit criteria

- A flashcard deck or article bundle can be exported; a shared bundle can be imported with a
  conflict-safe merge; merge conflicts on a shared/synced KB can be resolved; decks export to
  Anki; existing external notes can be imported (US-074, US-075, US-081, US-096, US-100).
- The KB can sync to a therobotlearns.com cloud account; a shared team KB works; a team lead
  can assign learning plans to members and view a team progress dashboard (US-076, US-077,
  US-078, US-079).
- Git integration versions the KB; the KB is exposed via an MCP server; any article opens in
  `$EDITOR` (US-097, US-098, US-099).
- Publishing to a public community library (US-080) is explicitly **deferred (won't-have this
  release)** — tracked in the coverage matrix, not built here — and its absence does not block
  the milestone.
- All 12 in-scope stories (US-080 excluded as won't-have) have their acceptance criteria
  checked off.

## Transition checklist

- [ ] Export bundle + import-with-merge + conflict resolution + Anki export + notes import work.
- [ ] Cloud sync + shared team KB + plan assignment + team dashboard work.
- [ ] Git versioning + MCP server + `$EDITOR` open work.
- [ ] US-080 confirmed deferred (won't-have) and recorded in `story-coverage.md`.
- [ ] All 12 in-scope stories' acceptance criteria checked off.

## Worker lanes

### L5.A — Sharing & Interchange
- **Zone / exclusive paths:** the export/import bundle commands, the conflict-safe merge
  engine, the Anki exporter, the external-notes importer.
- **Mission:** Move knowledge across KBs and external tools without losing or clobbering data.
- **Tasks:**
  - T5.A.1 — Export a flashcard deck or article bundle; export decks to Anki (US-074, US-096).
  - T5.A.2 — Import a shared bundle with conflict-safe merge; resolve merge conflicts on a
    shared/synced KB (US-075, US-081).
  - T5.A.3 — Import existing external notes (US-100).
- **Stories delivered:** US-074, US-075, US-081, US-096, US-100.
- **Contracts:** consumes C-ARTICLE, C-DECK, C-BACKUP. Provides the bundle interchange format,
  consumed by L5.B cloud sync.

### L5.B — Cloud & Team
- **Zone / exclusive paths:** the cloud-sync client, the shared/team KB layer, plan assignment,
  the team progress dashboard, the (deferred) community-publish stub.
- **Mission:** Extend the local-first KB to the future therobotlearns.com cloud service and
  team workflows.
- **Tasks:**
  - T5.B.1 — Sync KB to a therobotlearns.com cloud account (US-076).
  - T5.B.2 — Shared team knowledge base; team lead assigns learning plans (US-077, US-078).
  - T5.B.3 — Team progress dashboard for leads (US-079).
  - T5.B.4 — Community-library publish — **deferred (won't-have)**; leave a tracked stub only
    (US-080).
- **Stories delivered:** US-076, US-077, US-078, US-079; US-080 deferred (won't-have).
- **Contracts:** consumes C-ARTICLE, C-PLAN, C-BACKUP, and the L5.A bundle format. Provides
  nothing new.

### L5.C — Local Tooling Integrations
- **Zone / exclusive paths:** the git-versioning wrapper, the MCP server exposing the KB, the
  `$EDITOR` open hook.
- **Mission:** Wire the KB into the developer's existing tools.
- **Tasks:**
  - T5.C.1 — Git integration for KB versioning (US-097).
  - T5.C.2 — Expose the KB via an MCP server (US-098).
  - T5.C.3 — Open any article in `$EDITOR` (US-099).
- **Stories delivered:** US-097, US-098, US-099.
- **Contracts:** consumes C-ARTICLE, C-SEARCH (the MCP server surfaces search). Provides nothing
  new.

## Cross-lane integration tasks

- T5.X.1 (owned by L5.B) — Round-trip proof: export a bundle (L5.A), sync it to a cloud account
  and pull it into a second KB (L5.B), and open a synced article in `$EDITOR` (L5.C) — one flow
  proving the interchange format, cloud sync, and local tooling compose.
