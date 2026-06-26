---
id: US-209
title: "Mutuals in Common Count"
slug: mutuals-in-common-count
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [graph, social-proof]
---

# US-209: Mutuals in Common Count

## User Story

**As a** Social Connector (P-003)
**I want to** see how many mutuals I share with another user on their profile
**So that** I can gauge social compatibility before deciding to send a mutual request

## Acceptance Criteria

- **Given** I view another user's profile
  **When** we share at least one 1st-degree mutual
  **Then** a line reads "X mutuals in common" beneath their name

- **Given** we share zero mutuals
  **When** their profile loads
  **Then** no "mutuals in common" line is shown (it is omitted, not shown as 0)
