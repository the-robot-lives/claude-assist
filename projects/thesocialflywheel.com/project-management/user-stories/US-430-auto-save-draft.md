---
id: US-430
title: "Auto-save draft while composing"
slug: auto-save-draft-while-composing
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [drafts, auto-save, resilience, compose]
---

# US-430: Auto-Save Draft While Composing

## User Story

**As a** Creator
**I want to** have my post automatically saved to drafts as I type
**So that** I never lose my work if I navigate away or the device runs out of battery

## Acceptance Criteria

- **Given** I am actively composing a post
  **When** 10 seconds pass without user action
  **Then** the current composer state is silently saved as a draft

- **Given** I navigate away from the composer without explicitly saving or publishing
  **When** I return to the app
  **Then** the composer reopens with my last auto-saved content

## Notes
Auto-save indicator ("Saved") should flash briefly in the composer toolbar to confirm the save.
