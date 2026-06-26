---
id: US-615
title: "View Full Block List"
slug: view-full-block-list
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, management]
---

# US-615: View Full Block List

## User Story

**As a** cautious newcomer
**I want to** view a complete list of all users I have blocked
**So that** I can audit and manage my safety configuration at any time

## Acceptance Criteria

- **Given** I navigate to Settings > Safety > Blocked Users
  **When** the page loads
  **Then** I see a paginated list of all blocked accounts with username, block date, and cascade setting

- **Given** I have no active blocks
  **When** I visit the Blocked Users page
  **Then** an empty-state message confirms no one is blocked

## Notes
Block list is private; others cannot see it (covered in US-645).
