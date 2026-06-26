---
id: US-927
title: "Fast Profile Load for Large-Network Accounts"
slug: large-account-profile-load
personas: [P-003]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [profile, large-account, performance, pagination]
---

# US-927: Fast Profile Load for Large-Network Accounts

## User Story

**As a** social connector with thousands of mutuals and a long post history
**I want to** have my own profile and other high-follower profiles load quickly
**So that** large accounts are not second-class citizens with broken or slow-loading pages

## Acceptance Criteria

- **Given** I view a profile with 10,000+ mutuals and 500+ posts
  **When** the profile page loads
  **Then** the profile header and first page of posts (20 items) appear within 2 seconds

- **Given** the profile mutual count is very large
  **When** it is displayed
  **Then** the count is shown as a rounded figure ("12.4K") computed server-side rather than by counting client-side

## Notes
Never load all mutuals or posts at once. Paginate all collections from the profile page. Mutual count is a denormalized counter column, not a live COUNT query.
