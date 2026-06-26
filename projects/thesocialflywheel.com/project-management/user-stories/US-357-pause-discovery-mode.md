---
id: US-357
title: "Pause Discovery Mode"
slug: pause-discovery-mode
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, pause, settings]
---

# US-357: Pause Discovery Mode

## User Story

**As a** Quiet Consumer
**I want to** pause discovery entirely with a single toggle
**So that** I can take a break from new content exposure without losing my accumulated preferences

## Acceptance Criteria

- **Given** I am on the Discovery Settings page
  **When** I activate the "Pause Discovery" toggle
  **Then** discovery items stop appearing in my feed immediately and the toggle shows active state

- **Given** discovery is paused
  **When** I return to settings and deactivate the toggle
  **Then** discovery items resume in my feed on the next load and my prior topic weights are preserved

## Notes
Pause is indefinite with no automatic expiry; the user must manually re-enable it.
