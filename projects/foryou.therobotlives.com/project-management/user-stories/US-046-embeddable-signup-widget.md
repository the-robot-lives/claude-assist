---
id: US-046
title: "Embed a drop-in signup widget"
slug: embeddable-signup-widget
personas: [P-006, P-007]
epic: "Signups & Subscriptions"
priority: must-have
complexity: high
tags: [widget, embed, listmonk-replacement, item-3]
---

# US-046: Embed a drop-in signup widget

## User Story

**As a** developer maintaining an external portfolio site
**I want to** embed a signup form with one script/iframe snippet
**So that** I stop copy-pasting bespoke React forms per site

## Acceptance Criteria

- **Given** a List exists
  **When** I add the widget snippet pointing at that List
  **Then** a working signup form renders with fields derived from the List's attributes
- **Given** the widget loads on an external origin
  **When** a visitor submits
  **Then** the submission posts cross-origin and succeeds (US-048)
- **Given** a slow connection or assistive technology
  **When** the widget renders
  **Then** it remains usable, accessible, and degrades gracefully

## Notes
MANDATORY — the listmonk-replacement vehicle (plan item 3). One embed line
replaces the per-site copy-pasted form.
