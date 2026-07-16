---
id: US-063
title: "Back Up the KB On Demand or On Schedule"
slug: backup-kb-on-demand-or-schedule
personas: [P-008, P-001]
epic: "KB Maintenance"
priority: should-have
complexity: medium
tags: [backup, git, schedule]
---

# US-063: Back Up the KB On Demand or On Schedule

## User Story

**As a** privacy-first offline consultant with no cloud sync
**I want to** back up my entire KB on demand or on a schedule, either as a git commit or an archive
**So that** my local-only knowledge base is never one bad edit or disk failure away from being gone

## Acceptance Criteria

- **Given** my KB directory is a git repo
  **When** I run the backup command in git mode
  **Then** it stages and commits all changes with a generated message, without requiring me to write one manually

- **Given** I prefer file-based backups instead of git
  **When** I run the backup command in archive mode
  **Then** a timestamped compressed archive of the KB directory is written to a configured backup location

- **Given** I want backups to happen without remembering to trigger them
  **When** I configure a backup schedule (e.g., daily)
  **Then** backups run automatically at that interval and I can see a log of past runs

- **Given** a scheduled backup fails (e.g., destination unreachable)
  **When** the failure occurs
  **Then** I'm notified rather than the failure passing silently

## Notes
Archive mode is the primary path for offline/no-git setups; git mode is preferred when a repo is already in use. See [[US-064]] for the restore counterpart.
