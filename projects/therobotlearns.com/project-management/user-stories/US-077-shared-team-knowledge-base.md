---
id: US-077
title: "Shared Team Knowledge Base"
slug: shared-team-knowledge-base
personas: [P-004]
epic: "Collaboration & Cloud"
priority: could-have
complexity: high
tags: [cloud, team, shared-kb, future]
---

# US-077: Shared Team Knowledge Base

## User Story

**As a** engineering team lead
**I want to** maintain a shared team knowledge base that syncs to every team member's local robot-learns install
**So that** the whole team learns from the same curated articles and decks instead of duplicating effort

## Acceptance Criteria

- **Given** a team KB exists on therobotlearns.com cloud
  **When** a team member's local robot-learns syncs
  **Then** team KB articles and decks appear alongside their personal KB, clearly labeled as team-sourced and read-only by default

- **Given** I am the team lead
  **When** I publish an update to a team KB article
  **Then** the update propagates to all team members' local copies on their next sync without touching their personal annotations

- **Given** a team member wants to fork a team article into their personal KB for editing
  **When** they choose "fork to personal"
  **Then** a personal copy is created and future team updates no longer overwrite it

## Notes
Future cloud scope, depends on US-076 (account sync) and reuses the merge logic from US-075/US-081.
