---
id: US-016
title: "Mark an Article as Verified"
slug: mark-an-article-as-verified
personas: [P-001, P-003]
epic: "Knowledge Base"
priority: must-have
complexity: low
tags: [verification, trust, quality]
---

# US-016: Mark an Article as Verified

## User Story

**As a** developer who has tested advice in practice
**I want to** mark an article as verified/trusted after confirming it works
**So that** I can distinguish battle-tested knowledge from unconfirmed answers

## Acceptance Criteria

- **Given** I have applied an article's guidance successfully in practice
  **When** I mark it verified
  **Then** the article's status field is updated and the change is visible when browsing

- **Given** an article is marked verified
  **When** it is later refreshed due to staleness (US-009)
  **Then** the verified status is cleared or flagged for re-confirmation rather than silently carried over

- **Given** I filter or browse the KB
  **When** I filter by verified status
  **Then** only verified articles are returned

## Notes
None.
