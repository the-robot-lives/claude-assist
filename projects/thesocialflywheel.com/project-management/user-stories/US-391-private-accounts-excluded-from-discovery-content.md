---
id: US-391
title: "Private Accounts Excluded from Discovery Content"
slug: private-accounts-excluded-from-discovery-content
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, privacy, safety]
---

# US-391: Private Accounts Excluded from Discovery Content

## User Story

**As a** Bridge-Builder
**I want to** ensure that content from private accounts is never surfaced in discovery unless I already follow them
**So that** private users' content is not distributed beyond their approved audience through the discovery mechanism

## Acceptance Criteria

- **Given** a user has set their account to private
  **When** the discovery engine evaluates their posts as candidates
  **Then** those posts are excluded from discovery for all users who do not already follow that private account

- **Given** I follow a private account
  **When** the discovery engine runs
  **Then** that account's posts may appear in my regular feed but are never surfaced as discovery items for other users not following them

## Notes
This is a strict privacy rule. No exceptions for degree of connection; private means private.
