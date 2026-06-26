---
id: US-510
title: "React to Message with Emoji"
slug: react-to-message-with-emoji
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [reactions, emoji, engagement]
---

# US-510: React to Message with Emoji

## User Story

**As a** Social Connector (P-003)
**I want to** add an emoji reaction to any message in a channel or DM
**So that** I can respond expressively without cluttering the thread with a short reply

## Acceptance Criteria

- **Given** I hover or long-press a message
  **When** I select an emoji from the quick-react tray or full picker
  **Then** the reaction appears beneath the message with a count, and tapping it again removes my reaction

- **Given** multiple people react with the same emoji
  **When** I view the message
  **Then** reactions are grouped by emoji with a running count and a tooltip listing reacting users (up to 10 names then "+N more")

## Notes
Quick-react tray should show the 6 most-recently used emoji for the user.
