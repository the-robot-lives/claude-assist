---
id: US-066
title: "Password Reset Link Expiry"
slug: password-reset-link-expiry
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [password-reset, security, expiry]
---

# US-066: Password Reset Link Expiry

## User Story

**As a** cautious newcomer
**I want to** know that my password reset link expires after a short window
**So that** I am protected if the email is intercepted or delayed

## Acceptance Criteria

- **Given** a password reset link is generated
  **When** it is clicked more than 1 hour after generation
  **Then** I see an expiry message and a prompt to request a new link

- **Given** I successfully use a reset link
  **When** I or anyone else clicks the same link again
  **Then** it returns an invalid/already-used error
