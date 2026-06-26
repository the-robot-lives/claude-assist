---
id: US-680
title: "Anonymous Reporting Option"
slug: anonymous-reporting-option
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [reporting, privacy, anonymity]
---

# US-680: Anonymous Reporting Option

## User Story

**As a** cautious newcomer who fears retaliation
**I want to** submit a report without my identity being stored in the report record
**So that** I can report abuse safely even in close-knit or confrontational communities

## Acceptance Criteria

- **Given** I am in the report flow
  **When** I toggle "Submit anonymously"
  **Then** my user ID is replaced with an anonymised token in the stored report record and the mod queue displays no reporter identity

- **Given** I submit an anonymous report
  **When** the report is reviewed by a mod
  **Then** the mod cannot see my username, profile link, or any data that would allow them to identify me

- **Given** I choose anonymous reporting
  **When** the report is resolved
  **Then** the outcome notification is delivered to my notification centre but the notification itself does not contain my name (so even notification previews don't leak identity)

## Notes
Anonymous reports carry the same weight in the queue as identified reports; mods must not be told which reports are anonymous to prevent deprioritisation.
