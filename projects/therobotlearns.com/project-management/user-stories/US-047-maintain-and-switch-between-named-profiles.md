---
id: US-047
title: "Maintain and Switch Between Named Profiles"
slug: maintain-and-switch-between-named-profiles
personas: [P-003, P-006, P-004]
epic: "Onboarding & Setup"
priority: could-have
complexity: high
tags: [profiles, multi-context, power-user]
---

# US-047: Maintain and Switch Between Named Profiles

## User Story

**As a** user who works across distinct contexts (e.g., a work stack and a personal-learning stack)
**I want to** maintain multiple named profiles and switch between them
**So that** my expertise levels, learning style, and KB content stay relevant to whichever context I'm in

## Acceptance Criteria

- **Given** I already have a default profile set up
  **When** I create a new named profile via `/setup`
  **Then** it is stored separately without altering my existing profile or KB.

- **Given** I have multiple named profiles
  **When** I run a command to list them
  **Then** I see all profile names and which one is currently active.

- **Given** I want to switch context
  **When** I select a different named profile
  **Then** subsequent commands (`/query`, quizzes, flashcards) use that profile's expertise levels and preferences.

- **Given** I switch profiles
  **When** I check my KB content
  **Then** each profile's KB data remains isolated from the others (no cross-contamination).
