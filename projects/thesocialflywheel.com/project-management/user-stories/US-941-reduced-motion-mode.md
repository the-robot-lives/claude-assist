---
id: US-941
title: "Reduced-Motion Mode for Animations"
slug: reduced-motion-mode
personas: [P-008]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [accessibility, reduced-motion, animation, performance]
---

# US-941: Reduced-Motion Mode for Animations

## User Story

**As an** accessibility-first user who experiences motion sickness from animations
**I want to** have all non-essential animations and transitions suppressed when I enable reduced motion
**So that** I can use the app comfortably without triggering vestibular symptoms

## Acceptance Criteria

- **Given** my OS or browser has `prefers-reduced-motion: reduce` set
  **When** I use any part of the app
  **Then** all CSS transitions, keyframe animations, and JS-driven motion effects are disabled or replaced with instant state changes

- **Given** reduced motion is active
  **When** skeleton loading screens are shown
  **Then** the pulsing skeleton animation is replaced by a static placeholder

## Notes
Use `@media (prefers-reduced-motion: reduce)` in CSS. Check the preference in JS before starting any animation library (GSAP, Framer Motion). This also reduces main-thread jank on low-end devices.
