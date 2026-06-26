---
id: US-563
title: "Mute a Reply Thread"
slug: mute-reply-thread
personas: [P-006]
epic: "Reactions & Engagement"
priority: should-have
complexity: low
tags: [mute, thread, notifications]
---

# US-563: Mute a Reply Thread

## User Story

**As a** Quiet Consumer
**I want to** mute a reply thread I've commented in
**So that** I stop receiving notifications about it without deleting my contribution

## Acceptance Criteria

- **Given** I have replied to a post
  **When** I tap the thread options menu and select Mute
  **Then** I no longer receive notifications for new replies in that thread

- **Given** I mute a thread
  **When** I navigate to Notification Settings → Muted Threads
  **Then** I see the thread listed and can unmute it at any time

## Notes
Muting a thread does not remove my own replies or hide the thread from my feed; it only silences notifications.
