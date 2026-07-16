---
id: US-076
title: "Sync KB to a therobotlearns.com Cloud Account"
slug: sync-kb-to-cloud-account
personas: [P-001, P-008]
epic: "Collaboration & Cloud"
priority: could-have
complexity: high
tags: [cloud, sync, future, account, offline]
---

# US-076: Sync KB to a therobotlearns.com Cloud Account

## User Story

**As a** daily learner
**I want to** optionally sync my local KB to a therobotlearns.com cloud account
**So that** I can access my knowledge base and progress across multiple machines

## Acceptance Criteria

- **Given** I have a therobotlearns.com account
  **When** I opt in to cloud sync from robot-learns
  **Then** my KB's YAML/markdown files are synced to my account without altering the local-first file layout

- **Given** I have not opted in to cloud sync
  **When** I use robot-learns normally
  **Then** no network calls to therobotlearns.com are made and no account is required, ever

- **Given** I am a privacy-first user who never wants to see cloud prompts
  **When** I set an offline-only preference
  **Then** robot-learns permanently suppresses cloud sync prompts and account nudges for that installation

- **Given** sync is enabled and the network is unavailable
  **When** robot-learns attempts a sync
  **Then** it fails silently in the background and queues the sync for the next successful connection, never blocking local work

## Notes
Future scope — therobotlearns.com cloud does not exist in v1. This story documents the intended contract so v1's offline-only architecture doesn't need rework later. The offline opt-out (third criterion) must remain first-class for P-008 even after cloud ships.
