---
id: US-041
title: "Guided User Profile Creation"
slug: guided-user-profile-creation
personas: [P-002, P-005, P-004]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [onboarding, profile, personalization]
---

# US-041: Guided User Profile Creation

## User Story

**As a** new user
**I want to** be guided through providing my per-domain expertise levels and preferred learning style
**So that** the agent can calibrate its Q&A, KB articles, and quizzes to my actual skill level

## Acceptance Criteria

- **Given** I am in the `/setup` flow after bootstrap
  **When** I reach the profile step
  **Then** I am asked to rate my expertise across relevant domains (e.g., beginner/intermediate/advanced/expert) rather than filling out a blank form.

- **Given** I am unsure how to answer a domain question
  **When** I ask for clarification or examples
  **Then** the agent offers plain-language descriptions of each level to help me choose accurately.

- **Given** I complete the expertise questions
  **When** I am asked about learning style
  **Then** I can choose preferences such as examples-first vs theory-first and my preferred verbosity.

- **Given** I finish the guided profile creation
  **When** the flow ends
  **Then** my answers are saved to a user profile file that later commands (`/query`, quizzes, flashcards) read from.
