---
id: US-958
title: "View Audience Composition by Interest"
slug: view-audience-composition-by-interest
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [analytics, audience, interests, privacy]
---

# US-958: View Audience Composition by Interest

## User Story

**As a** Creator
**I want to** see which interest channels my engaged audience comes from in aggregate
**So that** I can understand my audience without compromising individual privacy.

## Acceptance Criteria

- **Given** an account with at least 50 engaged unique accounts in the past 30 days
  **When** I open Audience Composition
  **Then** I see a ranked list of interest channels with percentage of engaged audience per channel.

- **Given** fewer than 50 engaged unique accounts
  **When** I open Audience Composition
  **Then** a message explains insufficient data to display without compromising privacy.

## Notes
Data is aggregate only; no individual account is identifiable. Minimum cohort size of 50 is enforced before any breakdown is shown.
