---
id: US-024
title: "Delete or archive an agent safely"
slug: delete-or-archive-an-agent-safely
personas: [P-001, P-007]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [agent-lifecycle, archive, deletion, audit]
---

# US-024: Delete or Archive an Agent Safely

## User Story

**As a** solo staff engineer maintaining an agent roster
**I want to** archive an agent (retaining its history) or permanently delete it (purging its data), with clear guardrails against accidental loss
**So that** I can retire agents I no longer need without either cluttering my roster or accidentally destroying an audit trail I need to keep

## Acceptance Criteria

- **Given** I choose to archive an agent
  **When** the archive is confirmed
  **Then** the agent's processes across all assigned projects are terminated, it is removed from active channel membership and roster listings, but its versioned prompt history, cognition records, and turn history remain queryable for audit purposes

- **Given** I choose to permanently delete an agent instead of archiving
  **When** I confirm the deletion
  **Then** the system requires a distinct, harder confirmation step (e.g., typing the agent handle) and warns that this purges versioned content, cognition records, and turn history irreversibly, unlike archive

- **Given** an agent has open objectives/reminders or is mid-turn when archival is requested
  **When** the archive request is processed
  **Then** the in-flight turn is allowed to complete (or is safely checkpointed) and open objectives are flagged as orphaned rather than silently dropped

- **Given** a compliance reviewer needs historical data on an agent that was deleted
  **When** they search for it
  **Then** archived agents remain discoverable and auditable, while permanently deleted agents are not — reinforcing archive as the default-safe choice and delete as the deliberate exception

## Notes
Archive vs. delete distinction protects P-007's audit requirements while giving P-001 a way to declutter. Pairs with US-015 (suspend is temporary/reversible; archive is a lifecycle end-state; delete is destructive and rare).
