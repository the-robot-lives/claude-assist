---
id: US-303
title: "Read-Only No-Respond Boundary"
slug: read-only-no-respond-boundary
personas: [P-005]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, read-only, interaction-boundary]
---

# US-303: Read-Only No-Respond Boundary

## User Story

**As a** debate seeker
**I want to** understand clearly that I cannot reply to posts in the Opposing-Views Lane
**So that** I am not frustrated by a missing reply button and know the design intent

## Acceptance Criteria

- **Given** I view a post in the Opposing-Views Lane
  **When** I look for reply, quote, or reaction affordances
  **Then** none of those controls are rendered; only Save and Report are available

- **Given** I try to interact via a keyboard shortcut I use in other lanes
  **When** that shortcut would normally open a reply composer
  **Then** the shortcut does nothing in the Opposing-Views Lane and a brief toast explains "Replies are not available in the Opposing-Views Lane"

## Notes
The absence of reply controls is a core safety feature. Do not add an explanatory label permanently; use a toast only when the user actively attempts to reply.
