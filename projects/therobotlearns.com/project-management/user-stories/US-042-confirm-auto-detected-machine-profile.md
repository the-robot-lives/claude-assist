---
id: US-042
title: "Confirm Auto-Detected Machine Profile"
slug: confirm-auto-detected-machine-profile
personas: [P-001, P-003]
epic: "Onboarding & Setup"
priority: must-have
complexity: medium
tags: [onboarding, machine-profile, auto-detection]
---

# US-042: Confirm Auto-Detected Machine Profile

## User Story

**As a** developer with a specific toolchain
**I want to** have the setup process auto-detect my OS, installed tools, and versions and show me the results for confirmation
**So that** my KB and recommendations are grounded in my real environment instead of generic assumptions

## Acceptance Criteria

- **Given** `/setup` reaches the machine profile step
  **When** auto-detection runs
  **Then** it identifies my OS, shell, and a set of common developer tools with their installed versions.

- **Given** auto-detection completes
  **When** results are presented to me
  **Then** I can review the detected list and confirm, edit, or add entries before it is saved.

- **Given** a tool is installed but not detected (e.g., non-standard install path)
  **When** I review the list
  **Then** I can manually add it so the machine profile stays accurate.

- **Given** I confirm the machine profile
  **When** it is saved
  **Then** it becomes part of my environment and is referenced by later commands that give environment-specific guidance.
