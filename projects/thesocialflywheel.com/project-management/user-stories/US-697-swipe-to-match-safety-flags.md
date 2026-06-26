---
id: US-697
title: "Swipe-to-Match Safety Flags"
slug: swipe-to-match-safety-flags
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [safety, swipe-to-match, reporting]
---

# US-697: Swipe-to-Match Safety Flags

## User Story

**As a** cautious newcomer using the Swipe-to-Match lane
**I want to** flag a suggested profile for inappropriate content before or after matching
**So that** I am protected from harmful accounts and the platform can remove them before they reach others

## Acceptance Criteria

- **Given** I am viewing a suggested profile card in the Swipe-to-Match lane
  **When** I tap the flag icon on the card
  **Then** a reason sheet appears (Explicit content, Impersonation, Spam/bot, Threatening language, Other) and I can submit without completing the swipe decision

- **Given** I flag a profile
  **When** the flag is submitted
  **Then** the profile is immediately hidden from my Swipe-to-Match feed and queued for platform T&S review, and I receive a confirmation notification

- **Given** I have already matched with someone and then flag them
  **When** I submit the flag
  **Then** the match is automatically unmatched, the conversation thread is preserved as evidence for the T&S review, and the flagged user is not notified of the flag or the unmatch reason

## Notes
Safety flags in Swipe-to-Match route to platform T&S (not channel mods) because this lane is platform-managed, not channel-managed.
