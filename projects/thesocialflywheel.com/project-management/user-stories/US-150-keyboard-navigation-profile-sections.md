---
id: US-150
title: "Keyboard navigation through profile sections"
slug: keyboard-navigation-profile-sections
personas: [P-008]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, identity, accessibility]
---

# US-150: Keyboard Navigation Through Profile Sections

## User Story

**As an** accessibility-first member
**I want to** move through every profile section using only the keyboard
**So that** I can view and edit my profile without relying on a pointing device

## Acceptance Criteria

- **Given** I am on a profile page
  **When** I press Tab and arrow keys
  **Then** focus moves through all sections and controls in a logical, visible order

- **Given** a focused interactive element
  **When** I activate it with Enter or Space
  **Then** it responds the same as a click, with focus state clearly indicated

- **Given** a multi-section profile
  **When** I use skip or landmark navigation
  **Then** I can jump directly to a section without tabbing through every element

## Notes
Meets WCAG 2.1 keyboard-operable and focus-visible criteria; screen-reader landmarks back the skip navigation.
