---
id: US-642
title: "Detect and Reject Re-registration After Block"
slug: detect-and-reject-re-registration-after-block
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: high
tags: [safety, blocking, evasion]
---

# US-642: Detect and Reject Re-registration After Block

## User Story

**As a** cautious newcomer
**I want to** be protected from a blocked user evading my block by creating a new account
**So that** the block cannot be trivially circumvented by account hopping

## Acceptance Criteria

- **Given** User X is blocked by me and creates a new account with the same device fingerprint or phone number
  **When** the new account attempts to view my profile or interact with me
  **Then** the system flags the account for review and my block automatically extends to the new account

- **Given** a new account is flagged as a potential evasion attempt
  **When** Trust & Safety reviews it
  **Then** confirmed evasion accounts are suspended and the reporting user is notified

## Notes
Fingerprinting must comply with platform privacy policy; phone-number linkage is the primary signal.
