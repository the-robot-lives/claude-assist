---
id: US-326
title: "Keyboard Navigation Within the Read-Only Lane"
slug: keyboard-navigation-read-only-lane
personas: [P-008]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, accessibility, keyboard, navigation, a11y]
---

# US-326: Keyboard Navigation Within the Read-Only Lane

## User Story

**As an** accessibility-first user
**I want to** navigate between opposing-view posts and access Save and Report actions using only my keyboard
**So that** the read-only lane is fully usable without a pointing device

## Acceptance Criteria

- **Given** I am in the Opposing-Views Lane
  **When** I press Tab
  **Then** focus moves sequentially through: post content, "Opposing view on [Interest]" label, Save button, Report button, then next post

- **Given** focus is on the Save button
  **When** I press Enter
  **Then** the post is saved and a toast announces "Post saved" to screen readers

## Notes
Skip links must allow jumping from lane header directly to the first post. Arrow-key navigation within a post group is a nice-to-have.
