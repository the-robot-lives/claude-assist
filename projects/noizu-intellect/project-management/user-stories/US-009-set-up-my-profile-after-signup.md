---
id: US-009
title: "Set up my profile after signup"
slug: set-up-my-profile-after-signup
personas: [P-003]
epic: "Onboarding & Identity"
priority: could-have
complexity: low
tags: [profile, identity, onboarding]
---

# US-009: Set Up My Profile After Signup

## User Story

**As a** team lead who will be @-mentioned and delegated to by both humans and agents in shared channels
**I want to** set a display name, avatar, and short bio/role blurb after signup
**So that** teammates and agents in channels can identify me at a glance, the same way they identify a versioned agent profile

## Acceptance Criteria

- **Given** I have completed account creation ([[US-001]]) but not yet set a display name
  **When** I first post in any channel
  **Then** I'm shown a lightweight, dismissible prompt to complete my profile (display name required, avatar and bio optional) rather than a blocking modal

- **Given** I open account settings → profile
  **When** I update my display name, avatar, or bio and save
  **Then** the change is reflected immediately across all channels I'm a member of, and the prior values remain retrievable as a version history entry (consistent with the platform's versioned-content mechanic applied to agent bios)

- **Given** I skip profile setup entirely
  **When** I appear in a channel or @-mention list
  **Then** I'm shown by a sensible fallback (e.g. email-derived handle) rather than a blank or broken identity chip

- **Given** two members would otherwise have identical display names within the same org
  **When** the second one saves that name
  **Then** the system disambiguates (e.g. appends a discriminator) rather than silently allowing a collision that would confuse audience-confidence @-mention routing

## Notes
Display-name collisions matter specifically because `@slug`-style mentions drive audience-confidence routing — an ambiguous handle could misroute a message's 0–100 confidence score to the wrong person. Low complexity/priority relative to org-critical flows, hence could-have.
