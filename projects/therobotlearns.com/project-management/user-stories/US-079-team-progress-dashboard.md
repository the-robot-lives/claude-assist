---
id: US-079
title: "Team Progress Dashboard for Leads"
slug: team-progress-dashboard
personas: [P-004]
epic: "Collaboration & Cloud"
priority: could-have
complexity: medium
tags: [cloud, team, dashboard, progress, future]
---

# US-079: Team Progress Dashboard for Leads

## User Story

**As a** engineering team lead
**I want to** view a dashboard summarizing my team's progress on assigned learning plans and shared decks
**So that** I can identify who needs support and where the team's knowledge gaps are

## Acceptance Criteria

- **Given** team members have synced progress to the cloud
  **When** I open the team progress dashboard
  **Then** I see per-member completion percentage, quiz scores, and flashcard retention for each assigned plan

- **Given** a team member has opted out of progress sharing at the individual level
  **When** I view the dashboard
  **Then** their detailed metrics are excluded and they appear as "not sharing" rather than showing stale or zeroed data

- **Given** no team members have synced recently
  **When** I open the dashboard
  **Then** I see a clear "last synced" timestamp per member instead of a silently outdated view

## Notes
Future cloud scope. Individual opt-out (second criterion) matters for trust — this is a coaching tool, not surveillance, and should be positioned that way in the eventual UI copy.
