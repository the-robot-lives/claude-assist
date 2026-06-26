---
id: US-416
title: "Add alt text to an attached image"
slug: add-alt-text-image
personas: [P-008]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [accessibility, alt-text, image, a11y]
---

# US-416: Add Alt Text to an Attached Image

## User Story

**As an** Accessibility-First user
**I want to** add descriptive alt text to every image I attach to a post
**So that** screen-reader users and those who cannot load images understand the visual content

## Acceptance Criteria

- **Given** I have attached an image in the composer
  **When** I tap the "Add alt text" button on the image thumbnail
  **Then** a text field opens allowing me to enter a description up to 500 characters

- **Given** alt text has been entered
  **When** the post is published
  **Then** the alt text is rendered as the image's accessible name in all clients

## Notes
A prompt nudges users who publish images without alt text; it is a soft warning, not a blocker.
