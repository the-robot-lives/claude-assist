---
id: US-080
title: "Manage member roles and permissions"
slug: manage-member-roles-and-permissions
personas: [P-006]
epic: "Admin & Platform Ops"
priority: must-have
complexity: medium
tags: [roles, permissions, members]
---

# US-080: Manage Member Roles and Permissions

## User Story

**As a** self-hosting admin/SRE
**I want to** assign admin or user roles to org members and have permission enforcement follow that role everywhere
**So that** only trusted people can touch provider configuration, budgets, and other org-wide settings

## Acceptance Criteria

- **Given** I am an org admin
  **When** I change a member's role from user to admin (or vice versa)
  **Then** the change takes effect on that member's next request without requiring them to log out, and is recorded in the audit log ([[US-083]])

- **Given** a user-role member attempts to access provider config, budgets, or role management screens
  **When** they navigate to or call the API for those screens
  **Then** access is denied with a 403-equivalent and no admin-only data is returned in the response payload

- **Given** the last remaining admin in an org attempts to demote themselves to user
  **When** they submit the change
  **Then** the action is blocked so the org can never be left with zero admins

- **Given** a user-role member is a member of a channel or project
  **When** they perform in-channel actions (posting, @-mentioning agents, picking a path)
  **Then** those actions succeed normally — role restriction applies only to admin/ops surfaces, not day-to-day collaboration

## Notes
This is the least-privilege backbone for every other admin story in this epic — [[US-075]] through [[US-079]] and [[US-081]]/[[US-082]]/[[US-083]] should all be gated behind the admin role established here.
