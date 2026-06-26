---
id: US-901
title: "Fast First Load Under 2.5 Seconds LCP"
slug: fast-first-load-lcp
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: high
tags: [lcp, first-load, core-web-vitals, performance]
---

# US-901: Fast First Load Under 2.5 Seconds LCP

## User Story

**As a** skeptical switcher evaluating Flywheel Social for the first time
**I want to** see the main feed content within 2.5 seconds on a mid-range device
**So that** I don't abandon the app before giving it a chance

## Acceptance Criteria

- **Given** I open the app on a mid-range Android device on a 4G connection
  **When** the page begins loading
  **Then** the Largest Contentful Paint occurs within 2.5 seconds as measured by field data

- **Given** a slow 3G connection (< 1 Mbps)
  **When** the page loads
  **Then** a meaningful skeleton or placeholder appears within 1.5 seconds so the screen is not blank

## Notes
Measure via Chrome UX Report and RUM. Prioritize critical-path HTML/CSS inlining and hero-content preloading.
