---
id: US-290
title: "Undo Limited to One Per Session"
slug: undo-limited-to-one-per-session
personas: [P-003]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [undo, rate-limiting, session, abuse-resistance]
---

# US-290: Undo Limited to One Per Session

## User Story

**As a** Social Connector (P-003)
**I want to** understand that undo is a single-use action per swipe session
**So that** I use it thoughtfully and the system is not gamed through repeated undo loops

## Acceptance Criteria

- **Given** I have used my one undo for the session
  **When** I swipe on the next card
  **Then** no undo button is shown after the swipe

- **Given** I start a new swipe session (app restart or next day)
  **When** I make my first swipe
  **Then** the undo button is available again
