---
id: US-071
title: "Access a guarded admin console"
slug: guarded-admin-layout
personas: [P-003]
epic: "Admin Console"
priority: must-have
complexity: medium
tags: [admin, layout, guard, security, pbac]
---

# US-071: Access a guarded admin console

## User Story

**As a** site owner/admin
**I want to** reach an admin console that only admins can open
**So that** management surfaces are protected

## Acceptance Criteria

- **Given** I am an admin/owner
  **When** I navigate to `/app/admin`
  **Then** I see the admin layout with a sidebar and admin sections
- **Given** I am not an admin
  **When** I try to open `/app/admin`
  **Then** access is denied and I am redirected
- **Given** the admin guard is enforced
  **When** the admin flag is evaluated
  **Then** it reflects the real role (the RequireAdmin/schema gap is fixed)

## Notes
Depends on fixing `ForyouWeb.Plugs.RequireAdmin` / `:admin` schema gap so the
guard is not always false (plan Chunk A).
