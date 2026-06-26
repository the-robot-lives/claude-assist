---
id: US-883
title: "Skip Links and ARIA Landmarks"
slug: skip-links
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [skip-links, landmarks, screen-reader, keyboard, wcag-2.2]
---

# US-883: Skip Links and ARIA Landmarks

## User Story

**As a** keyboard or screen-reader user
**I want to** use skip-navigation links and properly labelled ARIA landmarks
**So that** I can jump directly to main content without tabbing through the entire header on every page load

## Acceptance Criteria

- **Given** I press Tab immediately after page load
  **When** the first focusable element appears
  **Then** it is a "Skip to main content" link that, when activated, moves focus to the `main` landmark

- **Given** I navigate by landmarks in my screen reader
  **When** I query for landmark regions
  **Then** the page has exactly one `main`, one `nav` labelled "Primary navigation", one `complementary` for the sidebar, and additional regions labelled by their visible headings

- **Given** I use a mobile screen reader's rotor to list landmarks
  **When** I select "Main"
  **Then** focus jumps past the nav and sidebar directly to the feed content

## Notes
All landmark labels must use `aria-label` or `aria-labelledby` to distinguish multiple same-type regions (e.g., two `nav` elements on the same page). Skip links must be visible on focus, not permanently hidden.
