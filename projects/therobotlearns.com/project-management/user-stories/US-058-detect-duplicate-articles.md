---
id: US-058
title: "Detect Duplicate Articles and Suggest Merges"
slug: detect-duplicate-articles
personas: [P-004, P-001]
epic: "KB Maintenance"
priority: should-have
complexity: high
tags: [dedup, merge, curation]
---

# US-058: Detect Duplicate Articles and Suggest Merges

## User Story

**As a** engineering team lead curating a shared KB
**I want to** detect articles that substantially overlap or duplicate each other
**So that** I can merge them instead of leaving redundant, possibly conflicting entries

## Acceptance Criteria

- **Given** two articles cover near-identical topics with overlapping content
  **When** I run the duplicate-detection command
  **Then** both articles are flagged as a candidate pair with a similarity score and the overlapping sections highlighted

- **Given** a flagged duplicate pair
  **When** I request a merge suggestion for that pair
  **Then** I'm shown a proposed merged article combining the unique content from both, with conflicting statements called out rather than silently dropped

- **Given** I accept a merge suggestion
  **When** the merge is applied
  **Then** the source articles are archived (not deleted) and index.yaml is updated to point to the new merged article

- **Given** the KB has no meaningful duplicates
  **When** I run the duplicate-detection command
  **Then** I get a clear "no duplicates found" result rather than false-positive pairings

## Notes
Similarity detection should weigh topic/tags and semantic content, not just title string matching.
