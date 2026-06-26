---
id: US-710
title: "Notify User of Content Report Outcome"
slug: moderation-report-outcome
personas: [P-001]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [moderation, safety, notifications]
---

# US-710: Notify User of Content Report Outcome

## User Story

**As a** Bridge Builder
**I want to** receive a notification when a report I submitted has been reviewed
**So that** I can understand whether the platform took action and feel that my safety concerns are heard

## Acceptance Criteria

- **Given** I submitted a content or user report
  **When** a moderator closes the report with an outcome
  **Then** I receive an in-app notification stating "Your report has been reviewed. [Action taken / No violation found.]"

- **Given** the moderation outcome notification is delivered
  **When** I tap it
  **Then** I see a summary of the report I filed and the outcome, without disclosing enforcement details about the reported user

## Notes
Notification must not reveal personally identifiable enforcement details per privacy policy.
