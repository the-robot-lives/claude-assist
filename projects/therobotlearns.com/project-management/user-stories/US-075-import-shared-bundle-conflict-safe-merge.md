---
id: US-075
title: "Import a Shared Bundle with Conflict-Safe Merge"
slug: import-shared-bundle-conflict-safe-merge
personas: [P-002, P-004]
epic: "Collaboration & Cloud"
priority: should-have
complexity: high
tags: [import, merge, sharing, conflict-resolution]
---

# US-075: Import a Shared Bundle with Conflict-Safe Merge

## User Story

**As a** developer who receives a flashcard deck or article bundle from a teammate
**I want to** import it into my local KB without silently overwriting my own content
**So that** I can benefit from shared material while keeping my personal notes and progress intact

## Acceptance Criteria

- **Given** a teammate sends me a bundle exported via US-074
  **When** I run the import command against the bundle file
  **Then** robot-learns validates the manifest and schema version before touching my KB, refusing incompatible bundles with a clear message

- **Given** the bundle contains an item whose ID does not exist in my KB
  **When** I import
  **Then** the item is added as new content with no further action needed

- **Given** the bundle contains an item that collides with an existing item ID or near-duplicate content in my KB
  **When** I import
  **Then** robot-learns flags it as a conflict, shows both versions side by side, and prompts me to keep mine, keep theirs, keep both (renamed), or merge fields

- **Given** I choose to keep both or merge
  **When** the import finishes
  **Then** my SM-2 review history for pre-existing cards is preserved untouched and only the newly imported or merged fields are added

## Notes
This is the conflict-resolution groundwork later reused by US-081 for cloud-synced KB divergence.
