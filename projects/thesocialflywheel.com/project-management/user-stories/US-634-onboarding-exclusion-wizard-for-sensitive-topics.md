---
id: US-634
title: "Onboarding Exclusion Wizard for Sensitive Topics"
slug: onboarding-exclusion-wizard-for-sensitive-topics
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, onboarding, accessibility]
---

# US-634: Onboarding Exclusion Wizard for Sensitive Topics

## User Story

**As an** accessibility-first user
**I want to** be presented with a guided wizard during onboarding that lets me quickly exclude common sensitive topic categories
**So that** I can configure meaningful protections without needing to know specific tag names

## Acceptance Criteria

- **Given** I reach the safety step in onboarding
  **When** the exclusion wizard loads
  **Then** I see a checklist of pre-defined sensitive topic groups (e.g., "Political content," "Violence & Conflict," "Self-harm adjacent") with simple toggle switches

- **Given** I toggle on "Political content"
  **When** I advance past the wizard
  **Then** all platform-curated political interest tags are added to my exclusion list in one step

- **Given** the wizard is navigated using only a keyboard
  **When** I move between toggles and confirm
  **Then** all actions complete without requiring a mouse

## Notes
The curated tag groups are maintained by the Trust & Safety team; users can refine per-tag later (US-601).
