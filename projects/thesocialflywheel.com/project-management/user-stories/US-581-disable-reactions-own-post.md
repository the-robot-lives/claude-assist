---
id: US-581
title: "Disable Reactions on My Own Post"
slug: disable-reactions-own-post
personas: [P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: low
tags: [creator, reactions, privacy, controls]
---

# US-581: Disable Reactions on My Own Post

## User Story

**As a** Creator
**I want to** disable reactions on a specific post
**So that** I can share sensitive content without inviting unsolicited emoji responses

## Acceptance Criteria

- **Given** I am composing a post
  **When** I open post settings before publishing
  **Then** I can toggle "Allow reactions" off

- **Given** reactions are disabled on a post
  **When** viewers open it
  **Then** the reaction button is absent and a small lock icon indicates controlled interaction mode

## Notes
Creator can re-enable reactions after publishing via post options menu. The setting does not affect replies; replies can be separately controlled.
