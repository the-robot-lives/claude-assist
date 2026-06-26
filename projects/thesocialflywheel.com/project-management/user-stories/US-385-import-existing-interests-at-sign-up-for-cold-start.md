---
id: US-385
title: "Import Existing Interests at Sign-Up for Cold Start"
slug: import-existing-interests-at-sign-up-for-cold-start
personas: [P-001]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, cold-start, onboarding]
---

# US-385: Import Existing Interests at Sign-Up for Cold Start

## User Story

**As a** Bridge-Builder
**I want to** import my interest data from another social platform during sign-up
**So that** the discovery engine has a richer seed profile and I skip the sparse cold-start experience

## Acceptance Criteria

- **Given** I am on the onboarding interest step
  **When** I choose "Import from another platform"
  **Then** I am shown a list of supported platforms and can authorize import via OAuth

- **Given** an import is completed successfully
  **When** I arrive at my feed
  **Then** discovery topics are drawn from the imported interest profile in addition to any manual quiz selections

## Notes
Imported interests should be presented for review before being applied; the user must confirm or deselect any imported interests. Only topic-level data (not social graph) is imported.
