---
id: US-035
title: "Onboarding Path for Platform Migrants"
slug: onboarding-path-platform-migrants
personas: [P-010, P-001]
epic: "Onboarding & Account Setup"
priority: could-have
complexity: high
tags: [migration, switcher, import, onboarding]
---

# US-035: Onboarding Path for Platform Migrants

## User Story

**As a** skeptical switcher migrating from another platform
**I want to** import my interest graph and follower list
**So that** I can reproduce my social context on Flywheel without rebuilding from zero

## Acceptance Criteria

- **Given** I choose "Import from [Platform]" during onboarding
  **When** the import completes
  **Then** matched users appear in my suggested connections and my interests are pre-populated from my import data.

- **Given** some imported interests do not match Flywheel's taxonomy
  **When** the import resolves
  **Then** unmapped interests are shown with "closest match" suggestions I can confirm or dismiss.

## Notes
Data import uses platform-provided archive formats (e.g. Twitter data export ZIP). Never request live API credentials — offline archive only. Rate of matches depends on how many users joined via the same import source.
