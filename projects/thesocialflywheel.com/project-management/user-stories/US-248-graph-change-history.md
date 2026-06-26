---
id: US-248
title: "Graph Change History"
slug: graph-change-history
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [graph, history, transparency]
---

# US-248: Graph Change History

## User Story

**As a** Bridge-Builder (P-001)
**I want to** view a chronological log of changes to my mutual graph (connections added, removed, requests sent/received)
**So that** I can track how my network has evolved over time

## Acceptance Criteria

- **Given** I navigate to "Network" → "Activity Log"
  **When** the log loads
  **Then** I see a reverse-chronological list of events: mutual added, mutual removed, request sent, request received, request cancelled, with timestamps

- **Given** I tap an event in the log
  **When** it expands
  **Then** I see the other user's name and a link to their profile (if they have not blocked me)

## Notes
Log retention should be at minimum 90 days. Events older than the retention window are summarized (e.g., "27 connections made before [date]").
