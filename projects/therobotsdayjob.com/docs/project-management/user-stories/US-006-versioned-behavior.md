---
id: US-006
title: "Version robot behavior and compare outputs"
slug: versioned-behavior
personas: [P-003, P-005]
epic: "Model Governance"
priority: should-have
complexity: medium
tags: [versioning, compare, rollout]
---

# US-006: Version robot behavior and compare outputs

## User Story

**As an** AI integrator  
**I want to** create and compare behavior versions per robot  
**So that** I can evaluate output changes before full rollout.

## Acceptance Criteria

- **Given** I save a new behavior version, **When** I run a sample workload, **Then** outputs are marked with version metadata.
- **Given** two versions are available, **When** I request compare mode, **Then** side-by-side outputs and metrics are shown.

## Notes
Keep compare outputs tied to the same input set for fairness.

