---
id: US-051
title: "Configure Local Preferences via Local-Preference Schema"
slug: configure-local-preferences-via-schema
personas: [P-001, P-003, P-006]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [settings, local-preference, editor, terminal]
---

# US-051: Configure Local Preferences via Local-Preference Schema

## User Story

**As a** terminal-native developer with strong tooling opinions
**I want to** configure local preferences like editor, pager, and output width through the local-preference YAML schema
**So that** robot-learns fits into my existing workflow instead of fighting it

## Acceptance Criteria

- **Given** I want to change my preferred editor
  **When** I edit the local-preference config (directly or via a settings command)
  **Then** the schema validates my input against the documented local-preference fields.

- **Given** I set a pager and output width
  **When** I run a command that produces long output (e.g., a KB article)
  **Then** it is displayed using my configured pager and wrapped to my configured width.

- **Given** I provide an invalid value in the local-preference file
  **When** robot-learns loads it
  **Then** I get a clear validation error naming the offending field, not a silent fallback or crash.

- **Given** I have not set a given local preference
  **When** that setting is needed
  **Then** a documented default is used automatically.
