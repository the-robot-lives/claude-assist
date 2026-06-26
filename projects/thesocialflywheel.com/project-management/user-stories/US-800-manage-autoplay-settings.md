---
id: US-800
title: "Manage Autoplay Settings"
slug: manage-autoplay-settings
personas: [P-008]
epic: "Settings & Preferences"
priority: could-have
complexity: low
tags: [accessibility, autoplay, media, data-saver]
---

# US-800: Manage Autoplay Settings

## User Story

**As an** accessibility-first user
**I want to** have granular control over video autoplay
**So that** videos do not start unexpectedly and cause sensory overload or waste data

## Acceptance Criteria

- **Given** I open Settings > Data & Performance > Autoplay
  **When** I select "Never autoplay"
  **Then** all inline videos display a static thumbnail and require a tap to play on any connection type.

- **Given** I select "Autoplay on Wi-Fi only"
  **When** I switch from cellular to Wi-Fi
  **Then** videos begin autoplaying without a page reload.

## Notes
