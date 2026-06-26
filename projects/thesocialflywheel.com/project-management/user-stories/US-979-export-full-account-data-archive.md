---
id: US-979
title: "Export Full Account Data Archive"
slug: export-full-account-data-archive
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [data-portability, export, gdpr, privacy]
---

# US-979: Export Full Account Data Archive

## User Story

**As a** Creator
**I want to** download a complete archive of all my posts, profile data, analytics, and mutual list
**So that** I have a portable copy of my data and can satisfy my right to data portability.

## Acceptance Criteria

- **Given** any authenticated account
  **When** I request a data export from Settings > Privacy
  **Then** within 24 hours I receive an email and in-app notification with a link to download a ZIP archive.

- **Given** the downloaded ZIP
  **When** I open it
  **Then** it contains: profile.json, posts.json, analytics_summary.json, mutuals_list.json (usernames only), and a README.txt explaining the schema.

- **Given** a data export request already in progress
  **When** I request another
  **Then** the request is queued and I am informed the previous export must complete first.

## Notes

Export links expire after 7 days. Third-party user data is not included; mutuals_list.json contains only public usernames of accounts that have consented to inclusion. Compliant with GDPR Article 20.
