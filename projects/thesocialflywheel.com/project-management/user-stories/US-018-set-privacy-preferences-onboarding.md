---
id: US-018
title: "Set Privacy Preferences During Onboarding"
slug: set-privacy-preferences-onboarding
personas: [P-004, P-006, P-008]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [privacy, onboarding, settings]
---

# US-018: Set Privacy Preferences During Onboarding

## User Story

**As a** cautious newcomer
**I want to** configure my privacy settings before I start using the app
**So that** I control who can discover me and send me mutual requests

## Acceptance Criteria

- **Given** I am on the privacy setup screen
  **When** I choose "Moots of moots only" for discovery
  **Then** only users within my 2nd-degree network can send me mutual requests.

- **Given** I toggle "Allow interest-based suggestions to others"
  **When** off
  **Then** my profile will not appear in the "People you may know" list shown to other users.

## Notes
Defaults should be the most restrictive reasonable setting. Show a plain-language summary of each option's consequence, not just a label.
