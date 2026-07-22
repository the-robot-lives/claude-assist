---
id: US-065
title: "View decision history with outcome tracking"
slug: view-decision-history-with-outcome-tracking
personas: [P-003, P-001]
epic: "Review & Reward"
priority: should-have
complexity: medium
tags: [decision-history, outcome-tracking, audit]
---

# US-065: View Decision History With Outcome Tracking

## User Story

**As a** team lead (Sam Okafor) overseeing a hybrid human+agent team
**I want to** browse a history of past picks with what actually shipped from each one
**So that** I can see whether the team's picks have translated into real outcomes and spot patterns of picks that didn't pan out

## Acceptance Criteria

- **Given** a project with multiple past runs
  **When** I open the decision history view
  **Then** I see each run's pick (or rejection), the one-line rationale, the picker's identity, and the grade score of the winning path, ordered by date

- **Given** a picked outcome that was later marked as shipped, reverted, or superseded outside the run itself
  **When** I view that history entry
  **Then** the current shipped-status is reflected, not just the state at pick time

- **Given** a rejected run ([[US-061]])
  **When** it appears in decision history
  **Then** it is clearly distinguished from a normal pick, including its rejection reason and whether a re-plan followed

## Notes
"What shipped" requires a lightweight status field on the decision-history entry that can be updated after the fact (e.g. via channel message or external hook) since Noizu Intellect doesn't necessarily own deployment. Complements [[US-063]] but is outcome-focused rather than weight-focused.
