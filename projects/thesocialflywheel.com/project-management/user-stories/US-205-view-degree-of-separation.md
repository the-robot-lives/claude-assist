---
id: US-205
title: "View Degree of Separation"
slug: view-degree-of-separation
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [graph, degrees]
---

# US-205: View Degree of Separation

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see my degree of separation from any user I encounter
**So that** I can understand how closely we are connected and decide whether to send a mutual request

## Acceptance Criteria

- **Given** I view another user's profile
  **When** that user is within my 4th-degree web
  **Then** their profile prominently displays their degree (1st, 2nd, 3rd, or 4th) relative to me

- **Given** I view a user who is outside my 4th-degree web
  **When** no reachability path exists
  **Then** the profile shows "Outside your web" with no degree number

- **Given** degree information is loading
  **When** the profile renders
  **Then** a skeleton placeholder appears for the degree field until the value resolves (max 2 s)
