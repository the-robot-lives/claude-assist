---
id: US-925
title: "Progressive Web App Installability"
slug: pwa-installability
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [pwa, install, manifest, service-worker, home-screen]
---

# US-925: Progressive Web App Installability

## User Story

**As a** skeptical switcher who doesn't want to use storage on a native app
**I want to** install Flywheel Social as a PWA to my home screen
**So that** I get an app-like experience with faster loads without a large app download

## Acceptance Criteria

- **Given** I visit the Flywheel Social web app on a compatible browser
  **When** the app meets PWA criteria (HTTPS, manifest, service worker)
  **Then** the browser surfaces an "Add to Home Screen" prompt without me having to search for it

- **Given** I have installed the PWA
  **When** I launch it from my home screen
  **Then** the app opens in standalone display mode with no browser chrome and loads the feed from cache within 1 second

## Notes
Web App Manifest must include `display: standalone`, icon set (192px, 512px), `theme_color`, and `background_color`. Achieve Lighthouse PWA score ≥ 90.
