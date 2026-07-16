---
id: US-082
title: "Corrupted YAML File Is Quarantined With Clear Guidance"
slug: corrupted-yaml-quarantine
personas: [P-006, P-003]
epic: "Resilience & Errors"
priority: must-have
complexity: medium
tags: [error-handling, corruption, yaml, resilience]
---

# US-082: Corrupted YAML File Is Quarantined With Clear Guidance

## User Story

**As a** developer whose KB files can get corrupted by crashes, bad merges, or manual edits
**I want to** have any unparseable YAML file automatically quarantined with a clear explanation
**So that** one bad file never crashes my session or blocks access to the rest of my KB

## Acceptance Criteria

- **Given** a YAML file in my KB fails to parse on load
  **When** robot-learns encounters it
  **Then** that file is moved to a quarantine directory (not deleted), the session continues loading all other valid files, and no exception surfaces to crash the CLI

- **Given** a file was quarantined during this session
  **When** the session starts or I run a status check
  **Then** I see a plain-language summary: which file, what schema it was expected to match, the parse error line/column, and the quarantine path

- **Given** I've fixed the file manually
  **When** I run the restore-from-quarantine command
  **Then** robot-learns re-validates it and moves it back into the KB only if it now parses and matches its expected schema

- **Given** multiple files are corrupted in the same session
  **When** robot-learns reports on startup
  **Then** all of them are listed together rather than surfacing one-at-a-time across repeated crashes

## Notes
This is the baseline resilience guarantee the whole local-first architecture depends on — no single bad file should ever be fatal.
