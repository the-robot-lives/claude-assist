---
id: US-687
title: "Mod Message to Sanctioned User"
slug: mod-message-to-sanctioned-user
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [moderation, communication, sanctions]
---

# US-687: Mod Message to Sanctioned User

## User Story

**As a** channel moderator applying a sanction
**I want to** have a system message automatically sent to the sanctioned user explaining the action
**So that** users understand what rule they broke and can adjust their behaviour, reducing repeat violations

## Acceptance Criteria

- **Given** I apply any sanction (warn, timeout, or ban) to a user
  **When** the action is saved
  **Then** a system message is delivered to the user's notification centre stating: the channel name, the action type, the rule violated (if selected), the sanction duration (if applicable), and a link to appeal

- **Given** the system message is sent
  **When** the user views it
  **Then** they do not see the moderator's personal identity — only the channel name and a generic "Channel Moderation Team" attribution

- **Given** I add an optional personal note in the action dialog
  **When** the system message is delivered
  **Then** my note is included verbatim below the standard template

## Notes
Hiding mod identity in system messages protects mods from targeted harassment by sanctioned users.
