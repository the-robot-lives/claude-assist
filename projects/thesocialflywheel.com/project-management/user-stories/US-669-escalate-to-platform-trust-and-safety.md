---
id: US-669
title: "Escalate to Platform Trust and Safety"
slug: escalate-to-platform-trust-and-safety
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [escalation, platform-trust-safety]
---

# US-669: Escalate to Platform Trust and Safety

## User Story

**As a** channel moderator
**I want to** escalate a report to platform Trust & Safety in one step
**So that** cases beyond my scope or authority (CSAM, credible threats, coordinated abuse) are handled by the right team immediately

## Acceptance Criteria

- **Given** I am viewing a report in my channel queue
  **When** I select "Escalate to Platform T&S" and provide a brief reason
  **Then** a platform-level case is created, the report is removed from my channel queue, and my channel audit log records the escalation

- **Given** a case has been escalated
  **When** platform T&S updates the case status
  **Then** I receive a notification with the outcome (e.g. "Global ban applied", "No action — returned to channel") so I am aware of the resolution

## Notes
Mods must never be left with CSAM or credible-threat content in their queue without a clear escalation path; the escalation button must be prominently visible.
