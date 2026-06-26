---
id: US-984
title: "Enforce Minimum Cohort Size on Audience Data"
slug: enforce-minimum-cohort-size-on-audience-data
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [privacy, analytics, audience, cohort]
---

# US-984: Enforce Minimum Cohort Size on Audience Data

## User Story

**As a** Creator
**I want to** the platform to clearly communicate when audience data is suppressed due to cohort-size privacy thresholds
**So that** I understand why certain breakdowns are unavailable rather than assuming a bug.

## Acceptance Criteria

- **Given** an audience breakdown where a segment has fewer than 50 accounts
  **When** that segment would normally be shown
  **Then** it is replaced with "Insufficient data (privacy protected)" messaging explaining the minimum cohort rule.

- **Given** a creator viewing suppressed data
  **When** they hover the info icon next to the suppression message
  **Then** a tooltip explains the 50-account minimum policy and links to the privacy documentation.

## Notes
The 50-account threshold applies per-segment, not per-total-audience. A creator with 1000 engaged accounts may still see suppression on narrow sub-segments.
