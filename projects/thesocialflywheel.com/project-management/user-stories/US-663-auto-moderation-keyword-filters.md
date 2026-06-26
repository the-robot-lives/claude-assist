---
id: US-663
title: "Auto-Moderation Keyword Filters"
slug: auto-moderation-keyword-filters
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [auto-moderation, filters]
---

# US-663: Auto-Moderation Keyword Filters

## User Story

**As a** channel moderator
**I want to** define a list of blocked keywords and phrases for my channel
**So that** posts containing those terms are held for review before appearing to other members

## Acceptance Criteria

- **Given** I add a keyword or phrase to the channel blocklist
  **When** a member submits a post containing that term (case-insensitive)
  **Then** the post is withheld from the channel feed and placed in the mod queue with reason "Keyword filter match: [term]"

- **Given** a post is held by a keyword filter
  **When** I review and approve it
  **Then** it is published retroactively with its original timestamp

- **Given** a keyword filter is active
  **When** the matched post author views their own post
  **Then** they see it as "Pending review" rather than published, so they know it was held

## Notes
Wildcards (e.g. "slur*") should be supported; whole-word matching should be the default to reduce false positives.
