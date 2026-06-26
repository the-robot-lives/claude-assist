---
id: US-937
title: "Optimized Web Font Loading to Prevent FOIT"
slug: font-loading-optimization
personas: [P-008]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: low
tags: [fonts, foit, fout, performance, accessibility]
---

# US-937: Optimized Web Font Loading to Prevent FOIT

## User Story

**As an** accessibility-first user who depends on readable text from the moment the page loads
**I want to** see system fallback text immediately instead of invisible text while custom fonts download
**So that** I can read content right away regardless of font load time

## Acceptance Criteria

- **Given** the page is loading and the custom font has not yet downloaded
  **When** text content is rendered
  **Then** system fallback fonts are used immediately (`font-display: swap`) so no text is invisible

- **Given** the custom font finishes downloading
  **When** it replaces the fallback
  **Then** the layout shift contributes less than 0.05 to CLS (achieved via `size-adjust` and `ascent-override` descriptors)

## Notes
Self-host font files to avoid third-party DNS lookups. Preload the primary weight/style with `<link rel="preload" as="font">`. Subset fonts to only characters needed for supported languages.
