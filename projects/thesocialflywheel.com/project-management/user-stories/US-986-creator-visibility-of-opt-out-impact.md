---
id: US-986
title: "Creator Visibility of Opt-Out Impact"
slug: creator-visibility-of-opt-out-impact
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: low
tags: [analytics, privacy, opt-out, transparency]
---

# US-986: Creator Visibility of Opt-Out Impact

## User Story

**As a** Creator
**I want to** see an approximate percentage of my audience that has opted out of analytics collection
**So that** I understand how representative my analytics data is and can make informed decisions with appropriate uncertainty.

## Acceptance Criteria

- **Given** the analytics dashboard
  **When** I view any audience breakdown section
  **Then** a banner shows an approximate opt-out rate (e.g., "~12% of your audience has opted out of behavioral analytics").

- **Given** the opt-out rate banner
  **When** I click "Learn more"
  **Then** a help article explains what data is and is not collected for opted-out users.

## Notes
The opt-out rate shown is rounded to the nearest 5% to avoid allowing creators to infer individual opt-out status from precise counts.
