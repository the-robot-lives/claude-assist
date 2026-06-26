---
id: US-072
title: "Suspicious Login Detection"
slug: suspicious-login-detection
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: high
tags: [security, anomaly-detection, login]
---

# US-072: Suspicious Login Detection

## User Story

**As a** skeptical switcher
**I want to** have the platform detect logins from unusual locations or devices
**So that** I am alerted when someone may be accessing my account without my knowledge

## Acceptance Criteria

- **Given** a login occurs from a country or device type never seen for my account
  **When** the login succeeds
  **Then** the session is flagged as suspicious and an alert is sent immediately

- **Given** a login is flagged as suspicious
  **When** I have not set up 2FA
  **Then** I am prompted to verify the login via email before the session is granted full access
