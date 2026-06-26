---
id: US-888
title: "Programmatically Associated Form Labels"
slug: form-labels
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [form-labels, screen-reader, wcag-2.2]
---

# US-888: Programmatically Associated Form Labels

## User Story

**As a** screen-reader user
**I want to** every form input to have a programmatically associated label
**So that** I know what information is expected in each field without guessing

## Acceptance Criteria

- **Given** any form (registration, post composer, settings)
  **When** a screen reader focuses an input
  **Then** it reads the associated label before the field role and type (e.g., "Email, text field")

- **Given** a placeholder is the only visible label text
  **When** focus enters the field and the placeholder disappears
  **Then** `aria-label` or `aria-labelledby` still provides the field name to the screen reader

- **Given** a group of radio buttons or checkboxes
  **When** screen reader focus enters the group
  **Then** a `fieldset` with a `legend` announces the group question first, then each option label

## Notes
Placeholders alone are not accessible labels and fail WCAG 1.3.1. Every input must have either a visible `<label>` element associated via `for`/`id` or an `aria-label` / `aria-labelledby` attribute.
