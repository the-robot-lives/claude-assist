---
id: US-439
title: "Mention a mutual in a reply"
slug: mention-mutual-in-reply
personas: [P-003]
epic: "Posting & Content Creation"
priority: should-have
complexity: low
tags: [mention, reply, mutuals, notification]
---

# US-439: Mention a Mutual in a Reply

## User Story

**As a** Social Connector
**I want to** @mention a mutual within a reply to another post
**So that** I can draw a third person into an ongoing conversation

## Acceptance Criteria

- **Given** I am typing a reply to any post
  **When** I type "@" and at least two characters
  **Then** a dropdown of matching mutuals appears for me to select

- **Given** I mention a mutual in a reply and submit
  **When** the reply is published
  **Then** the mentioned mutual receives a notification linking to the reply in context

## Notes
Shares the mention autocomplete logic with US-421 but triggered from the reply composer.
