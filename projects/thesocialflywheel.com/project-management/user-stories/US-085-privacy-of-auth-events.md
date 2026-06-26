---
id: US-085
title: "Privacy of Authentication Events"
slug: privacy-of-auth-events
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [privacy, security, audit-log]
---

# US-085: Privacy of Authentication Events

## User Story

**As a** cautious newcomer
**I want to** know that my login history and security events are visible only to me
**So that** other users, including moderators, cannot see when or where I log in

## Acceptance Criteria

- **Given** another user or a channel moderator views my profile
  **When** they look for login or security information
  **Then** no authentication event data is exposed on public-facing pages or moderator panels

- **Given** Flywheel staff review my account for a support case
  **When** they access security logs
  **Then** access is recorded in an internal audit trail and I am notified of the staff access
