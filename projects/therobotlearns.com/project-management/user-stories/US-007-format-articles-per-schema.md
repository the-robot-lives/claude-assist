---
id: US-007
title: "Format Articles Per Knowledge-Article Schema"
slug: format-articles-per-schema
personas: [P-001, P-006]
epic: "Calibrated Q&A"
priority: must-have
complexity: medium
tags: [doc-writer, schema, formatting]
---

# US-007: Format Articles Per Knowledge-Article Schema

## User Story

**As a** KB maintainer
**I want to** have the doc-writer sub-agent format saved articles per the knowledge-article YAML schema
**So that** every article is structurally consistent and machine-parseable

## Acceptance Criteria

- **Given** a `/query` answer is being saved
  **When** doc-writer formats it
  **Then** the resulting file validates against the knowledge-article YAML schema

- **Given** required schema fields are missing from the raw answer (e.g., tags, source)
  **When** doc-writer formats the article
  **Then** it infers or prompts for the minimum required fields before writing the file

- **Given** the schema is extended with a new field (e.g., by a custom user schema)
  **When** doc-writer formats an article
  **Then** it honors the extended schema without erroring

## Notes
Ties directly to the nine governing YAML schemas mentioned in the product brief.
