---
id: US-097
title: "Social Login Scope Transparency"
slug: oauth-scope-transparency
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [oauth, privacy, transparency, social-auth]
---

# US-097: Social Login Scope Transparency

## User Story

**As a** skeptical switcher
**I want to** see exactly which permissions Flywheel requests from my OAuth provider before I authorize
**So that** I can make an informed decision about what data I share

## Acceptance Criteria

- **Given** I click "Continue with Google"
  **When** I am shown the pre-authorization screen on Flywheel (before the redirect)
  **Then** I see a plain-language list of the data that will be requested (e.g., email address, profile name) and which is required vs optional

- **Given** I deny an optional permission on the OAuth provider
  **When** I am redirected back to Flywheel
  **Then** login succeeds and the optional feature is simply unavailable
