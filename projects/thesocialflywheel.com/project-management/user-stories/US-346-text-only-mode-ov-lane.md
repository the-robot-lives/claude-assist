---
id: US-346
title: "Text-Only Mode for Opposing-View Lane"
slug: text-only-mode-ov-lane
personas: [P-008]
epic: "Opposing-Views Lane"
priority: could-have
complexity: medium
tags: [opposing-views, accessibility, text-only, a11y, cognitive]
---

# US-346: Text-Only Mode for Opposing-View Lane

## User Story

**As an** accessibility-first user
**I want to** view the Opposing-Views Lane in a text-only mode that hides images, videos, and other media
**So that** I can focus on the written argument without being distracted or overwhelmed by visual content

## Acceptance Criteria

- **Given** I enable text-only mode in accessibility settings
  **When** opposing-view posts render
  **Then** all embedded images and videos are replaced with descriptive alt text or a "[Media hidden]" placeholder

- **Given** text-only mode is active
  **When** I disable it
  **Then** media content reappears on the next render without requiring a full page reload

## Notes
Text-only mode should apply across the whole app when enabled, not just the Opposing-Views Lane. This story focuses on ensuring the lane respects that global setting.
