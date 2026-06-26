---
id: US-083
title: "Personal Security Audit Log"
slug: security-audit-log
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [audit-log, security, transparency]
---

# US-083: Personal Security Audit Log

## User Story

**As a** skeptical switcher
**I want to** view a log of all security-relevant events on my account
**So that** I can review what has happened and detect unauthorized activity

## Acceptance Criteria

- **Given** I open the Security Audit Log in Settings
  **When** the page loads
  **Then** I see a reverse-chronological list of events (logins, password changes, 2FA changes, session revocations) with timestamp, device, and IP for each

- **Given** I filter the audit log by event type
  **When** I select "password changes"
  **Then** only password-change events are displayed

## Notes
Log must retain at least 90 days of history.
