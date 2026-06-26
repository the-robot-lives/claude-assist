---
id: US-207
title: "Reachability Indicator on Profile"
slug: reachability-indicator-on-profile
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [graph, degrees, profile]
---

# US-207: Reachability Indicator on Profile

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see whether a user is reachable through my mutuals web before I decide to connect
**So that** I understand the potential content impact of adding them as a mutual

## Acceptance Criteria

- **Given** I view a user who is within my 2nd–4th degree web
  **When** their profile loads
  **Then** a reachability indicator shows "In your web" alongside the degree badge

- **Given** I view a user outside my 4th-degree web
  **When** their profile loads
  **Then** the indicator shows "Outside your web" and clarifies that adding them would expand my reachable content

## Notes
"In your web" conveys that their posts may already surface in my feed through shared interest filters at outer degrees.
