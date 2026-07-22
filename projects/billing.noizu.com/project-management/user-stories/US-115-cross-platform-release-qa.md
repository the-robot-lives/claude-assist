---
id: US-115
title: "Cross-platform release QA"
slug: cross-platform-release-qa
personas: [P-001, P-002, P-008, P-009]
epic: "Cross-Platform Apps"
priority: must-have
complexity: high
tags: [qa, release, platforms]
---

# US-115: Cross-platform release QA

## User Story

**As a** product owner  
**I want to** validate critical billing journeys across web, iOS, Android, and macOS before release  
**So that** platform-specific bugs do not break financial workflows

## Acceptance Criteria

- **Given** a release candidate is ready  
  **When** QA runs platform journey tests  
  **Then** account setup, invoice review, invoice send, payment status, export access, notifications, and deep links pass on every targeted platform

## Notes
Use TestFlight for iOS, Play internal testing for Android, notarized/test-signed macOS builds, and browser E2E for web.
