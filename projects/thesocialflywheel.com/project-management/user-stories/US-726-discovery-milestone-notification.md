---
id: US-726
title: "Notify User of Discovery Milestone Reached"
slug: discovery-milestone-notification
personas: [P-003]
epic: "Notifications"
priority: could-have
complexity: medium
tags: [discovery, milestones, notifications, gamification]
---

# US-726: Notify User of Discovery Milestone Reached

## User Story

**As a** Social Connector
**I want to** receive a notification when I hit a meaningful Discovery milestone (e.g., 10 swipes right, 5 matches)
**So that** I feel a sense of progress and am encouraged to continue engaging with the Discovery lane

## Acceptance Criteria

- **Given** I am an active user in the Discovery / swipe lane
  **When** I reach a configured milestone (e.g., 10 mutual interest expressions)
  **Then** I receive an in-app celebration notification: "Discovery milestone: 10 connections sparked!"

- **Given** the milestone notification is delivered
  **When** I tap it
  **Then** I am taken to my Discovery stats page showing cumulative engagement

## Notes
Milestone thresholds: 1, 5, 10, 25, 50, 100 matches. Only deliver once per threshold, never repeat.
