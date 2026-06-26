---
id: US-670
title: "Transparency Notification to User"
slug: transparency-notification-to-user
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [transparency, notifications]
---

# US-670: Transparency Notification to User

## User Story

**As a** cautious newcomer who filed a report
**I want to** receive a notification when my report is resolved
**So that** I know the platform took my concern seriously without needing to chase it up

## Acceptance Criteria

- **Given** a report I submitted has been resolved by a mod or platform T&S
  **When** the case is closed
  **Then** I receive a notification stating the outcome category: "Action taken", "No action — did not violate rules", or "Escalated for further review"

- **Given** the outcome notification is sent
  **When** I view it
  **Then** it does not reveal the identity of any mod who acted on the case, nor any detail that would allow me to infer the specific sanction applied

## Notes
Outcome categories must be kept high-level to prevent reporters from gaming the system or harassing sanctioned users.
