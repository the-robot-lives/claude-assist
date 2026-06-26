---
id: US-440
title: "Preview bold, italic, and code markdown before posting"
slug: bold-italic-code-preview
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [markdown, preview, formatting, rich-text]
---

# US-440: Preview Bold, Italic, and Code Markdown Before Posting

## User Story

**As a** Creator
**I want to** see a live preview of rendered markdown formatting while I compose
**So that** I can verify the visual output before committing to publish

## Acceptance Criteria

- **Given** I type markdown in the composer
  **When** I tap the "Preview" toggle
  **Then** the composer switches to a read-only rendered view with all formatting applied

- **Given** I am in Preview mode
  **When** I tap "Edit"
  **Then** the raw markdown is restored and I can continue editing

## Notes
Preview and Edit modes are toggled inline; no page navigation required. Extends US-422.
