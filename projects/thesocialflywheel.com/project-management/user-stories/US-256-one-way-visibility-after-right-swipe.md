---
id: US-256
title: "One-Way Visibility After Right Swipe"
slug: one-way-visibility-after-right-swipe
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: high
tags: [visibility, one-way, privacy, core-flow]
---

# US-256: One-Way Visibility After Right Swipe

## User Story

**As a** Social Connector (P-003)
**I want to** understand that after I swipe right the candidate can see my posts but I cannot yet see theirs
**So that** I know what I am agreeing to before confirming interest

## Acceptance Criteria

- **Given** I swipe right on a candidate
  **When** the action is confirmed
  **Then** a one-time tooltip explains that they may now see my public posts but I cannot see theirs until they accept

- **Given** a candidate has received my right-swipe
  **When** they view their match inbox
  **Then** they can browse my recent public posts before deciding to accept or reject

- **Given** the candidate has not yet responded
  **When** I view my outgoing interests
  **Then** my feed still does not include their posts
