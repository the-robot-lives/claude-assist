---
id: US-054
title: "Set Default Verbosity for /query"
slug: set-default-verbosity-for-query
personas: [P-003, P-001]
epic: "Settings & Preferences"
priority: could-have
complexity: low
tags: [settings, query, verbosity]
---

# US-054: Set Default Verbosity for /query

## User Story

**As an** experienced engineer who wants quick answers most of the time
**I want to** set a default answer length/verbosity for `/query`
**So that** I don't have to specify it on every question

## Acceptance Criteria

- **Given** I open my `/query` settings
  **When** I choose a default verbosity (e.g., brief, standard, in-depth)
  **Then** subsequent `/query` calls use that length unless I override it inline.

- **Given** I override verbosity for a single `/query` call
  **When** I specify a different length as part of that call
  **Then** only that response uses the override; my default is unchanged for future calls.

- **Given** I haven't set a default verbosity
  **When** I use `/query` for the first time
  **Then** a documented standard default is used.

- **Given** my expertise level for the domain is high
  **When** `/query` generates a brief-verbosity answer
  **Then** it still omits only detail, not correctness — no oversimplification that would mislead.
