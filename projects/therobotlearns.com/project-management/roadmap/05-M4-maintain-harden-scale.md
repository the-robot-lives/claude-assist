---
id: M4
name: Maintain, Harden & Scale
sequence: 4
depends_on: [M3]
lanes: 4
stories: [US-056, US-057, US-058, US-059, US-060, US-061, US-062, US-063, US-064, US-065, US-082, US-083, US-087, US-088, US-089, US-090, US-091, US-092, US-093, US-094, US-095]
---

# M4 — Maintain, Harden & Scale

Keeps the KB healthy, recoverable, fast at scale, and accessible: hygiene and integrity checks,
backup/restore/migration, resilience against interruption and corruption, performance at
thousands of entries, and a dedicated accessibility + i18n pass over the surfaces built in
M1–M2. Sequenced here because these harden the features those milestones delivered.

## Entry criteria

- M3's exit criteria are met.
- The knowledge-article contract **[C-ARTICLE]** and the quiz contract **[C-QUIZ]** are frozen
  (hygiene validates them; resume replays a quiz session).
- The terminal and quiz-SPA surfaces from M1/M2 exist (the accessibility lane hardens them).

## Exit criteria

- `robot-learns --validate` checks every KB file against its schema and reports violations;
  `index.yaml` can be rebuilt from files on disk; duplicate articles are detected with merge
  suggestions; stale articles can be pruned/archived; KB stats + growth are viewable (US-056,
  US-057, US-058, US-059, US-060).
- A corrupted YAML file is quarantined with clear guidance instead of crashing the session
  (US-082).
- Template-version migration runs with an automatic pre-migration backup; the KB can be backed
  up on demand or on schedule, restored from a chosen backup, and relocated to a custom
  directory; a launcher-vs-template version mismatch is detected with guided resolution
  (US-061, US-062, US-063, US-064, US-065, US-087).
- An interrupted quiz or simulation resumes from where it stopped (US-083).
- Launcher startup meets its stated time budget; the KB stays responsive at thousands of
  entries; agent operations are token-frugal; the KB index updates incrementally rather than
  fully rebuilding (US-092, US-093, US-094, US-095).
- Terminal output is screen-reader-friendly; the quiz SPA passes a WCAG 2.2 AA audit (0
  critical violations); content is available in the user's preferred language; text size +
  high-contrast theme are adjustable (US-088, US-089, US-090, US-091).
- All 21 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `--validate` + rebuild-index + dedupe + prune + stats work.
- [ ] Corrupted-YAML quarantine works with clear guidance.
- [ ] Migrate + pre-migration backup + backup + restore + relocate + version-mismatch work.
- [ ] Interrupted quiz/simulation resume works.
- [ ] Startup budget, scale-to-thousands, token-frugality, incremental index all met.
- [ ] Screen-reader output + WCAG 2.2 AA SPA + preferred language + text/contrast work.
- [ ] All 21 stories' acceptance criteria checked off.
- [ ] M5 Entry criteria reviewed and satisfied.

## Worker lanes

### L4.A — KB Hygiene & Integrity
- **Zone / exclusive paths:** the validate/rebuild/dedupe/prune/stats maintenance commands and
  the corrupted-file quarantine path (read/write over `knowledge/` for hygiene only).
- **Mission:** Keep the KB internally consistent and self-healing.
- **Tasks:**
  - T4.A.1 — Validate KB files against schemas; rebuild `index.yaml` from disk (US-056,
    US-057).
  - T4.A.2 — Detect duplicate articles + suggest merges; prune/archive stale articles (US-058,
    US-059).
  - T4.A.3 — KB stats + growth over time; quarantine corrupted YAML with guidance (US-060,
    US-082).
- **Stories delivered:** US-056, US-057, US-058, US-059, US-060, US-082.
- **Contracts:** consumes C-ARTICLE, C-SCHEMAS. Provides nothing new.

### L4.B — Backup, Restore & Migration
- **Zone / exclusive paths:** the backup/restore/relocate commands, the template-version
  migration engine, the version-mismatch detector, the backup archive format.
- **Mission:** Make the KB durable and upgradable without data loss.
- **Tasks:**
  - T4.B.1 — Migrate KB on new launcher template version; automatic pre-migration backup
    (US-061, US-062).
  - T4.B.2 — Back up on demand or on schedule; restore from a chosen backup (US-063, US-064).
  - T4.B.3 — Relocate the KB to a custom directory; detect launcher-vs-template version
    mismatch with guided resolution (US-065, US-087).
- **Stories delivered:** US-061, US-062, US-063, US-064, US-065, US-087.
- **Contracts:** provides the backup-archive format **[C-BACKUP]**, consumed by M5 (cloud sync
  / export reuse). Consumes: C-ARTICLE, C-WRITE.

### L4.C — Resilience & Performance
- **Zone / exclusive paths:** the session-resume logic, the startup fast-path, the
  incremental-index updater, the token-budget instrumentation.
- **Mission:** Make sessions recoverable and the whole system fast at scale.
- **Tasks:**
  - T4.C.1 — Resume an interrupted quiz or simulation session (US-083).
  - T4.C.2 — Fast launcher startup; token-frugal agent operations (US-092, US-094).
  - T4.C.3 — Scale the KB to thousands of entries; incremental index updates (US-093, US-095).
- **Stories delivered:** US-083, US-092, US-093, US-094, US-095.
- **Contracts:** consumes C-QUIZ, C-ARTICLE. Provides nothing new.

### L4.D — Accessibility & i18n
- **Zone / exclusive paths:** the terminal screen-reader output mode, the quiz-SPA a11y
  hardening (`quiz-spa/**` a11y layer), the language-selection + high-contrast/text-size
  options.
- **Mission:** Make both surfaces usable by screen-reader users, low-vision users, and
  non-English speakers.
- **Tasks:**
  - T4.D.1 — Screen-reader-friendly terminal output (US-088).
  - T4.D.2 — Quiz SPA meets WCAG 2.2 AA (US-089).
  - T4.D.3 — Preferred-language content; adjustable text size + high-contrast theme (US-090,
    US-091).
- **Stories delivered:** US-088, US-089, US-090, US-091.
- **Contracts:** consumes C-QUIZ (SPA surface), C-ARTICLE (terminal surface). Provides nothing
  new.

## Cross-lane integration tasks

- T4.X.1 (owned by L4.B) — Disaster-recovery proof: corrupt a file so L4.A quarantines it,
  then restore from a backup (L4.B) and re-validate clean (L4.A) — one flow proving hygiene and
  backup/restore compose over C-ARTICLE and C-BACKUP.
- T4.X.2 (owned by L4.C) — Scale proof: seed thousands of entries, then show incremental index
  update + startup budget hold, and an interrupted quiz resumes correctly at that scale.
