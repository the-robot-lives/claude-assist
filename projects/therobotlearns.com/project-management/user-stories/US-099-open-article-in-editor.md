---
id: US-099
title: "Open any article in $EDITOR"
slug: open-article-in-editor
personas: [P-001, P-006]
epic: "Integrations"
priority: could-have
complexity: low
tags: [editor, obsidian, markdown]
---

# US-099: Open Any Article in $EDITOR

## User Story

**As a** staff backend engineer who wants editor integration
**I want to** open any KB article directly in my $EDITOR
**So that** I can edit notes with my normal tools while keeping files Obsidian-compatible

## Acceptance Criteria

- **Given** an article identified by title or ID
  **When** the user runs the open command
  **Then** the article opens in the editor specified by the $EDITOR environment variable

- **Given** the article is markdown
  **When** it is saved after editing
  **Then** the file remains valid Obsidian-compatible markdown (front matter, wikilinks, and formatting preserved)

- **Given** $EDITOR is not set
  **When** the open command is run
  **Then** a sensible fallback editor is used or a clear error message is shown

## Notes
Obsidian compatibility here benefits tinkerers (P-006) who cross-use their vault with other tools.
