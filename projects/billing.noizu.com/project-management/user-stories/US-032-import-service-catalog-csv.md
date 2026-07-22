---
id: US-032
title: "Import service catalog CSV"
slug: import-service-catalog-csv
personas: [P-002, P-005]
epic: "Projects and Service Catalog"
priority: could-have
complexity: medium
tags: [projects, catalog]
---

# US-032: Import service catalog CSV

## User Story

**As a** delivery or billing operator  
**I want to** bulk import service item definitions  
**So that** reuse consistent billing context

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the import service catalog csv flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
