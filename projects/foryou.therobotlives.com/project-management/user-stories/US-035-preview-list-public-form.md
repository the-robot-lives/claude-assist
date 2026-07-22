---
id: US-035
title: "Preview a List's public form"
slug: preview-list-public-form
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: low
tags: [list, form, preview, attributes]
---

# US-035: Preview a List's public form

## User Story

**As a** Service editor
**I want to** preview the public signup form generated from a List's attributes
**So that** I can confirm it before publishing

## Acceptance Criteria

- **Given** a List with declared attributes
  **When** I open its form preview
  **Then** I see each attribute rendered with the correct field type and required markers
- **Given** I change or reorder attributes
  **When** I refresh the preview
  **Then** the form updates accordingly
- **Given** the preview is shown
  **When** I attempt a test submission
  **Then** validation behaves as it will on the live form without creating a real signup

## Notes
Form is generated dynamically from attribute declarations (drives the widget, US-046).
