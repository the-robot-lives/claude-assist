---
id: US-066
title: "Delegate the pick to a Picker agent with human veto"
slug: delegate-the-pick-to-a-picker-agent-with-human-veto
personas: [P-003, P-004]
epic: "Review & Reward"
priority: could-have
complexity: high
tags: [picker-agent, delegation, human-veto]
---

# US-066: Delegate the Pick to a Picker Agent With Human Veto

## User Story

**As a** team lead (Sam Okafor) who doesn't want to review every single run personally
**I want to** delegate the winner-selection step to a Picker agent that acts on my behalf
**So that** low-stakes runs resolve automatically while I retain the ability to override the choice

## Acceptance Criteria

- **Given** a project configured to use a Picker agent for a channel or run type
  **When** a shortlist is ready
  **Then** the Picker agent grades the shortlist against the same comparison criteria a human would see and finalizes a pick with a one-line rationale, exactly as in [[US-060]]

- **Given** a Picker agent's automated pick
  **When** it is finalized
  **Then** it triggers reward back-propagation and memory write-back immediately, but remains open to human veto for a configurable grace window before those effects are treated as final in decision history

- **Given** a human (Priya Natarajan or Sam Okafor) reviewing a Picker agent's pick within the veto window
  **When** they veto it
  **Then** the automated pick is reverted, the reward update is rolled back, and the run returns to the shortlist for manual picking

## Notes
The veto window and rollback behavior are the risky part of this story — reward/memory effects must be cleanly reversible, which depends on [[US-062]] and [[US-067]] recording updates as discrete, revertible entries rather than in-place mutations. Marked could-have because the veto-rollback mechanics are non-trivial and can ship after the manual-pick flow is solid.
