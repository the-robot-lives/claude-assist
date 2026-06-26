---
id: US-020
title: "Capture structured user feedback after review"
slug: feedback-loop
personas: [P-001, P-005, P-004]
epic: "Learning and Improvement"
priority: could-have
complexity: low
tags: [feedback, reinforcement, onboarding]
---

# US-020: Capture structured user feedback after review

## User Story

**As an** operations controller  
**I want to** capture concise feedback on every reviewed item  
**So that** I can tune behavior without rewriting whole prompts.

## Acceptance Criteria

- **Given** an item is reviewed, **When** I submit feedback, **Then** the system stores outcome, reason, and preferred revision style.
- **Given** feedback accumulates, **When** behavior tuning mode opens, **Then** the system surfaces clustered feedback signals.

