---
id: US-428
title: "Preview post as a specific-degree connection sees it"
slug: preview-post-as-specific-degree
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: high
tags: [preview, degrees, audience, visibility]
---

# US-428: Preview Post as a Specific-Degree Connection Sees It

## User Story

**As a** Creator
**I want to** preview exactly which parts of my post a 2nd or 3rd-degree user would see
**So that** I can verify that interest-filtered propagation works as intended before publishing

## Acceptance Criteria

- **Given** I have composed a post with tags and a degree setting
  **When** I tap "Preview as 2nd Degree"
  **Then** I see a read-only simulation of how the post appears to an interest-matched 2nd-degree user

- **Given** I switch the preview to "3rd Degree"
  **When** the preview renders
  **Then** any content or metadata restricted to closer degrees is visually redacted

## Notes
Preview mode is illustrative; actual recipients depend on live graph state at publish time.
