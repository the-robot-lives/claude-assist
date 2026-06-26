---
id: US-296
title: "Interest Queue Pagination"
slug: interest-queue-pagination
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [inbox, pagination, performance]
---

# US-296: Interest Queue Pagination

## User Story

**As a** Social Connector (P-003)
**I want to** load my interest inbox in pages
**So that** opening the inbox is fast even when I have many pending interests

## Acceptance Criteria

- **Given** I have more than 20 pending interests
  **When** I open the inbox
  **Then** the first 20 are loaded and a "Load more" button or infinite scroll triggers the next page

- **Given** I am on page 2 of my inbox and accept an interest
  **When** the acceptance is confirmed
  **Then** my scroll position is preserved and the accepted card animates out without reloading from page 1
