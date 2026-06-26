---
id: US-084
title: "Download Security Audit Log"
slug: download-security-audit-log
personas: [P-010]
epic: "Authentication & Security"
priority: could-have
complexity: low
tags: [audit-log, export, security]
---

# US-084: Download Security Audit Log

## User Story

**As a** skeptical switcher
**I want to** export my security audit log as a file
**So that** I can keep an offline record or share it with support when investigating an incident

## Acceptance Criteria

- **Given** I am viewing my Security Audit Log
  **When** I click "Export" and choose a date range
  **Then** a CSV or JSON file is generated and downloaded containing all security events in that range
