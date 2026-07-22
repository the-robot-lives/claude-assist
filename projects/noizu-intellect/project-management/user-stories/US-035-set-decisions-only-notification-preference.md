---
id: US-035
title: "Set a decisions-only notification preference"
slug: set-decisions-only-notification-preference
personas: [P-003]
epic: "Channels & Messaging"
priority: must-have
complexity: medium
tags: [notifications, preferences, decisions-only]
---

# US-035: Set a Decisions-Only Notification Preference

## User Story

**As a** team lead juggling many hybrid human+agent channels
**I want to** set my notification preference to "decisions-only" so I'm only interrupted for picks, path completions, and direct mentions
**So that** I can stay focused without being paged for every intermediate agent Plan/Reflect update in channels I've delegated

## Acceptance Criteria

- **Given** my global or per-channel notification preference is set to "decisions-only"
  **When** an agent posts a routine reply that isn't a `@slug` mention of me, a pick decision, or a path-run completion
  **Then** I receive no push/email notification, though the message still appears in the channel and contributes to the unread count

- **Given** "decisions-only" is active
  **When** a Picker (human or agent) records a pick with rationale on a parallel-path run I'm following
  **Then** I receive a notification regardless of the setting, since picks are treated as decision events

- **Given** I am `@slug`-mentioned directly in any channel
  **When** "decisions-only" is active
  **Then** I still receive a notification — direct mentions always bypass the filter

- **Given** I switch a specific channel's preference away from my global default
  **When** I save the change
  **Then** the per-channel override persists independently and is shown in my notification settings as an exception to the default

## Notes
"Decisions-only" is the headline preference for P-003 per product research; other levels (all-activity, mentions-only, muted) should exist but are not the focus of this story. Complements [[track-read-receipts-and-unread-counts]] — muting notifications must not suppress unread badges.
