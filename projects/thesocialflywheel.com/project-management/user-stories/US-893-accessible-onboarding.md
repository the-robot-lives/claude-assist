---
id: US-893
title: "Accessible Onboarding for New Users"
slug: accessible-onboarding
personas: [P-004]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [onboarding, accessibility, cognitive-load, wcag-2.2]
---

# US-893: Accessible Onboarding for New Users

## User Story

**As a** Cautious Newcomer
**I want to** the onboarding flow to be fully keyboard and screen-reader accessible with plain-language explanations of abstract concepts
**So that** I can complete setup confidently without confusion about terms like "lanes," "degrees," or "moots"

## Acceptance Criteria

- **Given** I start the onboarding wizard
  **When** each step loads
  **Then** focus moves to the step heading and the screen reader announces the step number (e.g., "Step 2 of 5: Choose your interests")

- **Given** an abstract term like "moot" or "lane" is introduced on screen
  **When** I activate the adjacent info icon by keyboard
  **Then** an explanation tooltip opens, its text is announced by the screen reader, and my place in the wizard is not lost

- **Given** I complete onboarding
  **When** I land on the main feed for the first time
  **Then** a dismissible "Quick tips" panel is present, keyboard navigable, and announced via polite live region

## Notes
Onboarding steps must never auto-advance without user input. Each step should have a clearly labelled "Back" and "Next" button; no gesture-only progression.
