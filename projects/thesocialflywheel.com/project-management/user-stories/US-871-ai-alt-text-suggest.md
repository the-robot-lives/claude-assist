---
id: US-871
title: "AI-Assisted Alt Text Suggestion"
slug: ai-alt-text-suggest
personas: [P-009]
epic: "Accessibility & Internationalization"
priority: could-have
complexity: high
tags: [alt-text, ai, images, accessibility]
---

# US-871: AI-Assisted Alt Text Suggestion

## User Story

**As a** creator
**I want to** have the platform suggest alt text for my uploaded images using AI
**So that** I can provide accurate descriptions quickly without writing from scratch

## Acceptance Criteria

- **Given** I upload an image
  **When** the upload completes
  **Then** an AI-generated alt text suggestion appears pre-filled in the description field

- **Given** the AI suggestion is shown
  **When** I read it
  **Then** it is clearly labelled "AI suggestion — please review" and editable before posting

- **Given** the AI service is unavailable
  **When** I upload an image
  **Then** the field is blank and I see "Add a description for screen reader users" placeholder without error

## Notes
AI suggestions must never auto-publish; creator review is mandatory. The suggestion pipeline should run asynchronously after upload and update the form via a lightweight poll or WebSocket push to avoid blocking the upload flow.
