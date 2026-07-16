# AI Fighter Roadmap — Overview

## Mission

This roadmap sequences the 100 user stories of AI Fighter into five dependency-ordered
milestones so a fleet of agents can build them with maximum parallelism and zero merge
conflicts. It orders work by **what must be true before a milestone can start**, never by
calendar time — the graph data model and battle engine are the origin because every other
system consumes a fighter graph and a battle result. Accessibility baselines and the
no-pay-to-win fairness guarantee are placed at the foundation, not bolted on at the end,
because they are contracts every later screen and system must inherit.

## Core principles

1. **Sequence, not schedule.** A milestone's position is fixed by its dependencies, not by
   duration. There are no dates, durations, or estimates anywhere in this document set — only
   entry gates (what must already be merged) and exit gates (what must be demonstrably true).
2. **Contracts are the cut points.** Each milestone's Entry criteria name the frozen
   interfaces later lanes consume — the JSON graph schema, the battle-result/decision-trace
   format, the arena API, the design-token set. Freeze the contract once, then fan out.
3. **One owner per path.** Every lane lists the exclusive file globs it may edit. Two lanes
   never share a writable path; contested surfaces are promoted to contract work (frozen in an
   earlier lane) or integration work (a named cross-lane task).
4. **MoSCoW orders within a lane, not across milestones.** Musts come before Shoulds/Coulds
   inside a lane's task list; a later milestone's Must never blocks an earlier milestone's
   Could. Priority never moves a story between milestones — dependency does.
5. **Accessibility and fairness are foundations.** Touch-target, reduced-motion, non-color-state,
   and color-vision baselines are frozen in M0's design system; the "win by design, not wallet"
   guarantee (server-side sim resolves from the graph alone) is frozen in M0's engine. Later
   milestones inherit them rather than re-litigating them.
6. **Integration is a named task, not a hope.** Every multi-lane milestone ends with an
   explicit cross-lane task that proves the lanes actually compose end-to-end.

## Milestone summary

| ID | Name | Mission | Lanes | Stories |
|---|---|---|---|---|
| M0 | Foundation: Graph Studio & Battle Engine | Freeze the graph schema, ship the visual editor, the deterministic battle engine, and the design-system + fairness baselines everything else consumes. | 4 | 15 |
| M1 | Core Play Loop | Deliver the first playable end-to-end loop: onboard → build → submit to ranked → battle resolves → watch the replay. | 3 | 20 |
| M2 | Training, Evolution & Research | Ship the Training Gym and the analytics/reproducibility tooling that turns battles into a learning loop. | 3 | 16 |
| M3 | Community, Creation & Visualization | Open the Laboratory: build sharing, replay theater, creator/streaming tools, and graph-visualization export. | 3 | 25 |
| M4 | Education, Family, Accessibility & Launch Readiness | Harden for classrooms, families, and assistive tech; add moderation, progression, and competition polish for launch. | 4 | 24 |

Story count check: M0=15, M1=20, M2=16, M3=25, M4=24 → 100, matching the 100-story corpus.
See [`story-coverage.md`](story-coverage.md) for the full traceability matrix.

## How to read this roadmap

1. Open your milestone's doc; read its **Entry criteria** — everything it depends on must
   already be satisfied and merged before you start.
2. Find your lane; its **Zone / exclusive paths** line is the only code you may edit.
3. Work the lane's task list in priority order (Musts before Shoulds/Coulds).
4. A milestone is not done from one lane's view — exit requires every lane's exit criteria
   plus the cross-lane integration task.

## Traceability

Every one of the 100 user stories is assigned to exactly one primary milestone/lane; a second
lane is recorded only in the **Notes** column when it materially supports a story (e.g. the
moderation lane supporting a community-feed story). See
[`story-coverage.md`](story-coverage.md) for the full matrix.
