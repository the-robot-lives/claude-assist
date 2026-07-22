---
id: US-075
title: "Natural-Language Sales Query"
slug: "natural-language-sales-query"
personas: [P-002, P-001]
epic: "Reporting & Insights"
priority: "won't-have-yet"
complexity: "XL"
tags: [reporting, ai, later-phase]
---

# US-075: Natural-Language Sales Query

## User Story

**As a** market-stall owner (P-001),
**I want to** type or speak a plain question like "how much did I sell yesterday compared to last week" in Khmer,
**So that** I can get answers without learning how to navigate reports, filters, or date pickers.

## Acceptance Criteria

- [ ] Given the owner types or speaks a question in Khmer or English, when submitted, then the app returns a plain-language answer backed by the same underlying data as [[US-068]]/[[US-070]], not a hallucinated figure.
- [ ] Given the query maps to an ambiguous or unsupported request, when processed, then the app says so plainly and suggests the closest supported report rather than guessing.
- [ ] Given an answer is returned, when the owner wants detail, then they can tap through to the underlying report (e.g. [[US-068]] daily summary) that the answer was computed from.
- [ ] Given the feature is unavailable offline, when the owner is offline, then the app clearly states the query feature needs connectivity rather than failing silently.

## Notes

Explicitly won't-have-yet per the README's "later" framing for NL queries — this file exists to reserve the slot and scope for a future phase; decompose further (query parsing, KH-language NLU, answer-grounding safeguards) before estimating complexity for real. Depends on all other Reporting stories as its data backbone: [[US-068]], [[US-069]], [[US-070]], [[US-071]].
