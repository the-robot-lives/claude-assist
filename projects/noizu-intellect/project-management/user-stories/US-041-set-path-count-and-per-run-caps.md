---
id: US-041
title: "Set path count and per-run caps"
slug: set-path-count-and-per-run-caps
personas: [P-001, P-009]
epic: "Parallel-Path Execution"
priority: must-have
complexity: medium
tags: [path-cap, budget, quota, cost-control]
---

# US-041: Set Path Count and Per-Run Caps

## User Story

**As a** budget hobbyist running Intellect on my own hardware and API keys
**I want to** set a maximum path count and a hard spend/turn cap before I launch a parallel-path run
**So that** an ambitious decomposition can't silently fan out into a bill I didn't approve

## Acceptance Criteria

- **Given** I have a default path cap and per-run token/dollar budget configured at the project level
  **When** the Planner proposes more paths than my cap allows
  **Then** launch is blocked with a clear message showing the requested count vs. the configured cap, and I must either raise the cap explicitly or trim the breakdown (US-040)

- **Given** I set a per-run cap (max paths, max turns per path, and/or max spend) at launch time, overriding the project default
  **When** I launch
  **Then** each path GenServer is created with that cap attached, and any path that would exceed its turn or spend cap pauses and requests confirmation rather than exceeding it silently

- **Given** a run is in flight and a path's spend is approaching its cap
  **When** the cap threshold (e.g. 90%) is crossed
  **Then** I receive a notification identifying the path and remaining budget before the hard stop occurs

- **Given** a run reaches its total run-level cap across all paths combined
  **When** the cap is hit
  **Then** remaining paths are paused (not killed) so I can inspect partial progress and decide whether to raise the cap and continue (see US-047)

## Notes
This is the primary lever for Rosa's persona (P-009): cost preview and caps are what make self-hosted parallel-path experimentation viable on a hobbyist budget. Caps should be settable both as a project-level default and per-run override so Devon's daily-driver usage isn't forced through a confirmation dialog every time.
