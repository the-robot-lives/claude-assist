---
id: US-050
title: "Give feedback on forecast accuracy"
slug: "forecast-accuracy-feedback"
personas: [P-004, P-006]
epic: "Forecasting & Resupply"
priority: "could-have"
complexity: "M"
tags: [forecasting, feedback, accuracy]
---

# US-050: Give feedback on forecast accuracy

## User Story

**As a** multi-store operator (P-004),
**I want to** see how accurate past reorder suggestions actually were, and mark ones that were clearly wrong,
**So that** I can build trust in the forecasting feature over time and help it improve instead of quietly ignoring it after a couple of bad calls.

## Acceptance Criteria

- [ ] Given a reorder suggestion was acted on (PO created and received), when enough time has passed to observe the outcome, then the dashboard shows a simple accuracy comparison — predicted days-to-empty vs. actual, predicted quantity vs. what was actually needed.
- [ ] Given a suggestion turned out badly wrong (e.g. massive overstock or a stockout despite following it), when I view that item's history, then I can flag the suggestion as "wrong" with an optional reason (e.g. "one-off bulk sale," "supplier was late"), distinguishing model error from external causes.
- [ ] Given a bookkeeper (P-006) reviews forecasting performance monthly, when they open the accuracy summary, then it's presented as a plain-language track record (e.g. "suggestions were within 20% of actual demand 78% of the time") rather than raw statistical output.
- [ ] Given accuracy feedback accumulates over time, when future reorder suggestions are calculated, then flagged "wrong" instances are excluded or down-weighted so isolated anomalies don't distort future forecasts.

## Notes

Closes the loop on [[US-045]] and [[US-049]] — without this, forecasting has no mechanism to earn merchant trust or self-correct. Lowest priority in the epic since it only becomes meaningful once the other forecasting stories have real usage history. Cross-epic: aggregate accuracy stats may also surface in Reporting (US-051–075).
