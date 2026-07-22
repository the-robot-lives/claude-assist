---
id: US-097
title: "Git integration for KB versioning"
slug: git-integration-for-kb-versioning
personas: [P-008, P-006]
epic: "Integrations"
priority: should-have
complexity: medium
tags: [git, versioning, integration]
---

# US-097: Git Integration for KB Versioning

## User Story

**As a** privacy-first offline consultant
**I want to** version my KB with git and push it to a private remote
**So that** I have durable history and off-machine backup while keeping full control over hosting

## Acceptance Criteria

- **Given** the KB directory
  **When** git integration is enabled
  **Then** the KB is initialized as a git repo (or uses an existing one) with sensible default .gitignore entries

- **Given** changes are made to the KB (new/edited articles, cards, session logs)
  **When** the user commits
  **Then** the agent can generate commits, automatically or on demand, with meaningful messages

- **Given** a private git remote is configured
  **When** the user pushes
  **Then** the KB syncs to that remote without requiring any cloud service beyond what the user explicitly specifies

- **Given** the user works fully offline
  **When** no remote is configured
  **Then** local git versioning still functions correctly without error

## Notes
Supports Casey (P-006), whose OSS tinkering workflow also relies on git remotes.
