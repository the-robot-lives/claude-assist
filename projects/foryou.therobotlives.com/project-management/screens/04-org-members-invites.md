# 04: Organization Members & Invites

| Field | Value |
|-------|-------|
| ID | SCR-04 |
| Type | settings |
| Category | Onboarding & Auth |
| User Stories | US-009, US-010, US-019 |

## Description
Manage who belongs to an organization/Service and their roles: invite by email,
assign roles, accept invitations, and remove members.

## Key Components
- DataTable — members list with roles and actions
- FormField — invitee email + role selector
- Button — invite / re-send / remove
- InlineAlert — invite status and permission messaging
- Badge — role indicator

## Interactions
- Invite a member with a role; re-send an existing invite
- Accept an invitation via link; change or remove a member's role
- Permission-gated actions hidden when unauthorized

## Navigation
- **From:** Service Settings (SCR-07); App Home (SCR-02)
- **To:** Service Overview (SCR-06)
