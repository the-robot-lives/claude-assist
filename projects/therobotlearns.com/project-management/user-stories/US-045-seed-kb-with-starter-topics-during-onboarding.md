---
id: US-045
title: "Seed KB with Starter Topics During Onboarding"
slug: seed-kb-with-starter-topics-during-onboarding
personas: [P-002, P-005]
epic: "Onboarding & Setup"
priority: must-have
complexity: low
tags: [onboarding, kb, starter-content]
---

# US-045: Seed KB with Starter Topics During Onboarding

## User Story

**As a** new user finishing setup
**I want to** choose starter topics to seed my knowledge base
**So that** I have something to study right away instead of starting from an empty KB

## Acceptance Criteria

- **Given** I have completed profile creation
  **When** `/setup` reaches the topic-seeding step
  **Then** I am shown a list of suggested starter topics based on my stated domains and expertise levels.

- **Given** I want different topics than suggested
  **When** I enter my own topic names
  **Then** they are added to the seed list alongside or instead of the suggestions.

- **Given** I confirm my selected starter topics
  **When** seeding runs
  **Then** initial KB articles or stub entries are created for each chosen topic.

- **Given** I skip topic seeding entirely
  **When** setup completes
  **Then** I still end up with a valid, empty KB I can populate later via `/query`.
