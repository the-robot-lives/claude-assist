---
id: US-436
title: "Remove an interest tag before publishing"
slug: remove-interest-tag
personas: [P-002]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [interests, tagging, edit, compose]
---

# US-436: Remove an Interest Tag Before Publishing

## User Story

**As a** Niche Enthusiast
**I want to** remove an interest tag I've added to my post before I publish
**So that** I can adjust my post's reach if I accidentally tagged the wrong channel

## Acceptance Criteria

- **Given** I have added one or more interest tags in the composer
  **When** I tap the X on any tag chip
  **Then** that tag is removed from the post immediately

- **Given** all tags have been removed
  **When** I publish the post
  **Then** the post propagates only to direct mutuals (no interest-filtered outer-degree distribution)

## Notes
Removing all tags does not prevent publication; it just limits distribution to direct mutuals.
