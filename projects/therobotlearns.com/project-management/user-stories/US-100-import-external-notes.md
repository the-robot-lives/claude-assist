---
id: US-100
title: "Import existing external notes"
slug: import-external-notes
personas: [P-006]
epic: "Integrations"
priority: could-have
complexity: medium
tags: [import, obsidian, migration]
---

# US-100: Import Existing External Notes

## User Story

**As an** OSS tinkerer who imports notes and builds on extension APIs
**I want to** import existing external notes (markdown files or an Obsidian vault) into the KB
**So that** I can migrate my existing knowledge into the-robot-learns-kb without starting from scratch

## Acceptance Criteria

- **Given** a directory of markdown files or an Obsidian vault path
  **When** the user runs the import command
  **Then** notes are converted into the KB's schema-compliant format

- **Given** imported notes contain Obsidian-specific syntax (wikilinks, tags, front matter)
  **When** imported
  **Then** that syntax is preserved or correctly mapped to the KB's conventions

- **Given** a large vault is imported
  **When** the import runs
  **Then** the KB index is updated to include the new content without requiring a manual rebuild

- **Given** a naming or schema conflict arises during import (e.g., duplicate titles)
  **When** detected
  **Then** the user is prompted or given a clear resolution strategy

## Notes
Complements US-097 (git) and US-099 (Obsidian-compatible markdown) for a coherent tinkerer workflow.
