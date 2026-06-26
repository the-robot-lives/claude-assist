---
id: US-754
title: "Set Post Visibility by Degree"
slug: set-post-visibility-by-degree
personas: [P-004]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [privacy, visibility, degrees, posts]
---

# US-754: Set Post Visibility by Degree

## User Story

**As a** cautious newcomer
**I want to** set which connection degrees (1st–4th or public) can see my posts by default
**So that** I control who reads my content before I expand my network.

## Acceptance Criteria

- **Given** I open Privacy Settings
  **When** I select "2nd-degree mutuals and closer" from the post visibility dropdown
  **Then** all future posts default to that audience unless I override per post.

- **Given** I have changed my default visibility
  **When** I view existing posts
  **Then** their visibility is unchanged and I see a note that changes apply to new posts only.

## Notes
Per-post overrides allow creators to publish publicly on select posts while keeping their default audience narrow.
