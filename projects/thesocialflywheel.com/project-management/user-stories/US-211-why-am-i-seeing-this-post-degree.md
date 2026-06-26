---
id: US-211
title: "Why Am I Seeing This Post — Degree"
slug: why-am-i-seeing-this-post-degree
personas: [P-006]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [transparency, feed, degrees]
---

# US-211: Why Am I Seeing This Post — Degree

## User Story

**As a** Quiet Consumer (P-006)
**I want to** tap a "Why am I seeing this?" option on any feed post and get a degree-based explanation
**So that** I understand how the author connects to me and why they appear in my feed

## Acceptance Criteria

- **Given** a post from a 2nd-degree mutual appears in my feed
  **When** I open "Why am I seeing this?"
  **Then** the explanation states the author's degree (e.g., "They are a 2nd-degree mutual — a mutual of [shared contact name]")

- **Given** a post from a 1st-degree mutual appears
  **When** I open "Why am I seeing this?"
  **Then** the explanation states "They are one of your direct mutuals" with no further chain required

## Notes
This explanation UI is distinct from — but should co-exist with — the interest-based explanation (US-212).
