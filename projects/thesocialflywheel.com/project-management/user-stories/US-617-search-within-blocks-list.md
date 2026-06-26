---
id: US-617
title: "Search Within Blocks List"
slug: search-within-blocks-list
personas: [P-003]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: low
tags: [safety, management, search]
---

# US-617: Search Within Blocks List

## User Story

**As a** social connector with a large network
**I want to** search by username within my blocks list
**So that** I can quickly find and manage a specific blocked account without scrolling through hundreds of entries

## Acceptance Criteria

- **Given** I am on the Blocked Users page with 50+ blocked accounts
  **When** I type a partial username in the search box
  **Then** the list filters in real time to matching entries

- **Given** a search returns no results
  **When** the list updates
  **Then** a message reads "No blocked users match '[query]'" with an option to clear the search

## Notes
Search is client-side for lists under 500; server-side for larger lists.
