---
id: US-125
title: "Provide screen-reader-friendly profile markup"
slug: profile-screen-reader-markup
personas: [P-008]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, accessibility, a11y]
---

# US-125: Provide Screen-Reader-Friendly Profile Markup

## User Story

**As an** accessibility-first user
**I want to** navigate profiles with a screen reader
**So that** I can understand and act on profile content without sighted assistance

## Acceptance Criteria

- **Given** I use a screen reader
  **When** I open a profile
  **Then** headings, landmarks, and ARIA roles are present so I can navigate by structure

- **Given** interactive controls exist on the profile
  **When** I focus each control
  **Then** it announces a clear accessible name, role, and state

## Notes
Validate against WCAG 2.2 AA and test with VoiceOver and NVDA.
