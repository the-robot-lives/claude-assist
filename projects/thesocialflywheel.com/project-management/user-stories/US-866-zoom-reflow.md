---
id: US-866
title: "Content Reflow at 400% Zoom"
slug: zoom-reflow
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: high
tags: [zoom, reflow, responsive, wcag-2.2]
---

# US-866: Content Reflow at 400% Zoom

## User Story

**As a** low-vision user
**I want to** have the layout reflow into a single column at 400% browser zoom
**So that** I can read all content without horizontal scrolling

## Acceptance Criteria

- **Given** I zoom the browser to 400%
  **When** I view the feed
  **Then** all content fits within the viewport width without requiring horizontal scroll

- **Given** I zoom to 400% on the channel sidebar
  **When** the sidebar is open
  **Then** it overlays or shifts to a drawer without clipping text

- **Given** I zoom to 400% in chat
  **When** I send a message
  **Then** the input field and send button remain fully visible and usable

## Notes

Use CSS logical properties and responsive units (rem/%). Avoid fixed-pixel widths on containers. Test at 1280px viewport width at 400% zoom (equivalent to 320px CSS width) per WCAG 1.4.10 Reflow.
