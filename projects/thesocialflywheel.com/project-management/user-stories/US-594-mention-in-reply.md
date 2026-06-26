---
id: US-594
title: "Mention Someone in a Reply"
slug: mention-in-reply
personas: [P-003]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [reply, mentions, notifications]
---

# US-594: Mention Someone in a Reply

## User Story

**As a** Social Connector
**I want to** @mention a mutual in my reply
**So that** I can pull specific people into a conversation

## Acceptance Criteria

- **Given** I am typing a reply
  **When** I type "@" followed by at least two characters
  **Then** an autocomplete dropdown shows matching mutuals within my web

- **Given** I select a mutual from the dropdown and post
  **Then** the mentioned person receives a "You were mentioned" notification with a link to the reply

- **Given** the mentioned person is outside my web
  **Then** the @mention resolves as plain text and no notification is delivered

## Notes
Mentions render as tappable profile links to anyone who can see the post. Limit 5 mentions per reply to prevent mention-spam.
