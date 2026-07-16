---
id: M2
name: Retention & Assessment
sequence: 2
depends_on: [M1]
lanes: 4
stories: [US-019, US-020, US-021, US-022, US-023, US-024, US-025, US-026, US-027, US-028, US-029, US-030, US-031, US-032, US-033, US-034, US-035, US-036, US-037, US-038]
---

# M2 — Retention & Assessment

Turns a passive knowledge base into active learning: flashcards with spaced repetition,
quizzes in terminal and browser, graded simulations and projects, and goal-driven learning
plans that adapt to measured performance. Sequenced after M1 because every generator here reads
the knowledge-article contract to build its material.

## Entry criteria

- M1's exit criteria are met.
- The knowledge-article + `knowledge/index.yaml` contract **[C-ARTICLE]** is frozen and merged
  (flashcards and quizzes are generated from real articles).

## Exit criteria

- A flashcard deck can be generated from an article; a daily SM-2 review queue surfaces due
  cards; grading recall reschedules the card per SM-2; due-card counts show per deck; cards
  organize into topic decks (US-019, US-020, US-021, US-022, US-023).
- A quiz can be generated from a topic or article and taken **both** in the terminal
  (`@inquirer/prompts`) and in the browser SPA; results are stored, weak areas identified,
  missed-only retakes supported, and mixed question types render (US-024, US-025, US-026,
  US-027, US-028, US-029).
- The quiz SPA builds to a single HTML file (`cd quiz-spa && npm run build` exits 0 and emits
  one self-contained `.html`) (US-026).
- A terminal role-play simulation runs and produces a graded debrief; a graded project can be
  requested at the user's level, submitted, and evaluated by the grader agent (US-030, US-031,
  US-032, US-033).
- A learning plan can be created for a goal with SMART checkpoints; milestones are tracked and
  checked off; the plan adapts from quiz/review performance data; a weekly progress summary is
  produced; decayed topics resurface automatically (US-034, US-035, US-036, US-037, US-038).
- All 20 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] Flashcard generation + SM-2 queue + grading + due counts + decks work.
- [ ] Quiz generation + terminal runner + SPA runner + results + retake + mixed types work.
- [ ] `cd quiz-spa && npm run build` exits 0 and emits one self-contained HTML file.
- [ ] Simulation + graded debrief + graded project request/submit/evaluate work.
- [ ] Learning plan create/track/adapt/summary/resurface work.
- [ ] All 20 stories' acceptance criteria checked off.
- [ ] M3 Entry criteria reviewed and satisfied.

## Worker lanes

### L2.A — Flashcards & Spaced Repetition
- **Zone / exclusive paths:** `flashcards/**`,
  `template/.claude/agents/kb-flashcard-generator.md`,
  `template/.claude/commands/knowledge-base-flashcard.md`, the SM-2 scheduler.
- **Mission:** Generate Anki-format decks from articles and drive a correct SM-2 review loop.
- **Tasks:**
  - T2.A.1 — Generate flashcards from a knowledge article (US-019).
  - T2.A.2 — Daily SM-2 review queue + per-card grade-and-reschedule (US-020, US-021).
  - T2.A.3 — Due-card counts per deck; organize cards into topic decks (US-022, US-023).
- **Stories delivered:** US-019, US-020, US-021, US-022, US-023.
- **Contracts:** provides the flashcard-deck format + SM-2 scheduling fields **[C-DECK]**,
  consumed by M3 (card search) and M5 (deck export / Anki). Consumes: C-ARTICLE.

### L2.B — Quizzes (Generation, CLI Runner & SPA)
- **Zone / exclusive paths:** `quizzes/**`, `template/.claude/agents/kb-quiz-generator.md`,
  `template/.claude/commands/knowledge-base-quiz.md`, the CLI quiz runner, `quiz-spa/**`.
- **Mission:** Generate quizzes and run them identically in the terminal and the browser SPA,
  storing results that feed weak-area analysis and plan adaptation.
- **Tasks:**
  - T2.B.1 — Generate a quiz from a topic or article; mix question types (US-024, US-029).
  - T2.B.2 — Terminal quiz runner via `@inquirer/prompts` (US-025).
  - T2.B.3 — React quiz SPA that builds to one self-contained HTML file (US-026).
  - T2.B.4 — Store results, identify weak areas, retake only missed questions (US-027,
    US-028).
- **Stories delivered:** US-024, US-025, US-026, US-027, US-028, US-029.
- **Contracts:** provides the quiz-definition + quiz-result format **[C-QUIZ]**, consumed by
  M3 (SPA theme selection), M4 (resume interrupted session), and M5 (Anki export). Consumes:
  C-ARTICLE.

### L2.C — Simulations & Projects
- **Zone / exclusive paths:** `simulations/**`, `projects/**`,
  `template/.claude/agents/kb-grader.md`,
  `template/.claude/commands/knowledge-base-simulate.md`.
- **Mission:** Run terminal role-play simulations and graded project assignments with agent
  evaluation.
- **Tasks:**
  - T2.C.1 — Terminal role-play simulation + graded debrief (US-030, US-031).
  - T2.C.2 — Request a graded project matched to level; submit for grader evaluation (US-032,
    US-033).
- **Stories delivered:** US-030, US-031, US-032, US-033.
- **Contracts:** provides the graded-result format (shared shape with C-QUIZ results),
  consumed by L2.D plan adaptation. Consumes: C-ARTICLE, C-SCHEMAS.

### L2.D — Learning Plans
- **Zone / exclusive paths:** `learning-plan.yaml` handling,
  `template/.claude/commands/knowledge-base-learning-plan.md`, the progress-summary +
  decay-resurface logic.
- **Mission:** Author SMART learning plans and adapt them from measured retention and quiz
  performance.
- **Tasks:**
  - T2.D.1 — Create a learning plan for a goal; track and check off milestones (US-034,
    US-035).
  - T2.D.2 — Adapt the plan from quiz/review performance data (US-036).
  - T2.D.3 — Weekly progress summary; auto-resurface decayed topics (US-037, US-038).
- **Stories delivered:** US-034, US-035, US-036, US-037, US-038.
- **Contracts:** provides the learning-plan format **[C-PLAN]**, consumed by M5 (team plan
  assignment). Consumes: C-QUIZ, C-DECK, C-ARTICLE.

## Cross-lane integration tasks

- T2.X.1 (owned by L2.D) — Adaptation proof: complete a quiz (L2.B) and a review session
  (L2.A), then run plan adaptation (L2.D) and show the plan changed in response to the recorded
  performance data — one flow proving C-QUIZ and C-DECK actually feed C-PLAN.
- T2.X.2 (owned by L2.B) — Parity proof: the same quiz definition runs to an identical result
  record through both the terminal runner and the SPA build (US-025 ↔ US-026).
