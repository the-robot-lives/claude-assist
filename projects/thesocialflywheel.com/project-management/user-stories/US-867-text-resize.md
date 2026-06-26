---
id: US-867
title: "Text Resize Without Content Overflow"
slug: text-resize
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [resizable-text, zoom, wcag-2.2]
---

# US-867: Text Resize Without Content Overflow

## User Story

**As a** low-vision user
**I want to** increase text size up to 200% via browser or OS settings without text being clipped or overlapping other elements
**So that** I can comfortably read all content

## Acceptance Criteria

- **Given** I set the browser default font size to 32px (200%)
  **When** I load any page
  **Then** no text is truncated with an ellipsis in a way that hides meaning

- **Given** large text mode is active
  **When** I view post cards
  **Then** card height expands to accommodate text rather than clipping it

- **Given** I increase text size
  **When** interactive elements resize
  **Then** touch/click targets remain at least 44×44 CSS pixels

## Notes

Avoid `overflow: hidden` on fixed-height card containers; use `min-height` instead. Ensure icon-only buttons include a text label that scales with font size, even if visually hidden, to maintain adequate target size.
