---
id: US-798
title: "Enable Data Saver Mode"
slug: enable-data-saver-mode
personas: [P-004]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [data-saver, bandwidth, performance, mobile]
---

# US-798: Enable Data Saver Mode

## User Story

**As a** cautious newcomer on a limited data plan
**I want to** enable a data saver mode
**So that** the app uses significantly less mobile data without sacrificing core functionality

## Acceptance Criteria

- **Given** I open Settings > Data & Performance
  **When** I enable "Data Saver"
  **Then** images are served at reduced resolution (max 480 px wide), video autoplays are disabled, and link previews load only on tap.

- **Given** Data Saver is enabled
  **When** I view the top of the feed
  **Then** a persistent banner confirms "Data Saver is ON" so I know the mode is active.

## Notes
