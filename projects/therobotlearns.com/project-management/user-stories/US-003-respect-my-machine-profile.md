---
id: US-003
title: "Respect My Machine Profile"
slug: respect-my-machine-profile
personas: [P-003, P-001]
epic: "Calibrated Q&A"
priority: must-have
complexity: medium
tags: [machine-profile, environment-aware]
---

# US-003: Respect My Machine Profile

## User Story

**As an** SRE managing my own toolchain
**I want to** have `/query` answers respect my machine profile (OS, installed tool versions)
**So that** I'm not given advice for the wrong platform or an incompatible version

## Acceptance Criteria

- **Given** my machine profile records macOS and Docker 24.x
  **When** I ask a containerization question
  **Then** the answer uses macOS-appropriate commands and Docker 24.x-compatible syntax

- **Given** a tool referenced in my question is not present in my machine profile
  **When** `/query` answers
  **Then** it flags the tool as not detected and asks whether to proceed with generic guidance

- **Given** my machine profile is stale or missing
  **When** I run `/query`
  **Then** the system warns me and offers to refresh the machine profile before answering

## Notes
Machine profile is populated at bootstrap and should be periodically refreshable.
