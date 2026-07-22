---
id: US-043
title: "Detect and Guide Missing Claude Code Install"
slug: detect-and-guide-missing-claude-code-install
personas: [P-005, P-002]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [onboarding, prerequisites, claude-code]
---

# US-043: Detect and Guide Missing Claude Code Install

## User Story

**As a** new user without Claude Code installed
**I want to** have robot-learns detect that Claude Code is missing and walk me through installing and authenticating it
**So that** I can get the tool working even though I didn't know it was a prerequisite

## Acceptance Criteria

- **Given** I run `robot-learns` and Claude Code is not installed or not on my PATH
  **When** the launcher checks prerequisites
  **Then** it clearly explains that Claude Code is required and why, instead of failing with a cryptic error.

- **Given** Claude Code is missing
  **When** I ask for help
  **Then** I am given step-by-step installation instructions appropriate to my detected OS.

- **Given** I have installed Claude Code but not authenticated it
  **When** the launcher rechecks prerequisites
  **Then** it detects the unauthenticated state and guides me through the login/auth step.

- **Given** Claude Code is installed and authenticated
  **When** I re-run `robot-learns`
  **Then** the prerequisite check passes and onboarding proceeds automatically.
