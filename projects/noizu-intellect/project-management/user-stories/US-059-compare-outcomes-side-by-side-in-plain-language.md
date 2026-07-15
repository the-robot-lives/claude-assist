---
id: US-059
title: "Compare outcomes side-by-side in plain language"
slug: compare-outcomes-side-by-side-in-plain-language
personas: [P-004]
epic: "Review & Reward"
priority: must-have
complexity: high
tags: [comparison, plain-language, non-technical]
---

# US-059: Compare Outcomes Side-by-Side in Plain Language

## User Story

**As a** non-technical PM (Priya Natarajan) acting as the human-in-the-loop picker
**I want to** view the shortlisted path outcomes as side-by-side comparison cards written in plain language, not raw agent transcripts
**So that** I can evaluate and choose between them without needing to understand agent internals, tags/checkouts, or reflection patches

## Acceptance Criteria

- **Given** a shortlisted set of graded path outcomes
  **When** I open the comparison view
  **Then** each path renders as a card with a plain-language summary of what the path did, its outcome, and its grade rationale — with no exposed jargon like "checkout," "reflection patch," or raw model output

- **Given** two or more comparison cards displayed together
  **When** I scan them
  **Then** differences between the paths (approach taken, result, notable tradeoffs) are visually highlighted so I don't have to manually diff the prose myself

- **Given** a comparison card whose plain-language summary I find unclear
  **When** I expand it
  **Then** I can drill into more detail (still in plain language) before falling back to the raw transcript as a last resort

## Notes
This is the core UX deliverable for P-004. The plain-language summary is itself agent-generated content and should be versioned so summary quality can be iterated on without losing history. Feeds into the pick action in [[US-060]].
