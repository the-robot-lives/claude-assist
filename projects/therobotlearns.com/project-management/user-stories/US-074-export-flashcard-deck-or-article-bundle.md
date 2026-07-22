---
id: US-074
title: "Export a Flashcard Deck or Article Bundle"
slug: export-flashcard-deck-or-article-bundle
personas: [P-002, P-004]
epic: "Collaboration & Cloud"
priority: should-have
complexity: medium
tags: [export, sharing, flashcards, articles, bundle]
---

# US-074: Export a Flashcard Deck or Article Bundle

## User Story

**As a** developer who studies with peers
**I want to** export a flashcard deck or article bundle from my local KB into a single shareable file
**So that** I can hand it to a teammate without giving them access to my entire knowledge base

## Acceptance Criteria

- **Given** I have a flashcard deck or KB article selected
  **When** I run the export command targeting that deck or article
  **Then** robot-learns packages the item and its dependencies (linked articles, media, SM-2 review metadata) into a single portable bundle file

- **Given** I export a bundle
  **When** the export completes
  **Then** the bundle is written as a self-contained YAML/markdown archive with a manifest listing schema version, item counts, and export timestamp

- **Given** I want to share only content, not my personal review history
  **When** I export with a "strip personal data" flag
  **Then** SM-2 scheduling state (ease factor, due dates, review counts) is omitted from the bundle while card content is preserved

- **Given** the export target directory does not exist or is not writable
  **When** I run the export command
  **Then** I get a clear error identifying the path problem before any partial file is written

## Notes
Bundles are the building block for US-075 (import) and are also the artifact a team lead could later push to a shared team KB (US-077, future cloud scope).
