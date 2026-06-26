---
id: US-968
title: "Export Personal Analytics as CSV"
slug: export-personal-analytics-as-csv
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: low
tags: [analytics, export, csv, portability]
---

# US-968: Export Personal Analytics as CSV

## User Story

**As a** Creator
**I want to** download my analytics summary as a CSV file
**So that** I can open it in a spreadsheet and perform my own analysis without needing to code

## Acceptance Criteria

- **Given** an authenticated Creator account
  **When** I click "Export CSV" in the analytics dashboard
  **Then** a CSV file downloads immediately with one row per post and columns for title, publish date, impressions, reactions, replies, and reach by degree

- **Given** a CSV export
  **When** I open it in a spreadsheet
  **Then** all date fields are in ISO 8601 format and all numeric fields are plain integers with no currency symbols

## Notes
CSV exports are generated synchronously for up to 1,000 posts; larger accounts trigger an async job with notification on completion.
