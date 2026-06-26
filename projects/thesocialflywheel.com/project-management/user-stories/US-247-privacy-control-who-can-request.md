---
id: US-247
title: "Privacy Control Who Can Request"
slug: privacy-control-who-can-request
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [privacy, requests, safety]
---

# US-247: Privacy Control Who Can Request

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** control who is allowed to send me mutual requests
**So that** I can limit unsolicited connection attempts from strangers

## Acceptance Criteria

- **Given** I navigate to Privacy Settings → Mutual Requests
  **When** I choose "Only people in my web (2nd–4th degree)"
  **Then** users outside my 4th-degree web cannot send me mutual requests; the "Add Mutual" button is hidden on my profile for those users

- **Given** I choose "No one can send me requests"
  **When** any user attempts to send me a request
  **Then** the system blocks the attempt silently; the "Add Mutual" button is replaced with a disabled state or hidden

- **Given** I change my privacy setting to "Everyone"
  **When** the setting is saved
  **Then** any registered user can send me a request, and the button is visible on my public profile

## Notes
Default setting for new accounts should be "Everyone" to facilitate onboarding, with a prompt to review privacy settings after initial setup.
