---
id: US-066
title: "Re-subscribe or resume a paused list"
slug: resubscribe-and-resume
personas: [P-001]
epic: "Preference Center"
priority: could-have
complexity: low
tags: [preference-center, resubscribe, resume]
---

# US-066: Re-subscribe or resume a paused list

## User Story

**As a** subscriber who unsubscribed or paused a list
**I want to** re-subscribe or resume it from my dashboard
**So that** I can re-engage on my terms

## Acceptance Criteria

- **Given** an unsubscribed subscription
  **When** I choose "Re-subscribe"
  **Then** it re-activates per the list's opt-in mode (re-confirm if double opt-in)
- **Given** a paused subscription
  **When** I choose "Resume"
  **Then** contact resumes at my prior preferences
- **Given** re-subscribe requires confirmation
  **When** I trigger it
  **Then** a fresh confirmation email is sent

## Notes
