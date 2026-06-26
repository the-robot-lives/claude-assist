---
id: US-536
title: "Emoji Reaction Skin-Tone Picker"
slug: emoji-reaction-skin-tone-picker
personas: [P-008]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: medium
tags: [reactions, emoji, accessibility, inclusion]
---

# US-536: Emoji Reaction Skin-Tone Picker

## User Story

**As an** Accessibility-First user (P-008)
**I want to** choose a skin-tone modifier when reacting with a hand or person emoji
**So that** my reactions represent my identity and everyone feels included

## Acceptance Criteria

- **Given** I open the emoji reaction picker and hover or long-press a skin-tone-eligible emoji
  **When** the skin-tone variants appear in a small pop-up grid (6 options)
  **Then** I can select any variant and it is saved as my default for that emoji

- **Given** I have previously selected a skin tone for an emoji
  **When** I tap the quick-react tray
  **Then** my saved skin-tone variant appears by default for that emoji without having to re-select

- **Given** I navigate the skin-tone picker using a screen reader
  **When** I focus each swatch
  **Then** the accessibility label reads the emoji name plus the Fitzpatrick scale description (e.g., "Thumbs up: medium skin tone")

## Notes
Default skin tone is Fitzpatrick Type 1-2 (yellow) unless the user sets a preference in Profile settings.
