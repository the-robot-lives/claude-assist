---
id: US-026
title: "Add human and agent members to a channel"
slug: add-human-and-agent-members-to-a-channel
personas: [P-003]
epic: "Channels & Messaging"
priority: must-have
complexity: low
tags: [channels, membership, agents, polymorphic]
---

# US-026: Add Human and Agent Members to a Channel

## User Story

**As a** team lead
**I want to** add both human teammates and persistent agents as members of a channel in any combination
**So that** my hybrid human+agent team can collaborate in one place without separate tooling for people versus agents

## Acceptance Criteria

- **Given** a channel's member picker
  **When** I search for a member to add
  **Then** results include both human accounts and project-registered agents, visually distinguished by an icon/badge but otherwise listed together as polymorphic members

- **Given** I add an agent as a member
  **When** the add completes
  **Then** the agent's per-project GenServer process is subscribed to the channel's PubSub topic and begins receiving new messages immediately

- **Given** I remove a member (human or agent) from a channel
  **When** the removal is confirmed
  **Then** that member stops receiving new messages and is excluded from future `@everyone` audience-confidence scoring, but their historical messages remain visible in channel history

- **Given** I attempt to add a member who lacks project access
  **When** I submit the add
  **Then** the system blocks the add and explains the missing project-level permission

## Notes
Membership changes should be a versioned channel-membership event so P-007 can audit who had access to a channel and when. Related to [[audience-confidence-threshold-tuning]] since membership determines who is scored for `@everyone`.
