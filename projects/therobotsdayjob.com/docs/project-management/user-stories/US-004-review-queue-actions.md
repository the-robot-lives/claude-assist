---
id: US-004
title: "Review queue supports approve, revise, and escalate actions"
slug: review-queue-actions
personas: [P-005, P-002]
epic: "Human-in-the-Loop"
priority: must-have
complexity: low
tags: [review, queue, governance]
---

# US-004: Review queue supports approve, revise, and escalate actions

## User Story

**As a** quality gatekeeper  
**I want to** review each pending output with quick actions  
**So that** high-risk outputs do not ship without oversight.

## Acceptance Criteria

- **Given** I open a review item, **When** I choose **Approve**, **Then** the item is finalized and passed to the next configured destination.
- **Given** I choose **Revise**, **Then** the item returns to the originating robot with revision notes.
- **Given** I choose **Escalate**, **Then** the item is flagged and assigned to the selected human approver.

