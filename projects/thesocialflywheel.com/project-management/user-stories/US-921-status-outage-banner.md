---
id: US-921
title: "Status and Outage Banner for Known Incidents"
slug: status-outage-banner
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [status, outage, incident, banner, communication]
---

# US-921: Status and Outage Banner for Known Incidents

## User Story

**As a** skeptical switcher who experiences frequent app errors during an outage
**I want to** see a clear status banner explaining that the platform is having issues
**So that** I don't assume the problem is on my end and don't lose trust in the app

## Acceptance Criteria

- **Given** the platform engineering team has flagged an active incident
  **When** I open the app during the incident window
  **Then** a dismissible status banner appears at the top of every screen with a one-sentence plain-language description

- **Given** the incident is resolved
  **When** I open the app after resolution
  **Then** the banner is no longer shown and a brief "All systems operational" toast is displayed once

## Notes
Pull incident status from a lightweight status endpoint (not the main API, so it works during partial outages). Fallback to cached status if the status endpoint itself is down.
