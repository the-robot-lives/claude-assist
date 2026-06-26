---
id: US-774
title: "Enable Reduce Motion"
slug: enable-reduce-motion
personas: [P-008]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [accessibility, motion, animation, vestibular]
---

# US-774: Enable Reduce Motion

## User Story

**As an** accessibility-first user
**I want to** enable a reduce-motion setting
**So that** UI animations do not trigger vestibular discomfort or distract from content.

## Acceptance Criteria

- **Given** I open Accessibility Settings
  **When** I enable "Reduce Motion"
  **Then** all non-essential animations (slide transitions, reaction bursts, skeleton loaders) are replaced with instant cuts or simple fades.

## Notes
The setting also honours the OS-level reduce-motion preference if set, applying it automatically on first launch.
