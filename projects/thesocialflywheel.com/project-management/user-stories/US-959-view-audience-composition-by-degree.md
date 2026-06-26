---
id: US-959
title: "View Audience Composition by Degree"
slug: view-audience-composition-by-degree
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: low
tags: [analytics, audience, degrees, privacy]
---

# US-959: View Audience Composition by Degree

## User Story

**As a** Creator
**I want to** see what percentage of my engaged audience is at each mutual degree
**So that** I understand whether my reach is concentrated in close connections or spreading outward.

## Acceptance Criteria

- **Given** an account with sufficient engagement data
  **When** I view degree composition
  **Then** I see percentage bars for 1st, 2nd, 3rd, and 4th degree engagement share.

- **Given** engagement data meeting the 50-account minimum
  **When** viewing degree composition
  **Then** raw counts are not shown — only percentages — to protect individual privacy.

## Notes
Degree is determined at the time of each engagement event. Only aggregate percentages are surfaced.
