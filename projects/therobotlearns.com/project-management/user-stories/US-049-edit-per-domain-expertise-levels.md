---
id: US-049
title: "Edit Per-Domain Expertise Levels"
slug: edit-per-domain-expertise-levels
personas: [P-002, P-001]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [settings, profile, expertise]
---

# US-049: Edit Per-Domain Expertise Levels

## User Story

**As a** user who has grown in a domain since onboarding
**I want to** edit my per-domain expertise levels at any time
**So that** the difficulty of questions, articles, and quizzes stays matched to my current skill

## Acceptance Criteria

- **Given** I have an existing user profile with domain expertise levels
  **When** I open the settings/profile editor
  **Then** I see each domain and its current level, editable individually.

- **Given** I raise or lower a domain's expertise level
  **When** I save the change
  **Then** subsequent `/query` answers and quiz difficulty reflect the updated level immediately.

- **Given** I add a new domain that wasn't part of my original onboarding
  **When** I set an expertise level for it
  **Then** it is added to my profile without disturbing existing domains.

- **Given** I make an edit I didn't intend
  **When** I cancel before saving
  **Then** my profile remains unchanged.
