---
id: US-688
title: "Opposing Views Moderation Guidelines"
slug: opposing-views-moderation-guidelines
personas: [P-005, P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [opposing-views, policy, moderation]
---

# US-688: Opposing Views Moderation Guidelines

## User Story

**As a** channel moderator reviewing content in the Opposing-Views lane
**I want to** access clear, example-driven policy guidance distinguishing protected disagreement from sanctionable harassment
**So that** I apply consistent, defensible decisions that preserve the lane's core purpose

## Acceptance Criteria

- **Given** I open the mod guidelines for the Opposing-Views lane
  **When** the page loads
  **Then** I see a two-column comparison: "Protected Dissent" examples on the left (counter-arguments, criticism of ideas, sarcasm targeting positions) vs "Sanctionable Conduct" on the right (personal attacks, doxxing, slurs, threats)

- **Given** I am filling out a report action form for an Opposing-Views post
  **When** I click "View Policy"
  **Then** a side panel opens with the relevant guideline section without closing or losing my action form state

- **Given** the platform updates opposing-views policy
  **When** I next open any mod panel
  **Then** a banner highlights "Policy updated" with a diff of the changed examples so I notice what specifically changed

## Notes
These guidelines should be authored jointly by legal, policy, and the product team and versioned; older versions should be accessible to support audit of historical decisions.
