---
id: US-870
title: "Alt Text Required on Image Posts"
slug: alt-text-required
personas: [P-008, P-009]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [alt-text, images, wcag-2.2]
---

# US-870: Alt Text Required on Image Posts

## User Story

**As a** screen-reader user
**I want to** every image posted to channels to have meaningful alt text
**So that** I am not excluded from image-based content

## Acceptance Criteria

- **Given** a creator uploads an image
  **When** they try to publish without alt text
  **Then** the form shows an inline error "Add a description for screen reader users" and blocks submission

- **Given** alt text is provided
  **When** the image is rendered in feed
  **Then** the `img` element has an `alt` attribute matching the creator-supplied text

- **Given** the image is purely decorative (e.g., a background pattern)
  **When** the creator marks it decorative
  **Then** the `img` has `alt=""` and `role="presentation"`

## Notes
The decorative-image checkbox must be visually distinct and accompanied by a short explanation to ensure creators understand when its use is appropriate; consider a tooltip or link to the platform's image accessibility guide.
