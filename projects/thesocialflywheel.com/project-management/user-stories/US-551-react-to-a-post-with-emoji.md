---
id: US-551
title: "React to a Post with Emoji"
slug: react-to-a-post-with-emoji
personas: [P-006]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [reactions, emoji, engagement]
---

# US-551: React to a Post with Emoji

## User Story

**As a** Quiet Consumer
**I want to** react to a post with an emoji
**So that** I can express my feelings without writing a reply

## Acceptance Criteria

- **Given** I am viewing a post from a 1st-degree mutual
  **When** I tap the reaction button
  **Then** an emoji picker appears with the platform's defined reaction set

- **Given** the picker is open
  **When** I select an emoji
  **Then** my reaction is saved and the count increments on the post immediately

## Notes
Reaction set is platform-defined (not freeform unicode); see design spec for the initial emoji roster.
