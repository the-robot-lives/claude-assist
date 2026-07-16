---
id: US-040
title: "Bootstrap Agent Environment on First Run"
slug: bootstrap-agent-environment-on-first-run
personas: [P-001, P-002]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [onboarding, setup, bootstrap]
---

# US-040: Bootstrap Agent Environment on First Run

## User Story

**As a** first-time user
**I want to** have the first run of `robot-learns` bootstrap `~/.config/the-robot-learns-kb/` from the bundled template via `/setup`
**So that** I have a working agent environment without manually creating config files

## Acceptance Criteria

- **Given** I run `robot-learns` for the first time with no existing `~/.config/the-robot-learns-kb/` directory
  **When** the launcher detects this state
  **Then** it prompts me to run the `/setup` command inside the agent session.

- **Given** I invoke `/setup`
  **When** the bootstrap process runs
  **Then** it copies the bundled template into `~/.config/the-robot-learns-kb/`, creating the expected directory structure (profiles, KB storage, session logs).

- **Given** the bootstrap process is copying template files
  **When** any file already exists at the destination
  **Then** it does not silently overwrite it and instead flags the conflict for my review.

- **Given** bootstrap completes successfully
  **When** I check `~/.config/the-robot-learns-kb/`
  **Then** I find a valid, non-empty environment ready for profile creation.
