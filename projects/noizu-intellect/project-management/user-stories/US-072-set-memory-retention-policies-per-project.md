---
id: US-072
title: "Set memory retention policies per project"
slug: set-memory-retention-policies-per-project
personas: [P-006]
epic: "Memory & Knowledge"
priority: should-have
complexity: medium
tags: [memory, retention, admin, quotas]
---

# US-072: Set Memory Retention Policies Per Project

## User Story

**As a** self-hosting admin/SRE (Nadia Volkov)
**I want to** configure how long different classes of memory (short-term path sandboxes, distilled synthetic memories, raw reflection-patch memories) are retained per project
**So that** storage growth and vector-index size stay under control without an engineer manually pruning data

## Acceptance Criteria

- **Given** a project's memory settings
  **When** I set a retention period for a memory class (e.g. "distilled memories: keep 180 days," "path sandboxes: purge after run completion + 24h")
  **Then** the system enforces that period going forward via a background sweep, without requiring manual intervention

- **Given** a retention policy change on a project with existing older memories
  **When** the policy is saved
  **Then** I am shown how many existing records would be affected before the sweep runs, so I don't accidentally mass-delete data

- **Given** a project approaching a storage or vector-index quota
  **When** retention sweeps run
  **Then** the resulting freed space and record counts are reflected in the admin spend/health dashboard

## Notes
Path-sandbox retention interacts with [[US-067]] — winning-path memories are promoted (and thus exit the sandbox retention class) before the sandbox purge would otherwise apply to them. Losing-path sandboxes should already be gone immediately per [[US-067]], independent of this general policy.
