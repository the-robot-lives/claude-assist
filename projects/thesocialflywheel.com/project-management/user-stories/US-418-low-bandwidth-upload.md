---
id: US-418
title: "Upload media on a slow network"
slug: upload-media-slow-network
personas: [P-002]
epic: "Posting & Content Creation"
priority: should-have
complexity: high
tags: [low-bandwidth, upload, performance, resilience]
---

# US-418: Upload Media on a Slow Network

## User Story

**As a** Niche Enthusiast
**I want to** upload images and videos even on a slow or intermittent connection
**So that** poor network conditions don't prevent me from sharing content

## Acceptance Criteria

- **Given** I am on a connection below 1 Mbps
  **When** I attach an image
  **Then** the app automatically compresses the image to a reduced-quality version appropriate for the bandwidth

- **Given** an upload is in progress and network drops
  **When** connectivity is restored
  **Then** the upload resumes from the last successful byte without restarting

## Notes
Users can disable auto-compression if they prefer to wait for the full-quality upload.
