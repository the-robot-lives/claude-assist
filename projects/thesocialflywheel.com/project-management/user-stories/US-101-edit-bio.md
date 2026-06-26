---
id: US-101
title: "Edit bio"
slug: edit-bio
personas: [P-003]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, identity]
---

# US-101: Edit Bio

## User Story

**As a** social connector
**I want to** write and edit a short bio on my profile
**So that** people I meet across channels quickly understand who I am and why we might connect

## Acceptance Criteria

- **Given** I am on my own profile in edit mode
  **When** I type into the bio field and save
  **Then** my updated bio is stored and shown on my profile

- **Given** I enter a bio that exceeds the character limit
  **When** I attempt to save
  **Then** I see an inline error and the bio is not saved until I shorten it

## Notes
Plain text with basic line breaks; no rich formatting in v1.
