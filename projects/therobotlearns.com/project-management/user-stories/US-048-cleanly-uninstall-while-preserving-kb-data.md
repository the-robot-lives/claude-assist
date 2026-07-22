---
id: US-048
title: "Cleanly Uninstall While Preserving KB Data"
slug: cleanly-uninstall-while-preserving-kb-data
personas: [P-008, P-001]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [uninstall, data-export, privacy]
---

# US-048: Cleanly Uninstall While Preserving KB Data

## User Story

**As a** privacy-conscious user who may stop using the tool
**I want to** cleanly uninstall robot-learns while preserving or exporting my KB data
**So that** I don't lose my accumulated knowledge base and retain full control over where my data ends up

## Acceptance Criteria

- **Given** I decide to uninstall the `the-robot-learns` package
  **When** I run the uninstall/export command before removing the npm package
  **Then** I am offered an option to export my KB (articles, flashcards, profiles, session logs) to a directory I choose.

- **Given** I export my data
  **When** the export completes
  **Then** it produces a self-contained archive I can inspect without any additional tooling.

- **Given** I choose to remove the local environment
  **When** I confirm the removal
  **Then** `~/.config/the-robot-learns-kb/` is deleted only after I've explicitly confirmed I've exported or don't want the data.

- **Given** I run `npm uninstall -g the-robot-learns`
  **When** the package is removed
  **Then** my exported data (if any) is untouched, since it lives outside the package installation path.
