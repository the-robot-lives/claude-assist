---
id: US-350
title: "System Prevents Harassing Content in Opposing-View Lane"
slug: system-prevents-harassment-in-lane
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, harassment, safety, moderation, automated]
---

# US-350: System Prevents Harassing Content in Opposing-View Lane

## User Story

**As a** cautious newcomer
**I want to** be protected by automatic safeguards that prevent harassing or personally targeted content from appearing in the Opposing-Views Lane
**So that** the lane fulfills its intent of respectful exposure and does not become a vector for harm

## Acceptance Criteria

- **Given** a post contains language patterns associated with personal attacks or harassment
  **When** the system evaluates it for lane eligibility
  **Then** the post is automatically withheld from all users' Opposing-Views Lanes and queued for human moderation review

- **Given** a post is auto-withheld
  **When** a moderator clears it as not harassing
  **Then** it becomes eligible for the lane; if the moderator confirms it as harassment, it is removed platform-wide

- **Given** the automated system makes a false positive and withholds a benign post
  **When** the author appeals
  **Then** the appeal routes to the moderation queue and is resolved within the SLA defined in platform policy

## Notes
The harassment detection system must not disproportionately target specific demographic groups or viewpoints. Bias auditing is required before launch.
