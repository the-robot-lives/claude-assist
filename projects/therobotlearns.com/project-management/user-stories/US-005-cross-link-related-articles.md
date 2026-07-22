---
id: US-005
title: "Cross-Link Related Articles"
slug: cross-link-related-articles
personas: [P-001, P-004]
epic: "Calibrated Q&A"
priority: should-have
complexity: medium
tags: [cross-linking, knowledge-graph]
---

# US-005: Cross-Link Related Articles

## User Story

**As a** developer building a personal KB over time
**I want to** have new articles automatically cross-linked to related existing articles
**So that** my knowledge base becomes a connected reference rather than isolated notes

## Acceptance Criteria

- **Given** an existing article on a closely related topic exists
  **When** a new article is saved
  **Then** the new article includes a reference to the related article, and the related article is updated to reference the new one

- **Given** no related articles exist yet
  **When** a new article is saved
  **Then** it is saved without broken or speculative links

- **Given** two articles are linked
  **When** I browse one article
  **Then** I can see the linked related articles listed

## Notes
Relatedness can be inferred from tags, topic similarity, or explicit references in the answer text.
