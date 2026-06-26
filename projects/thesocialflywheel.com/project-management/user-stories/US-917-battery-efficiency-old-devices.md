---
id: US-917
title: "Battery-Efficient Background Polling on Old Devices"
slug: battery-efficiency-old-devices
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [battery, polling, background, old-devices, mobile]
---

# US-917: Battery-Efficient Background Polling on Old Devices

## User Story

**As a** skeptical switcher using a 4-year-old smartphone with a degraded battery
**I want to** have the app respect battery-saving modes and avoid draining my battery in the background
**So that** I don't uninstall the app because it kills my battery

## Acceptance Criteria

- **Given** my device reports battery level below 20% or Low Power Mode is active
  **When** the app is in the background
  **Then** all polling intervals are increased to at least 5-minute intervals and WebSocket pings are suppressed

- **Given** the app is in the foreground on any battery level
  **When** the user is idle for 10 minutes
  **Then** push connections remain open but feed-refresh polling pauses until user interaction resumes

## Notes
Detect Low Power Mode via `navigator.getBattery()`. Use Page Visibility API to pause work on hidden tab. Resume normal polling when the user returns to the foreground.
