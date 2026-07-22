---
id: US-013
title: "Tag and Categorize Knowledge Articles"
slug: tag-and-categorize-knowledge-articles
personas: [P-001, P-006]
epic: "Knowledge Base"
priority: should-have
complexity: low
tags: [tagging, categorization, organization]
---

# US-013: Tag and Categorize Knowledge Articles

## User Story

**As a** KB maintainer
**I want to** tag and categorize knowledge articles
**So that** I can organize and later filter my knowledge base by topic area

## Acceptance Criteria

- **Given** an existing article
  **When** I add or edit tags/category on it
  **Then** the change is persisted to the article's YAML frontmatter per the schema

- **Given** I browse the KB by a tag or category
  **When** I filter
  **Then** only matching articles are returned

- **Given** an article is auto-saved from `/query`
  **When** it is written
  **Then** it is auto-tagged based on the query's inferred topic, with the option for me to adjust the tags afterward

## Notes
None.
