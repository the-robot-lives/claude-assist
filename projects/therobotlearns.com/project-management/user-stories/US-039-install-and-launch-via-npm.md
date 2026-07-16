---
id: US-039
title: "Install and Launch via npm"
slug: install-and-launch-via-npm
personas: [P-001, P-002, P-005]
epic: "Onboarding & Setup"
priority: must-have
complexity: low
tags: [installation, npm, cli]
---

# US-039: Install and Launch via npm

## User Story

**As a** developer setting up a new tool
**I want to** install `the-robot-learns` globally via npm and launch it with a single `robot-learns` command
**So that** I can start using my personal knowledge base without complex setup steps

## Acceptance Criteria

- **Given** Node.js and npm are installed on my machine
  **When** I run `npm i -g the-robot-learns`
  **Then** the package installs successfully and the `robot-learns` command becomes available on my PATH.

- **Given** the package is installed
  **When** I run `robot-learns` for the first time
  **Then** the launcher starts and detects that no agent environment exists yet at `~/.config/the-robot-learns-kb/`.

- **Given** I run `robot-learns --version` or `robot-learns --help`
  **When** the command executes
  **Then** I see the installed version and a summary of available commands.

- **Given** the install fails due to permission errors
  **When** npm reports the failure
  **Then** I receive a clear message suggesting a fix (e.g., use a Node version manager or npx) rather than a raw stack trace.

## Notes
Package name and launcher binary are fixed per product brief (`the-robot-learns` / `robot-learns`).
