---
id: US-018
title: "Save a Compare/Contrast Query as a Comparison Article"
slug: save-compare-contrast-as-comparison-article
personas: [P-002, P-006]
epic: "Knowledge Base"
priority: should-have
complexity: medium
tags: [comparison, query, article-type]
---

# US-018: Save a Compare/Contrast Query as a Comparison Article

## User Story

**As a** developer weighing two tools or approaches
**I want to** ask a compare/contrast question and have it saved as a comparison article
**So that** I can revisit the tradeoffs later without re-researching them

## Acceptance Criteria

- **Given** I ask a `/query` in the form "X vs Y"
  **When** the answer is generated
  **Then** it is structured around the specific dimensions compared (e.g., performance, ergonomics, ecosystem) rather than as an undifferentiated narrative

- **Given** the answer is saved
  **When** doc-writer formats it
  **Then** it is saved using a comparison-article structure/type distinct from a standard knowledge article, per the schema

- **Given** a comparison article references X and Y
  **When** it is saved
  **Then** it is cross-linked to any existing standalone articles about X and about Y individually

## Notes
Comparison articles may warrant their own schema variant among the nine governing YAML schemas.
