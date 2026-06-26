---
id: US-875
title: "RTL Chat Bubble Alignment"
slug: rtl-chat
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [rtl, chat, i18n, wcag-2.2]
---

# US-875: RTL Chat Bubble Alignment

## User Story

**As an** RTL-language user
**I want to** have chat message bubbles align correctly
**So that** my sent messages appear on the right and received messages on the left within an RTL context

## Acceptance Criteria

- **Given** RTL mode is active
  **When** I send a chat message
  **Then** my bubble aligns to the `inline-start` (right in RTL) side of the thread

- **Given** RTL mode is active
  **When** I receive a message
  **Then** the sender's bubble aligns to the `inline-end` (left in RTL) side

- **Given** a message contains a mix of LTR and RTL text (bidirectional)
  **When** rendered
  **Then** the Unicode bidi algorithm is applied and text direction is visually correct

## Notes
Set `dir="auto"` on individual message bubble elements to allow per-message bidi resolution; this ensures mixed-language conversations render correctly regardless of the account's global locale setting.
