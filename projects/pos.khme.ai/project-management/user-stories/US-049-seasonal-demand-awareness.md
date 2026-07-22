---
id: US-049
title: "Account for seasonal and holiday demand"
slug: "seasonal-demand-awareness"
personas: [P-004, P-002]
epic: "Forecasting & Resupply"
priority: "could-have"
complexity: "M"
tags: [forecasting, seasonality, holidays]
---

# US-049: Account for seasonal and holiday demand

## User Story

**As a** multi-store operator (P-004),
**I want to** have reorder suggestions adjust ahead of known high-demand periods like Khmer New Year and Pchum Ben,
**So that** I'm not caught understocked during the busiest, most predictable sales windows of the year, when a plain trailing-average forecast would badly underestimate demand.

## Acceptance Criteria

- [ ] Given a built-in Cambodian holiday calendar (Khmer New Year, Pchum Ben, and other configurable dates), when a holiday is within a configurable lead window (default 14 days out), then reorder suggestions for historically holiday-sensitive categories (e.g. drinks, snacks, gifts) apply an uplift multiplier instead of the plain trailing average.
- [ ] Given last year's sales data exists for the same holiday, when the uplift is calculated, then it uses the shop's own historical spike for that period in preference to a generic default multiplier.
- [ ] Given a shop has no prior-year data (new shop, or new item), when a holiday approaches, then the system falls back to a modest default uplift and clearly labels the suggestion as "estimated, no history yet" so the owner knows to sanity-check it.
- [ ] Given an owner disagrees with a seasonal suggestion, when they adjust or dismiss it for a specific item, then that override is remembered as a signal for next year's calculation, feeding [[US-050]].

## Notes

Lowest-priority forecasting story since it depends on at least one full seasonal cycle of data to be useful, and a static holiday calendar can ship before any adaptive logic. Related: [[US-045]], [[US-050]].
