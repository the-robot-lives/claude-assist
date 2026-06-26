---
id: US-017
title: "Search and replay run history"
slug: run-history
personas: [P-003, P-002]
epic: "Operational Intelligence"
priority: could-have
complexity: low
tags: [search, debug, replay]
---

# US-017: Search and replay run history

## User Story

**As an** AI integrator  
**I want to** filter and replay prior runs  
**So that** I can reproduce issues quickly.

## Acceptance Criteria

- **Given** I search by message hash or workflow ID, **When** a result is selected, **Then** full inputs and outputs are restored in read-only replay mode.
- **Given** replay mode runs a copy, **When** I compare with current version, **Then** both outputs are stored as comparison artifacts.

