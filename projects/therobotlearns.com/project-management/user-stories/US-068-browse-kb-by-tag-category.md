---
id: US-068
title: "Browse the KB by Tag/Category Tree"
slug: browse-kb-by-tag-category
personas: [P-004, P-005]
epic: "Search & Discovery"
priority: should-have
complexity: medium
tags: [browse, taxonomy, navigation]
---

# US-068: Browse the KB by Tag/Category Tree

## User Story

**As a** engineering team lead browsing and curating a team KB
**I want to** navigate the KB as a tag/category tree
**So that** I can explore what's there by topic structure instead of only via search queries

## Acceptance Criteria

- **Given** articles are tagged with one or more categories
  **When** I open the browse view
  **Then** I see a tree of categories and subcategories with article counts at each node

- **Given** I select a category node
  **When** it expands
  **Then** I see the articles filed under it, plus any subcategories nested beneath

- **Given** I'm a career-switcher junior dev exploring an unfamiliar domain
  **When** I browse without a search term in mind
  **Then** the tree structure alone is enough to discover what topics exist in the KB

- **Given** an article has multiple tags spanning different branches of the tree
  **When** I browse either branch
  **Then** the article appears under all its relevant categories, not just one

## Notes
Tree structure should derive from tag/category metadata already present in article front matter — no separate taxonomy file to maintain by hand.
