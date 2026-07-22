---
id: US-061
title: "Migrate KB on New Launcher Template Version"
slug: migrate-kb-template-version
personas: [P-008, P-002, P-006]
epic: "KB Maintenance"
priority: must-have
complexity: high
tags: [migration, template, versioning]
---

# US-061: Migrate KB on New Launcher Template Version

## User Story

**As a** privacy-first offline consultant running an older KB template version
**I want to** migrate my existing KB when `robot-learns` ships a newer template
**So that** I stay compatible with the current agent environment without losing or corrupting my data

## Acceptance Criteria

- **Given** my KB was bootstrapped from an older template version than the one the launcher currently ships
  **When** I start `robot-learns`
  **Then** I'm notified a template migration is available and shown what will change before anything runs

- **Given** I approve the migration
  **When** it runs
  **Then** structural/config changes from the template are applied while my personal KB content (articles, decks, logs) is left untouched except where the schema itself requires updates

- **Given** the migration would touch schema-governed data files
  **When** it proceeds
  **Then** it defers to the schema-version migration flow (see pre-migration backup) rather than editing those files directly

- **Given** I decline the migration
  **When** I continue using `robot-learns`
  **Then** I can keep working on the old template version with a persistent reminder that migration is pending

## Notes
Directly depends on [[US-062]] for the backup-before-migrate guarantee.
