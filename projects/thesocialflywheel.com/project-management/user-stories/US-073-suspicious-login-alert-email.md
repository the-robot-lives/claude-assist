---
id: US-073
title: "Suspicious Login Alert Email"
slug: suspicious-login-alert-email
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [security, alerts, email, notifications]
---

# US-073: Suspicious Login Alert Email

## User Story

**As a** cautious newcomer
**I want to** receive an immediate email alert when a suspicious login is detected on my account
**So that** I can take action quickly if my account is being accessed without my consent

## Acceptance Criteria

- **Given** a suspicious login is detected
  **When** the alert is triggered
  **Then** I receive an email within 60 seconds containing the device type, approximate location, time, and links to "This was me" and "Secure my account"

- **Given** I click "Secure my account" in the alert email
  **When** I follow the link
  **Then** all sessions except the current browser viewing the link are revoked and I am prompted to change my password
