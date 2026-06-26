---
id: US-210
title: "Mutuals in Common List"
slug: mutuals-in-common-list
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [graph, social-proof]
---

# US-210: Mutuals in Common List

## User Story

**As a** Social Connector (P-003)
**I want to** expand the "X mutuals in common" count to see who those mutual connections are
**So that** I can decide whether our shared network makes this person a good mutual for me

## Acceptance Criteria

- **Given** I see "X mutuals in common" on a profile
  **When** I tap the count
  **Then** a bottom sheet or modal lists up to 20 shared mutuals with avatars and names, sorted by degree proximity

- **Given** a shared mutual has a private account
  **When** the list renders
  **Then** they appear as "1 private account" rather than being listed by name or avatar
