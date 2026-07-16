---
id: US-065
title: "Relocate the KB to a Custom Directory"
slug: relocate-kb-directory
personas: [P-008, P-006]
epic: "KB Maintenance"
priority: could-have
complexity: low
tags: [config, relocation, storage]
---

# US-065: Relocate the KB to a Custom Directory

## User Story

**As a** privacy-first offline consultant who wants my KB on an encrypted or separately-managed volume
**I want to** move my KB from the default `~/.config/the-robot-learns-kb/` location to a directory of my choosing
**So that** I control where my personal data physically lives

## Acceptance Criteria

- **Given** my KB currently lives at the default location
  **When** I run the relocate command with a new target path
  **Then** all files are moved to the new path and the launcher's local-preference config is updated to point there

- **Given** the target path doesn't exist or isn't writable
  **When** I attempt the relocation
  **Then** it fails before any files are moved and I get a clear reason why

- **Given** the relocation completes
  **When** I next start `robot-learns`
  **Then** it reads the KB from the new location automatically, with no manual path flags needed

- **Given** I want to move the KB back to the default location
  **When** I run the relocate command targeting the default path
  **Then** the same move-and-repoint behavior applies symmetrically

## Notes
Relocation should not silently leave a stale copy at the old path once the move is confirmed successful.
