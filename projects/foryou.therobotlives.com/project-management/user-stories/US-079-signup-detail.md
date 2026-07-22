---
id: US-079
title: "View a single signup's detail"
slug: signup-detail
personas: [P-003]
epic: "Admin Console"
priority: must-have
complexity: low
tags: [admin, signup, detail, preferences]
---

# US-079: View a single signup's detail

## User Story

**As a** site owner/admin
**I want to** open one signup and see all its details
**So that** I can inspect its attributes, status, and preferences

## Acceptance Criteria

- **Given** a signup in the table
  **When** I open it
  **Then** I see its full attribute values, status history, and contact preferences
- **Given** the signup is linked to a user account
  **When** I view it
  **Then** the linkage is shown
- **Given** I lack permission
  **When** I try to open it
  **Then** access is denied

## Notes
Read-focused; respects the no-existence-leak boundary for public surfaces.
