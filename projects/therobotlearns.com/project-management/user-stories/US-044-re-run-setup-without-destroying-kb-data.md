---
id: US-044
title: "Re-run Setup Without Destroying KB Data"
slug: re-run-setup-without-destroying-kb-data
personas: [P-001, P-004]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [setup, data-safety, profile-update]
---

# US-044: Re-run Setup Without Destroying KB Data

## User Story

**As an** existing user whose skills or preferences have changed
**I want to** re-run `/setup` later to update my profiles without wiping out my existing KB articles, flashcards, and session logs
**So that** I can keep my accumulated learning history while adjusting my configuration

## Acceptance Criteria

- **Given** I already have an existing KB with articles, flashcards, and session logs
  **When** I run `/setup` again
  **Then** it detects the existing environment and offers an "update profile" path instead of a fresh bootstrap.

- **Given** I choose to update my user profile or machine profile
  **When** the update completes
  **Then** only the profile files are modified and my KB content, flashcards, and session logs remain untouched.

- **Given** I want to review changes before they're applied
  **When** `/setup` shows me a summary of what will change
  **Then** I can confirm or cancel before anything is written.

- **Given** the update process is interrupted (e.g., I cancel mid-flow)
  **When** I check my environment afterward
  **Then** no partial or corrupted profile state is left behind.
