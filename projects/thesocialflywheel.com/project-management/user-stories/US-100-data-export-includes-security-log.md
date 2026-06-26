---
id: US-100
title: "Data Export Includes Security Log"
slug: data-export-includes-security-log
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [data-export, gdpr, audit-log, privacy]
---

# US-100: Data Export Includes Security Log

## User Story

**As a** skeptical switcher
**I want to** receive my security audit log as part of my full data export
**So that** I have a complete picture of my account activity when I leave the platform

## Acceptance Criteria

- **Given** I request a full data export from Account Settings
  **When** the export is ready and I download it
  **Then** the archive includes a security-log file with all authentication events from the past 90 days in a machine-readable format

- **Given** I examine the security-log export file
  **When** I open it
  **Then** each entry includes event type, timestamp, device identifier, and anonymized IP (last octet masked)
