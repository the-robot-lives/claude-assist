---
id: US-147
title: "Personal data export"
slug: personal-data-export
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, identity, privacy, data-export]
---

# US-147: Personal Data Export

## User Story

**As a** cautious newcomer
**I want to** export my personal data including all profile content
**So that** I keep control of my information and can review exactly what the platform holds about me

## Acceptance Criteria

- **Given** I request a data export from my profile settings
  **When** the export is prepared
  **Then** I receive a machine-readable archive of my profile, interests, and connection data

- **Given** an export is still processing
  **When** I check its status
  **Then** I see progress and am notified when the download is ready

- **Given** my export is ready
  **When** I download it
  **Then** the link expires after a defined window to protect the data

## Notes
Supports data-portability and privacy-regulation obligations. Export excludes other members' private data.
