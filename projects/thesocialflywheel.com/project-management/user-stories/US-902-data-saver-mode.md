---
id: US-902
title: "Data-Saver Mode Reduces Media Usage"
slug: data-saver-mode
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [data-saver, bandwidth, media, settings]
---

# US-902: Data-Saver Mode Reduces Media Usage

## User Story

**As a** skeptical switcher on a limited mobile data plan
**I want to** enable a data-saver mode that suppresses auto-playing video and loads lower-resolution images
**So that** I can use Flywheel Social without burning through my monthly data allowance

## Acceptance Criteria

- **Given** I have enabled Data Saver in app settings
  **When** I scroll through any feed lane
  **Then** videos do not auto-play and images load at ≤ 50% of their full resolution

- **Given** Data Saver is active
  **When** I tap a media thumbnail
  **Then** the full-resolution asset loads on demand with a visible progress indicator

## Notes
Respect the OS-level `Save-Data` HTTP header as the default-on trigger; let users override in settings.
