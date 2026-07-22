---
id: US-055
title: "Telemetry Is Opt-In and Clearly Disclosed"
slug: telemetry-is-opt-in-and-clearly-disclosed
personas: [P-008, P-007]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [privacy, telemetry, consent, trust]
---

# US-055: Telemetry Is Opt-In and Clearly Disclosed

## User Story

**As a** privacy-first consultant who works fully offline
**I want to** have any telemetry or data collection be strictly opt-in and clearly disclosed
**So that** I can trust the tool never phones home without my explicit, informed consent

## Acceptance Criteria

- **Given** I complete a fresh install and `/setup`
  **When** onboarding finishes
  **Then** telemetry is off by default and no data collection has occurred without my action.

- **Given** I want to understand what telemetry would collect
  **When** I view the telemetry disclosure
  **Then** it plainly lists what data would be sent, where, and why, in non-legalese language.

- **Given** I decide to opt in
  **When** I enable telemetry
  **Then** the setting change is explicit, logged, and reversible at any time.

- **Given** I never opt in
  **When** I use robot-learns fully offline
  **Then** no network calls related to telemetry are made, verifiable by inspection of local configuration.

## Notes
Priority set to must-have, deviating from this epic's general should-have/could-have guidance — an opt-in, disclosed-by-default telemetry posture is treated as a trust baseline rather than an optional enhancement, given the offline/privacy-first personas this product targets.
