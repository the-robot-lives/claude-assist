---
id: US-300
title: "Mutual Conversion Confirmation Screen"
slug: mutual-conversion-confirmation-screen
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [mutuals, accept, confirmation, core-flow]
---

# US-300: Mutual Conversion Confirmation Screen

## User Story

**As a** Social Connector (P-003)
**I want to** see a clear confirmation screen after accepting an interest that summarizes what becoming mutuals means
**So that** I understand exactly what access I am granting and receiving before the link is finalized

## Acceptance Criteria

- **Given** I tap "Accept" on an incoming interest
  **When** the confirmation screen appears
  **Then** it clearly states that we will both see each other's public posts and both appear in each other's mutuals list

- **Given** the confirmation screen is shown
  **When** I tap "Confirm"
  **Then** the mutual link is created and I am taken to the new mutual's profile

- **Given** the confirmation screen is shown
  **When** I tap "Cancel"
  **Then** no mutual link is created and the interest remains pending in my inbox
