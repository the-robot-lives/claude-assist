---
id: US-056
title: "Validate KB Files Against Their Schemas"
slug: validate-kb-against-schemas
personas: [P-006, P-004]
epic: "KB Maintenance"
priority: should-have
complexity: medium
tags: [validation, schema, cli]
---

# US-056: Validate KB Files Against Their Schemas

## User Story

**As a** OSS tinkerer maintaining my own KB
**I want to** run a command that validates every YAML/markdown file against its governing schema
**So that** I catch malformed or drifted files before they break search, indexing, or agent queries

## Acceptance Criteria

- **Given** a KB with a mix of valid and invalid knowledge-article, flashcard-deck, and quiz files
  **When** I run the validation command
  **Then** I get a report listing each invalid file, the schema it violates, and the specific field-level errors

- **Given** all nine schema types (knowledge-article, index, flashcard-deck, quiz, simulation, learning-plan, user-profile, machine-profile, local-preference) are present in my KB
  **When** validation runs
  **Then** every file is checked against the correct schema based on its type, not just its location

- **Given** validation finds zero violations
  **When** the command completes
  **Then** I see a concise "KB is valid" confirmation with a count of files checked

- **Given** I only want to check one file or directory
  **When** I pass a path argument to the validation command
  **Then** only files under that path are validated

## Notes
Exit code should be non-zero on violations so it can be used in pre-commit hooks or CI for KB repos synced via git.
