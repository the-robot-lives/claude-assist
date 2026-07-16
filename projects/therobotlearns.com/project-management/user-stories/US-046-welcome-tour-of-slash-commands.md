---
id: US-046
title: "Welcome Tour of Slash Commands"
slug: welcome-tour-of-slash-commands
personas: [P-005, P-002]
epic: "Onboarding & Setup"
priority: should-have
complexity: low
tags: [onboarding, discoverability, help]
---

# US-046: Welcome Tour of Slash Commands

## User Story

**As a** user who just finished setup
**I want to** see a short welcome tour that introduces the six slash commands
**So that** I know what I can do next without hunting through documentation

## Acceptance Criteria

- **Given** `/setup` has completed successfully
  **When** the welcome tour starts
  **Then** each of the six slash commands is introduced with a one-line description of its purpose.

- **Given** I'm being shown the tour
  **When** a command is described
  **Then** I see a concrete example of when I'd use it (e.g., "/query when you have a quick question").

- **Given** I want to skip the tour
  **When** I dismiss it
  **Then** I can access the same information later via a help command.

- **Given** English is not my first language
  **When** the tour text is displayed
  **Then** it uses plain, simple phrasing rather than idioms or jargon.
