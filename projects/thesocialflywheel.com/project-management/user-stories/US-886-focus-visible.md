---
id: US-886
title: "Visible Focus Indicator on All Interactive Elements"
slug: focus-visible
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [focus-visible, keyboard, wcag-2.2]
---

# US-886: Visible Focus Indicator on All Interactive Elements

## User Story

**As a** keyboard or switch-access user
**I want to** see a clearly visible focus ring on every interactive element
**So that** I always know where keyboard focus is located on the screen

## Acceptance Criteria

- **Given** any interactive element (button, link, input, tab, card)
  **When** it receives keyboard focus
  **Then** a focus ring of at least 2px solid with 3:1 contrast ratio against the adjacent color appears around it

- **Given** the focus indicator is visible
  **When** I measure the focused area
  **Then** it encloses at least the full component bounding box per WCAG 2.4.11 Focus Appearance

- **Given** a custom component suppresses `:focus-visible`
  **When** a keyboard user focuses it
  **Then** an equivalent custom indicator is rendered via CSS or JavaScript — `outline: none` without replacement is never acceptable

## Notes
Include focus-indicator enforcement in the design system component library so all consuming components inherit correct behavior without per-component overrides.
