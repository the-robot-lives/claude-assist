# The Robot Learns — Roadmap Overview

## Mission

This roadmap sequences The Robot Learns — a cloud application for personal and team knowledge
retention, assessment, and learning workflows — with a local Claude Code workspace agent as a
supporting capture/generation surface. It orders work by **dependency, not calendar time**:
each milestone lists only what must be true before it starts and before it exits. The spine is
the data: the nine YAML schemas freeze first, the knowledge-article contract freezes next, and
every retention, search, maintenance, sync, team, and sharing feature downstream is keyed to
those frozen contracts so lanes can be built in parallel without colliding.

## Core principles

1. **Sequence, not schedule.** Milestones are ordered by blocking dependency. There are no
   dates, durations, or estimates anywhere in this document set — only entry and exit gates.
2. **Contract-first entry.** Each milestone's Entry criteria name the frozen contracts it
   consumes (`C-SCHEMAS`, `C-CONFIGDIR`, `C-ARTICLE`, `C-QUIZ`, `C-DECK`, `C-PLAN`, `C-SEARCH`,
   `C-BACKUP`). A contract is written once and changed only through the coordinator.
3. **Lane ownership = exclusive paths.** Within a milestone every file/dir glob belongs to
   exactly one lane — the only code that lane may edit. Contested surfaces become contract work
   or a cross-lane integration task.
4. **One primary owner per story.** Every one of the 100 user stories has exactly one primary
   milestone + lane. A second lane appears only in the coverage matrix's **Notes** as
   "supports US-XXX" — never as a second primary owner.
5. **Verifiable gates only.** Every exit criterion is a command that exits 0, a file that
   exists at a stated path, or an explicit "all N stories' acceptance criteria checked off" —
   never "mostly working."
6. **MoSCoW orders within a lane.** Must-haves precede should/could-haves inside a lane's task
   list; priority never reorders milestones.

## Milestone summary

| ID | Name | Mission | Lanes | Stories |
|---|---|---|---|---|
| M0 | Foundation & Onboarding | Launcher, first-run agent environment, profiles, and the nine schema contracts | 3 | 14 |
| M1 | Calibrated Q&A & Knowledge Base | The ask → answer → auto-save → browse core value loop | 3 | 18 |
| M2 | Retention & Assessment | Flashcards, quizzes (terminal + SPA), simulations, projects, learning plans | 4 | 20 |
| M3 | Navigate & Tune | Full-text/structured search and the settings surface | 2 | 14 |
| M4 | Maintain, Harden & Scale | Hygiene, backup/restore/migration, resilience, performance, accessibility | 4 | 21 |
| M5 | Collaboration, Cloud & Integrations | Cloud sync, team KBs, export/import, git/MCP/`$EDITOR` | 3 | 13 |

Story count check: M0=14, M1=18, M2=20, M3=14, M4=21, M5=13 → 100, matching the 100-story
corpus. See [`story-coverage.md`](story-coverage.md) for the full traceability matrix.

## How to read this roadmap

1. Open your milestone's doc; read its **Entry criteria** — every contract and prior-milestone
   gate it names must already be satisfied.
2. Find your lane; its **Zone / exclusive paths** line is the only code you may edit.
3. Work the lane's task list in priority order (musts before shoulds/coulds).
4. A milestone isn't done from one lane's view — exit requires every lane's exit criteria plus
   the cross-lane integration task that proves the lanes compose.

## Traceability

Every user story is assigned to exactly one primary milestone/lane; see
[`story-coverage.md`](story-coverage.md) for the full matrix.
