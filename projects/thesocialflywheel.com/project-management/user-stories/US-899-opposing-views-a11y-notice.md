---
id: US-899
title: "Accessible Notice for Opposing-Views Lane Restrictions"
slug: opposing-views-a11y-notice
personas: [P-001, P-008]
epic: "Accessibility & Internationalization"
priority: could-have
complexity: low
tags: [screen-reader, opposing-views, lanes, accessibility]
---

# US-899: Accessible Notice for Opposing-Views Lane Restrictions

## User Story

**As a** Bridge-Builder using a screen reader
**I want to** the Opposing-Views lane's read-only restriction to be clearly announced on entry
**So that** I do not waste effort trying to post or react and then receive a confusing silent failure

## Acceptance Criteria

- **Given** I enter the Opposing-Views lane
  **When** the lane loads
  **Then** a polite live region announces "Opposing-Views lane: read-only. You can view and translate posts but cannot reply or react here"

- **Given** I tab to the post composer area while in Opposing-Views
  **When** my screen reader reads the region
  **Then** it announces "Posting is disabled in this lane" via an `aria-disabled` or visually-hidden description

- **Given** I attempt a keyboard-triggered reaction (e.g., pressing E for emoji) while in Opposing-Views
  **When** the action is blocked
  **Then** an accessible inline error message explains the restriction rather than silently ignoring the keypress

## Notes
The read-only restriction should be discoverable before the user attempts any action — not only surfaced as an error after the attempt. Consider also adding a persistent visually-hidden landmark label "Read-only lane" on the Opposing-Views region.
