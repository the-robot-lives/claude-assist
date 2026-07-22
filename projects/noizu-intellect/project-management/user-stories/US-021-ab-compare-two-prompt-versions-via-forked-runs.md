---
id: US-021
title: "A/B compare two prompt versions via forked runs"
slug: ab-compare-two-prompt-versions-via-forked-runs
personas: [P-002]
epic: "Agents & Cognition"
priority: should-have
complexity: high
tags: [ab-testing, versioned-content, forked-paths, evaluation]
---

# US-021: A/B Compare Two Prompt Versions via Forked Runs

## User Story

**As a** agent designer/prompt engineer
**I want to** run the same input against two versions of an agent's prompt as parallel forked paths and compare the outcomes
**So that** I can decide which prompt version performs better before committing to it as the live version

## Acceptance Criteria

- **Given** an agent has prompt version 4 (live) and version 5 (candidate)
  **When** I launch an A/B comparison run against a shared context checkpoint
  **Then** two independent paths fork — one executing with version 4, one with version 5 — using the same `tag`/`checkout` mechanic as parallel-path execution

- **Given** both forked paths complete
  **When** I view the comparison
  **Then** I see each path's reply, Reflect-pass cognition patch, and (if a Reviewer grade is available) its grade side by side

- **Given** I decide version 5 performed better
  **When** I confirm it as the winner
  **Then** version 5 becomes (or remains) the agent's live version, and the losing path's short-term memory is discarded per the standard parallel-path outcome mechanic

- **Given** I want to A/B test without affecting the agent's live cognition
  **When** the comparison run executes
  **Then** neither path's short-term memory writes back to the agent's long-term memory until I explicitly pick a winner

## Notes
Reuses the core parallel-path/tag-checkout/grade/pick mechanic, scoped specifically to comparing prompt versions rather than solution approaches. This is the clearest overlap point between "Agents & Cognition" and the parallel-path execution epic — cross-reference accordingly.
