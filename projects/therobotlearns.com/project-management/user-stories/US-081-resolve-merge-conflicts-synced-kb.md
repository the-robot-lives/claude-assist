---
id: US-081
title: "Resolve Merge Conflicts When a Shared or Synced KB Diverges"
slug: resolve-merge-conflicts-synced-kb
personas: [P-004, P-006]
epic: "Collaboration & Cloud"
priority: could-have
complexity: high
tags: [cloud, sync, merge-conflict, future]
---

# US-081: Resolve Merge Conflicts When a Shared or Synced KB Diverges

## User Story

**As a** user whose team KB or cloud-synced KB has diverged from another copy
**I want to** be walked through resolving merge conflicts item by item
**So that** I don't lose work or end up with inconsistent duplicated content across devices or teammates

## Acceptance Criteria

- **Given** the same item was edited independently on two synced copies
  **When** the next sync runs
  **Then** robot-learns detects the divergence by content hash and timestamp rather than silently picking one side

- **Given** a conflict is detected
  **When** I review it
  **Then** I see a diff of both versions and can choose keep-mine, keep-theirs, keep-both, or field-level merge, matching the resolution flow from US-075

- **Given** I am mid-resolution and something interrupts the session
  **When** I resume robot-learns
  **Then** unresolved conflicts are still flagged and pending, and no partial merge was silently committed

- **Given** I am an OSS tinkerer running an older launcher version against a newer synced schema
  **When** a conflict resolution touches a field my version doesn't recognize
  **Then** I'm warned the field will be preserved unmodified but not editable until I upgrade

## Notes
Future cloud scope, depends on US-076/US-077. Directly extends the local conflict UI introduced in US-075 rather than inventing a second mechanism.
