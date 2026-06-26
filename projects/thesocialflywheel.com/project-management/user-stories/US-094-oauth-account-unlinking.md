---
id: US-094
title: "Unlink Social OAuth Account"
slug: oauth-account-unlinking
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [oauth, account-linking, social-auth]
---

# US-094: Unlink Social OAuth Account

## User Story

**As a** skeptical switcher
**I want to** remove a linked OAuth provider from my account
**So that** that provider can no longer be used to access my account

## Acceptance Criteria

- **Given** I have a password set and at least two login methods
  **When** I unlink an OAuth provider in Security Settings
  **Then** it is removed and future logins via that provider are rejected

- **Given** the OAuth provider is my only login method and I have no password set
  **When** I attempt to unlink it
  **Then** I am blocked and informed that I must set a password first
