---
id: US-445
title: "Discard a draft with confirmation prompt"
slug: discard-draft-confirmation
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [drafts, discard, ux, safety]
---

# US-445: Discard a Draft with Confirmation Prompt

## User Story

**As a** Creator
**I want to** be asked to confirm before my draft is discarded
**So that** I don't accidentally lose work by tapping the wrong button

## Acceptance Criteria

- **Given** I have unsaved content in the composer
  **When** I tap the Back or Close button
  **Then** a modal asks: "Discard changes?", with options "Discard" and "Keep editing" and "Save as Draft"

- **Given** I tap "Discard"
  **When** the modal closes
  **Then** the composer is dismissed and the content is permanently removed

## Notes
If the composer was opened from an existing draft, "Discard" reverts to the last saved draft state.
