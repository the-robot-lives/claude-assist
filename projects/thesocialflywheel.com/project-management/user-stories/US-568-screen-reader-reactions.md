---
id: US-568
title: "Use Reactions with a Screen Reader"
slug: screen-reader-reactions
personas: [P-008]
epic: "Reactions & Engagement"
priority: must-have
complexity: medium
tags: [accessibility, screen-reader, reactions]
---

# US-568: Use Reactions with a Screen Reader

## User Story

**As an** Accessibility-First user
**I want to** have screen-reader announcements for reaction actions
**So that** I can engage with content independently without visual confirmation

## Acceptance Criteria

- **Given** a post displays reactions
  **When** my screen reader focuses on the reaction summary
  **Then** it reads "3 reactions: 2 thumbs up, 1 heart. Tap to see who reacted."

- **Given** I select an emoji from the picker
  **Then** my screen reader announces "[Emoji name] reaction added" as a live region update

## Notes
Use aria-live regions for count updates triggered by reactions. All emoji must have descriptive aria-label values. Test on VoiceOver (iOS/macOS) and TalkBack (Android).
