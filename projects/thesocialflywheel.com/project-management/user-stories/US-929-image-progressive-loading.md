---
id: US-929
title: "Progressive JPEG and Blur-Up Image Loading"
slug: image-progressive-loading
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: low
tags: [images, progressive-jpeg, blur-up, perceived-performance]
---

# US-929: Progressive JPEG and Blur-Up Image Loading

## User Story

**As a** quiet consumer browsing an image-heavy channel
**I want to** see a blurred low-resolution preview of images while the full image loads
**So that** the page feels populated and I can assess content before full image download completes

## Acceptance Criteria

- **Given** I scroll to an image post that has not yet loaded
  **When** the image enters the viewport
  **Then** a tiny (< 1 KB) blurred placeholder is shown immediately, replaced by the full image on completion

- **Given** the full image has loaded
  **When** it replaces the blur placeholder
  **Then** the transition uses a CSS opacity fade (200 ms) with no layout shift

## Notes
Generate blur-up thumbnails (16×16 px, base64 inline) at upload time. Store alongside original asset in CDN. Use `loading="lazy"` on `<img>` elements below the fold.
