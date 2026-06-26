---
id: US-022
title: "Welcome Empty State — No Mutuals Yet"
slug: welcome-empty-state-no-mutuals
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [empty-state, mutuals, onboarding, UX]
---

# US-022: Welcome Empty State — No Mutuals Yet

## User Story

**As a** cautious newcomer
**I want to** the Mutuals lane to show a helpful empty state when I have no mutuals yet
**So that** I understand what to do next rather than seeing a blank screen

## Acceptance Criteria

- **Given** I have zero mutuals
  **When** I open the Mutuals lane
  **Then** I see an illustration and a message explaining that content appears here once I have moots, plus two CTAs: "Find People" and "Invite Friends".

- **Given** I send my first mutual request
  **When** it is pending
  **Then** the empty state updates to "Waiting for your first moot to accept" to show progress.

## Notes
Empty state must not feel punishing. Use warm, encouraging copy. The illustration should be accessible (alt text provided).
