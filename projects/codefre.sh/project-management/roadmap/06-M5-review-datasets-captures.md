# M5 — Review, Datasets & Captures

**Impl-plan stages:** 8, 9 · **Stories:** 22

## Mission

Turn eval output back into eval input — the learning loop. Lane A ships the freeball
review queue and promotion flow (tentative nodes become authored script versions).
Lane B ships datasets: request/expected-output pairs, versioning, CSV/JSON import, and
model-based eval runs. Lane C ships manually flagged captures that promote into script
nodes or dataset entries. Lanes are independent given M3/M4.

## Entry criteria

- M3 exit: freeball runs produce tentative nodes with confidence.
- M4 exit: run detail + review-adjacent surfaces exist; script fork/versioning (US-046,
  M2) supports promotion targets.

## Exit criteria

- A freeball chain can be claimed, approved, and promoted into a new script version;
  rejected freeballs feed a regression suite.
- A dataset imported from CSV runs against an agent with a rubric attached and yields
  per-entry scores; persona fan-out works for dataset runs.
- A flagged capture (manual mode) promotes into a script-node input and a dataset entry.

## Lane A — Freeball review & promotion (8 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/review/`
(review_queue, branch_promotions), review queue/detail screens.

| Story | Title | Pri |
|---|---|---|
| US-088 | Show the freeball review queue | P1 |
| US-089 | Claim, approve, or reject a freeball node | P1 |
| US-090 | Promote a freeball chain to a new script version | P1 |
| US-137 | Regression suite from rejected freeballs | P2 |
| US-138 | Bulk actions on the freeball review queue | P2 |
| US-140 | Review assignment workflow | P2 |
| US-139 | Promote a freeball expectation to a persona-scoped expectation | P3 |
| US-141 | Freeball SLA aging alerts | P3 |

Promotion records unblock US-127 (freeball learning mode, M3 Lane B tail).

## Lane B — Datasets (9 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/datasets/`, dataset
list/detail screens.

| Story | Title | Pri |
|---|---|---|
| US-101 | Create a dataset of request / expected-output pairs | P1 |
| US-102 | Publish a new dataset version | P1 |
| US-103 | Add entries to a dataset manually | P1 |
| US-104 | Import a dataset from CSV or JSON | P1 |
| US-105 | Run a dataset against an agent (model-based eval) | P1 |
| US-110 | Attach a rubric to a dataset | P1 |
| US-125 | Dataset-run persona fan-out | P3 |
| US-149 | HuggingFace datasets integration | P2 |
| US-150 | Export datasets as Parquet | P2 |

## Lane C — Flagged captures, manual mode (5 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/` flagged_captures modules,
flagged-captures library screen.

| Story | Title | Pri |
|---|---|---|
| US-106 | Flag a production interaction for future eval use (manual mode; OTel-span flagging + auto mode finalize in M6) | P1 |
| US-107 | Browse the flagged captures library | P1 |
| US-108 | Promote a flagged capture to a script node input | P1 |
| US-109 | Promote a flagged capture to a dataset entry | P1 |
| US-148 | Flag digest email | P3 |

## Cross-lane integration task

A freeball chain from an M3 demo run is approved and promoted to script v2; a capture
flagged from that run's detail view is promoted into a dataset entry; the dataset then
runs against the agent with a rubric — one artifact traversing all three lanes.
