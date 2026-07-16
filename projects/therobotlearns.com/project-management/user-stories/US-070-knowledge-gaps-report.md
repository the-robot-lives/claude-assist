---
id: US-070
title: "Knowledge-Gaps Report: Adjacent Topics Not Covered"
slug: knowledge-gaps-report
personas: [P-003, P-002]
epic: "Search & Discovery"
priority: should-have
complexity: high
tags: [gap-analysis, recommendations]
---

# US-070: Knowledge-Gaps Report: Adjacent Topics Not Covered

## User Story

**As a** SRE/DevOps polymath tracking my knowledge across many tools
**I want to** get a report of adjacent topics related to what's in my KB that I haven't covered yet
**So that** I can direct my learning toward real gaps instead of guessing what to study next

## Acceptance Criteria

- **Given** my KB has solid coverage of a topic area
  **When** I run the gaps report for that area
  **Then** I see a list of closely related topics with no or minimal KB coverage, not unrelated suggestions

- **Given** a gap is identified
  **When** it's listed in the report
  **Then** it includes a brief reason it was flagged (e.g., "commonly paired with X, which you have 8 articles on")

- **Given** I'm a mid-level developer upskilling deliberately in one direction
  **When** I scope the gaps report to a specific topic or tag
  **Then** results stay focused on that area's neighborhood rather than the whole KB

- **Given** my KB is too sparse for meaningful gap inference
  **When** the report runs
  **Then** I'm told there isn't enough coverage yet to generate reliable gap suggestions

## Notes
Complements [[US-069]] — where "what do I know about X" summarizes coverage, this report points outward at what's missing.
