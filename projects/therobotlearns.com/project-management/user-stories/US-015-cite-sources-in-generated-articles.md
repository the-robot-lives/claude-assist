---
id: US-015
title: "Cite Sources in Generated Articles"
slug: cite-sources-in-generated-articles
personas: [P-001, P-008]
epic: "Knowledge Base"
priority: must-have
complexity: medium
tags: [citations, sources, trust]
---

# US-015: Cite Sources in Generated Articles

## User Story

**As a** privacy- and accuracy-conscious developer
**I want to** have generated articles cite their sources
**So that** I can verify claims and trust the knowledge base isn't quietly hallucinating

## Acceptance Criteria

- **Given** a `/query` answer draws on specific documentation, prior articles, or external references
  **When** the article is saved
  **Then** those sources are listed in the article per the knowledge-article schema

- **Given** an answer is generated primarily from the model's own reasoning without an external source
  **When** the article is saved
  **Then** it is labeled as such rather than fabricating a citation

- **Given** I view an article
  **When** I inspect its sources
  **Then** each cited source is specific enough to locate (e.g., doc title/version, not just "the internet")

## Notes
Particularly load-bearing for P-008, who works offline and needs to distinguish locally-verifiable sources from anything requiring network access.
