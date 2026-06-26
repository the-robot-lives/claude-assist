---
id: US-752
title: "Change Phone Number"
slug: change-phone-number
personas: [P-004]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [settings, account, phone, 2fa]
---

# US-752: Change Phone Number

## User Story

**As a** cautious newcomer
**I want to** update my phone number in account settings
**So that** my two-factor authentication and recovery options stay accurate.

## Acceptance Criteria

- **Given** I navigate to Account Settings > Phone
  **When** I enter a new number and request a verification code
  **Then** a one-time code is sent via SMS to the new number.

- **Given** I have received the SMS code
  **When** I enter it correctly
  **Then** my phone number is updated and the old number is disassociated.

## Notes
SMS verification ensures the user owns the new number before completing the update.
