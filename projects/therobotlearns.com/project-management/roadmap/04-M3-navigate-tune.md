---
id: M3
name: Navigate & Tune
sequence: 3
depends_on: [M2]
lanes: 2
stories: [US-049, US-050, US-051, US-052, US-053, US-054, US-066, US-067, US-068, US-069, US-070, US-071, US-072, US-073]
---

# M3 — Navigate & Tune

Makes a growing KB findable and the whole system tunable: full-text and structured search over
articles, cards, and quizzes, plus the settings surface that lets each user shape depth,
cadence, style, and the quiz SPA's look. Sequenced after M2 because search needs content to
index and several settings tune M2 features.

## Entry criteria

- M2's exit criteria are met.
- The knowledge-article contract **[C-ARTICLE]**, the flashcard-deck contract **[C-DECK]**,
  and the quiz contract **[C-QUIZ]** are frozen and merged (search indexes them; settings tune
  them).
- The local-preference schema from **[C-SCHEMAS]** is available for the settings surface to
  write against.

## Exit criteria

- Full-text search across KB articles returns ranked results; flashcards and quizzes are
  searchable by topic; the KB browses by tag/category tree (US-066, US-067, US-068).
- `robot-learns "what do I know about X"` returns a synthesized summary drawn from existing
  articles; a knowledge-gaps report lists adjacent topics not yet covered (US-069, US-070).
- Related-article suggestions surface while reading; a recently-added/updated feed and a
  serendipity (random old article) mode work (US-071, US-072, US-073).
- The settings surface edits per-domain expertise, learning style, local-preference fields,
  the quiz SPA theme, review cadence + daily card limits, and default `/query` verbosity —
  each persisted to the correct YAML and honored on the next run (US-049, US-050, US-051,
  US-052, US-053, US-054).
- All 14 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] Full-text search + card/quiz search + tag-tree browse work.
- [ ] "What do I know about X" synthesis + knowledge-gaps report work.
- [ ] Related suggestions + recent feed + serendipity mode work.
- [ ] All six settings persist to the right YAML and are honored next run.
- [ ] All 14 stories' acceptance criteria checked off.
- [ ] M4 Entry criteria reviewed and satisfied.

## Worker lanes

### L3.A — Search & Discovery
- **Zone / exclusive paths:** the search command(s) + discovery logic reading `knowledge/`,
  `flashcards/`, `quizzes/` (read-only over other lanes' stores), the tag/category browse
  index.
- **Mission:** Make everything in the KB findable — by text, by tag, by synthesis, and by
  serendipity.
- **Tasks:**
  - T3.A.1 — Full-text search over articles; search flashcards/quizzes by topic (US-066,
    US-067).
  - T3.A.2 — Browse by tag/category tree; recently-added/updated feed (US-068, US-072).
  - T3.A.3 — "What do I know about X" synthesis; knowledge-gaps report (US-069, US-070).
  - T3.A.4 — Related-article suggestions while reading; serendipity mode (US-071, US-073).
- **Stories delivered:** US-066, US-067, US-068, US-069, US-070, US-071, US-072, US-073.
- **Contracts:** provides the search/query interface **[C-SEARCH]**, consumed by M5 (MCP
  server exposes it). Consumes: C-ARTICLE, C-DECK, C-QUIZ.

### L3.B — Settings & Preferences
- **Zone / exclusive paths:** the settings command, `local-preference.yaml` writes, the
  per-domain expertise + learning-style + verbosity editors, the quiz-SPA theme selector.
- **Mission:** Give every user a single surface to shape depth, cadence, style, and the SPA's
  visual theme — persisted and honored.
- **Tasks:**
  - T3.B.1 — Edit per-domain expertise levels; set learning-style preferences (US-049,
    US-050).
  - T3.B.2 — Configure local preferences via the local-preference schema; set default `/query`
    verbosity (US-051, US-054).
  - T3.B.3 — Choose a visual theme for the quiz SPA; configure review cadence + daily card
    limits (US-052, US-053).
- **Stories delivered:** US-049, US-050, US-051, US-052, US-053, US-054.
- **Contracts:** provides the local-preference surface **[C-PREFS]**, consumed by the query
  and review loops. Consumes: C-SCHEMAS, C-QUIZ (SPA theme), C-DECK (review cadence).

## Cross-lane integration tasks

- T3.X.1 (owned by L3.A) — Tuned-search proof: set a learning-style/verbosity preference in
  L3.B, then run a search + "what do I know about X" (L3.A) and show the result honors the
  preference — one flow proving C-PREFS and C-SEARCH compose.
