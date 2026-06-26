---
id: US-328
title: "No Reply Affordance Rendered in Opposing-View Lane"
slug: no-reply-affordance-rendered
personas: [P-005]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, read-only, ui, interaction-boundary]
---

# US-328: No Reply Affordance Rendered in Opposing-View Lane

## User Story

**As a** debate seeker
**I want to** see the opposing-view post rendered without any reply, react, or quote controls
**So that** the read-only nature of the lane is visually unambiguous

## Acceptance Criteria

- **Given** I view any post in the Opposing-Views Lane
  **When** the post component renders
  **Then** the DOM contains no reply button, reaction picker, quote button, or share-to-feed control

- **Given** I inspect the post via browser DevTools
  **When** I search for reply-related elements
  **Then** no hidden or display:none reply affordances exist in the markup

## Notes
Removing controls from the DOM (rather than hiding via CSS) prevents accidental keyboard focus on invisible interactive elements.
