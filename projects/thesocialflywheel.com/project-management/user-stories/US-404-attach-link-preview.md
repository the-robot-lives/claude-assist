---
id: US-404
title: "Attach a link with rich preview"
slug: attach-link-preview
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [media, link, preview, og]
---

# US-404: Attach a Link with Rich Preview

## User Story

**As a** Creator
**I want to** paste a URL and see a rich Open Graph preview card
**So that** readers immediately understand what the link is about without clicking

## Acceptance Criteria

- **Given** I paste a URL into the composer
  **When** the app fetches the page's Open Graph metadata
  **Then** a preview card showing title, description, and thumbnail appears below the text

- **Given** a link preview card is shown
  **When** I choose to dismiss it
  **Then** the URL remains as plain text without the preview card

## Notes
Preview fetch should time out gracefully within 3 seconds; fall back to plain URL on failure.
