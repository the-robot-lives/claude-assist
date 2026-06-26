---
id: US-694
title: "Channel Rule Violation Auto-Tagging"
slug: channel-rule-violation-auto-tagging
personas: [P-007]
epic: "Moderation & Reporting"
priority: could-have
complexity: medium
tags: [auto-moderation, channel-rules, tagging]
---

# US-694: Channel Rule Violation Auto-Tagging

## User Story

**As a** channel moderator
**I want to** have the system pre-select a likely violated rule when a new report arrives
**So that** I spend less time looking up rules and can focus on the decision itself

## Acceptance Criteria

- **Given** a new report arrives with a reason category of "Harassment"
  **When** the system matches the reason category against the channel's rule keywords
  **Then** the rule most likely violated is pre-selected in the triage form's "Rule violated" dropdown, highlighted as a suggestion (not a binding selection)

- **Given** I disagree with the auto-suggested rule
  **When** I open the dropdown
  **Then** I can select any other rule or "No specific rule" with equal ease and my override is what gets recorded

- **Given** the channel has no rules configured
  **When** a report arrives
  **Then** the auto-tag feature shows a prompt suggesting the mod set up channel rules for better future auto-tagging

## Notes
Auto-tagging is a suggestion only and must never prevent a mod from choosing a different rule or no rule.
