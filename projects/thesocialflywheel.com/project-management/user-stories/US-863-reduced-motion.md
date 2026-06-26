---
id: US-863
title: "Reduced Motion Mode"
slug: reduced-motion
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [reduced-motion, animation, wcag-2.2]
---

# US-863: Reduced Motion Mode

## User Story

**As a** user with vestibular sensitivity
**I want to** have the app respect my OS reduced-motion preference
**So that** swipe animations, transitions, and parallax effects do not trigger discomfort

## Acceptance Criteria

- **Given** my OS has prefers-reduced-motion: reduce set
  **When** I open the app
  **Then** all non-essential animations (card swipe, lane transitions, celebration bursts) are disabled or replaced with instant transitions

- **Given** I am in reduced-motion mode
  **When** a match celebration fires
  **Then** the confetti animation is suppressed and replaced with a static badge

- **Given** no OS preference is set
  **When** I visit Accessibility Settings
  **Then** I can manually enable reduced-motion mode and the preference persists across sessions

## Notes

Use CSS `@media (prefers-reduced-motion: reduce)` as the baseline; supplement with an in-app toggle stored in the user profile so users on shared devices or locked-down OS environments can still opt in.
