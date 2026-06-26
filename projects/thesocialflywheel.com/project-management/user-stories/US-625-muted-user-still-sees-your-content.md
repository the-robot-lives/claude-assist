---
id: US-625
title: "Muted User Still Sees Your Content"
slug: muted-user-still-sees-your-content
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: low
tags: [safety, mute]
---

# US-625: Muted User Still Sees Your Content

## User Story

**As a** bridge-builder
**I want to** know that muting someone is one-directional
**So that** the muted user's experience is unaffected and they can still engage with my content normally

## Acceptance Criteria

- **Given** I have muted User Y
  **When** User Y opens Discovery
  **Then** my posts appear for them as normal

- **Given** User Y comments on one of my posts
  **When** I view that post
  **Then** User Y's comment is hidden from my view but visible to all other readers

## Notes
This asymmetry is what distinguishes mute from block; block is surfaced together in US-626.
