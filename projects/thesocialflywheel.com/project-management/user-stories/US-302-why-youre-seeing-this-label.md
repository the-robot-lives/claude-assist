---
id: US-302
title: "Why You're Seeing This Label"
slug: why-youre-seeing-this-label
personas: [P-001]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, transparency, label]
---

# US-302: Why You're Seeing This Label

## User Story

**As a** bridge-builder
**I want to** see a clear inline label on each opposing-view post that names the shared interest that triggered it
**So that** I understand the specific topic connection rather than wondering why this person's post appeared

## Acceptance Criteria

- **Given** an opposing-view post appears in my lane
  **When** I view the post
  **Then** a label reads "Opposing view on [Interest Name]" directly beneath the author line

- **Given** I tap or click the label
  **When** the detail popover opens
  **Then** it explains that this person shares my interest in [Interest Name] but holds a different view on it

## Notes
Label text must be concise enough to scan at a glance; full explanation lives in the popover.
