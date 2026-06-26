---
id: US-633
title: "Safety Prompt During Onboarding"
slug: safety-prompt-during-onboarding
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, onboarding]
---

# US-633: Safety Prompt During Onboarding

## User Story

**As a** cautious newcomer
**I want to** be guided through essential safety settings during account setup
**So that** I start with appropriate protections in place before I encounter any content

## Acceptance Criteria

- **Given** I complete the basic profile creation step
  **When** onboarding proceeds to the next screen
  **Then** a "Your Safety" step is presented covering: Swipe-to-Match defaults, interest exclusions, and who can find me

- **Given** I reach the safety step
  **When** I configure at least Swipe-to-Match visibility and confirm
  **Then** onboarding advances and my settings are saved immediately

- **Given** I skip the safety step
  **When** onboarding completes
  **Then** safety defaults are applied (mutuals-only matching, no exclusions) and a banner invites me to review later

## Notes
Default settings favour privacy for new users (US-627).
