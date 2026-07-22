---
id: US-001
title: "Ask a Calibrated Question"
slug: ask-a-calibrated-question
personas: [P-001, P-002, P-003]
epic: "Calibrated Q&A"
priority: must-have
complexity: high
tags: [query, calibration, expertise]
---

# US-001: Ask a Calibrated Question

## User Story

**As a** terminal-native developer
**I want to** ask a question via `/query` and receive an answer calibrated to my expertise level
**So that** I get the right depth without wading through fluff or missing critical context

## Acceptance Criteria

- **Given** a user profile with a domain expertise level set
  **When** I run `/query "<question>"` in that domain
  **Then** the answer's depth and terminology matches my recorded expertise level (e.g., no basic definitions for expert-level domains)

- **Given** no expertise level is recorded for the question's domain
  **When** I run `/query`
  **Then** the system defaults to an intermediate calibration and notes that the domain is unrated

- **Given** I run `/query` with a question
  **When** the answer is generated
  **Then** it is returned directly in the terminal without requiring additional confirmation steps

- **Given** my learning style preference is set (e.g., terse vs. example-driven)
  **When** `/query` answers
  **Then** the response format honors that style preference

## Notes
This is the foundational command underpinning the rest of the Calibrated Q&A epic.
