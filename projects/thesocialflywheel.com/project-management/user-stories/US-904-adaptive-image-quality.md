---
id: US-904
title: "Adaptive Image Quality Based on Connection Speed"
slug: adaptive-image-quality
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [images, adaptive, connection, srcset, webp]
---

# US-904: Adaptive Image Quality Based on Connection Speed

## User Story

**As a** skeptical switcher on an unreliable mobile connection
**I want to** receive appropriately compressed images sized for my current network conditions
**So that** images load quickly without looking broken or pixelated on my screen

## Acceptance Criteria

- **Given** the Network Information API reports `effectiveType` of "2g" or "slow-2g"
  **When** profile photos and post images are requested
  **Then** the server delivers WebP images at ≤ 480px width

- **Given** a fast connection (4G or WiFi)
  **When** images are requested
  **Then** full-resolution WebP/AVIF assets are served with appropriate `srcset` breakpoints

## Notes
Use a CDN image transformation service. Emit `<img srcset>` and let the browser pick; fall back to server-side hint via Client-Hints headers.
