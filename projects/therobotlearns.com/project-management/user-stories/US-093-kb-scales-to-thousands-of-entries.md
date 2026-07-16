---
id: US-093
title: "KB scales to thousands of entries"
slug: kb-scales-to-thousands-of-entries
personas: [P-003]
epic: "Performance & Scale"
priority: should-have
complexity: high
tags: [performance, scale, indexing]
---

# US-093: KB Scales to Thousands of Entries

## User Story

**As an** SRE/DevOps polymath with a huge knowledge base
**I want to** have the KB scale to thousands of articles and flashcards without index slowdown
**So that** my learning workflow doesn't degrade as my KB grows

## Acceptance Criteria

- **Given** a KB containing thousands of articles and flashcards
  **When** index.yaml is read or queried
  **Then** lookup and search operations complete within latency comparable to a small KB

- **Given** the KB grows over time
  **When** new content is continually added
  **Then** query and search performance does not noticeably degrade

- **Given** a large KB
  **When** running a quiz session selection or SM-2 scheduling pass
  **Then** the operation completes without perceptible lag

## Notes
Should be validated with a synthetic KB benchmark (e.g., 5,000+ articles/cards) as part of definition of done.
