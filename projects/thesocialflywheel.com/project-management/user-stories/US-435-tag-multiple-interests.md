---
id: US-435
title: "Add multiple interest tags to a single post"
slug: tag-multiple-interests
personas: [P-002]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [interests, tagging, multi-tag, reach]
---

# US-435: Add Multiple Interest Tags to a Single Post

## User Story

**As a** Niche Enthusiast
**I want to** attach multiple interest tags to one post
**So that** my content reaches different communities that are all relevant to what I'm sharing

## Acceptance Criteria

- **Given** I am composing a post
  **When** I add up to five interest tags via the tag picker
  **Then** all selected tags appear as chips in the composer before I publish

- **Given** a post with multiple tags is published
  **When** the propagation engine runs
  **Then** the post is eligible to reach outer-degree users who follow any of the listed interests

## Notes
Tags are OR-combined for reach (any match qualifies); see US-405 for tag-based routing details.
