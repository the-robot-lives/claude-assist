---
id: M1
name: Calibrated Q&A & Knowledge Base
sequence: 1
depends_on: [M0]
lanes: 3
stories: [US-001, US-002, US-003, US-004, US-005, US-006, US-007, US-008, US-009, US-010, US-011, US-012, US-013, US-014, US-015, US-016, US-017, US-018]
---

# M1 — Calibrated Q&A & Knowledge Base

The core value loop: ask a question, get an answer calibrated to your expertise and machine,
and have that answer captured as a growing knowledge base. Sequenced first after Foundation
because every retention, search, and sharing feature downstream operates on the articles this
milestone produces.

## Entry criteria

- M0's exit criteria are met.
- The nine schemas **[C-SCHEMAS]**, the config-dir layout **[C-CONFIGDIR]**, the atomic-write
  helper **[C-WRITE]**, and the launcher surface **[C-LAUNCH]** are frozen and merged.

## Exit criteria

- `robot-learns "what is a zebra"` returns an answer whose depth matches the user's
  per-domain expertise and respects `machine-profile.yaml` (e.g. OS-appropriate commands)
  (US-001, US-002, US-003).
- Every answer is auto-saved as a knowledge-article file under `knowledge/` that conforms to
  the knowledge-article schema (`yq e '.' knowledge/**/... ` validates), and
  `knowledge/index.yaml` is updated in the same run (US-004, US-007, US-014).
- Generated articles carry inline source citations and can be flagged verified; a stale
  article can be refreshed in place (US-015, US-016, US-009).
- Related articles are cross-linked and adjacent topics suggested after a query; a
  compare/contrast query can be saved as a comparison article (US-005, US-006, US-018).
- A follow-up question reuses the prior answer's context; a single-query beginner override
  works without mutating the saved profile (US-010, US-017).
- `robot-learns` renders an article and browses/opens past session logs from the terminal;
  every Q&A run appends a session log (US-008, US-011, US-012, US-013).
- All 18 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `robot-learns "<query>"` returns a profile-calibrated, machine-aware answer.
- [ ] Answers auto-save as schema-valid articles and update `knowledge/index.yaml`.
- [ ] Citations present; verify + refresh flows work.
- [ ] Cross-links, adjacent-topic suggestions, and comparison articles work.
- [ ] Follow-up context + single-query beginner override work.
- [ ] Terminal article viewer + session-log browsing work; every run logs a session.
- [ ] All 18 stories' acceptance criteria checked off.
- [ ] M2 Entry criteria reviewed and satisfied.

## Worker lanes

### L1.A — Query & Calibration Agent
- **Zone / exclusive paths:** `template/.claude/commands/knowledge-base-query.md`,
  `template/.claude/agents/kb-doc-writer.md`, `template/.claude/agents/kb-topic-expander.md`.
- **Mission:** Turn a raw question into a calibrated answer using the user + machine profiles,
  with follow-up context, depth overrides, and adjacent-topic expansion.
- **Tasks:**
  - T1.A.1 — Calibrated `/query` reading per-domain expertise + machine profile (US-001,
    US-002, US-003).
  - T1.A.2 — Follow-up questions that carry prior context; single-query beginner override
    (US-010, US-017).
  - T1.A.3 — Suggest adjacent topics and refresh a stale article on demand (US-006, US-009).
- **Stories delivered:** US-001, US-002, US-003, US-006, US-009, US-010, US-017.
- **Contracts:** provides the `/query` answer payload, consumed by L1.B for persistence.
  Consumes: C-SCHEMAS, C-CONFIGDIR.

### L1.B — Knowledge Base Store & Article Formatting
- **Zone / exclusive paths:** `knowledge/**` layout, the `knowledge/index.yaml` writer,
  article-formatting logic keyed to the knowledge-article schema, citation + cross-link + tag
  handling.
- **Mission:** Persist answers as schema-conformant, cited, cross-linked, tagged articles and
  keep the KB index current — freezing the on-disk knowledge-article contract everything
  downstream reads.
- **Tasks:**
  - T1.B.1 — Auto-save answers as schema-conformant articles; keep `knowledge/index.yaml`
    current (US-004, US-007, US-014).
  - T1.B.2 — Inline source citations; mark-verified flag (US-015, US-016).
  - T1.B.3 — Cross-link related articles; save compare/contrast as a comparison article
    (US-005, US-018).
  - T1.B.4 — Tag/categorize articles; append a session log per run (US-013, US-011).
- **Stories delivered:** US-004, US-005, US-007, US-011, US-013, US-014, US-015, US-016,
  US-018.
- **Contracts:** provides the knowledge-article on-disk format + `knowledge/index.yaml` schema
  **[C-ARTICLE]**, consumed by M2 (card/quiz generation), M3 (search/maintenance), and M5
  (export). Consumes: C-SCHEMAS, C-WRITE.

### L1.C — Terminal Viewer
- **Zone / exclusive paths:** terminal article-render helpers, the session-log viewer.
- **Mission:** Read the KB back in the terminal — render an article cleanly and browse past
  session logs.
- **Tasks:**
  - T1.C.1 — Render a knowledge article from the terminal with readable formatting (US-008).
  - T1.C.2 — List and open past session logs (US-012).
- **Stories delivered:** US-008, US-012.
- **Contracts:** provides nothing new. Consumes: C-ARTICLE, C-CONFIGDIR.

## Cross-lane integration tasks

- T1.X.1 (owned by L1.B) — Full loop proof: a `/query` run (L1.A) produces an answer, persists
  it as a schema-valid article with citations and an index entry (L1.B), and the terminal
  viewer (L1.C) renders it and the session log — one command exercising all three lanes and
  the C-ARTICLE contract.
