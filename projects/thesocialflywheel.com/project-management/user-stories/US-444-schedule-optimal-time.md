---
id: US-444
title: "Schedule post for suggested optimal time"
slug: schedule-post-optimal-time
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: high
tags: [scheduling, analytics, ml, automation]
---

# US-444: Schedule Post for Suggested Optimal Time

## User Story

**As a** Creator
**I want to** receive a suggested optimal publishing time based on when my mutuals are most active
**So that** my posts get maximum engagement without me having to analyze activity patterns manually

## Acceptance Criteria

- **Given** I tap "Schedule"
  **When** I choose "Best time"
  **Then** the system suggests up to three time slots within the next 48 hours based on mutual activity patterns

- **Given** I accept a suggested time
  **When** the post is saved
  **Then** it is scheduled exactly as if I had manually entered that time (see US-409)

## Notes
Suggestions are personalized per account; initial suggestions are generic until enough activity data exists.
