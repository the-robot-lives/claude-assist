---
id: US-946
title: "Critical CSS Inlining for Above-the-Fold Render"
slug: critical-css-inlining
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [critical-css, first-paint, render-blocking, performance]
---

# US-946: Critical CSS Inlining for Above-the-Fold Render

## User Story

**As a** skeptical switcher on a slow connection
**I want to** see the above-the-fold feed content styled correctly before external CSS files finish loading
**So that** the page does not flash unstyled content or remain blank while stylesheets download

## Acceptance Criteria

- **Given** I open the app on a slow connection where external CSS has not yet loaded
  **When** the HTML arrives
  **Then** the above-the-fold layout renders with correct styles because critical CSS is inlined in `<style>` in the `<head>`

- **Given** the full CSS bundle loads after the critical inline styles
  **When** non-critical styles are applied
  **Then** no visible re-layout or flash of unstyled content occurs

## Notes
Extract critical CSS at build time using a tool like Critters or penthouse. Total inlined critical CSS budget: < 14 KB uncompressed. Load full CSS asynchronously with `media="print" onload` swap pattern.
