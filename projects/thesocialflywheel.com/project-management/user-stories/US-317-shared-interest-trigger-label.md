---
id: US-317
title: "Shared-Interest Trigger Label on Post"
slug: shared-interest-trigger-label
personas: [P-001]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, label, transparency, interests]
---

# US-317: Shared-Interest Trigger Label on Post

## User Story

**As a** bridge-builder
**I want to** see which specific shared interest caused a particular opposing-view post to appear
**So that** I can evaluate the relevance of the content and understand the system's reasoning

## Acceptance Criteria

- **Given** I view an opposing-view post
  **When** the post renders
  **Then** a label displays the exact interest name that matched, e.g. "Shown because you both follow: Urban Cycling"

## Notes
If multiple interests match, show the highest-confidence match. Do not list all matches to avoid label clutter.
