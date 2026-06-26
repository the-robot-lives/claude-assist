---
id: US-933
title: "Brotli and Gzip Compression on All API Responses"
slug: api-response-compression
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [compression, brotli, gzip, api, bandwidth]
---

# US-933: Brotli and Gzip Compression on All API Responses

## User Story

**As a** skeptical switcher on a metered mobile data plan
**I want to** have all API JSON responses compressed before transmission
**So that** my data usage is minimised without sacrificing any information

## Acceptance Criteria

- **Given** I make an API request from a client that sends `Accept-Encoding: br, gzip`
  **When** the server responds
  **Then** the response body is Brotli-compressed and `Content-Encoding: br` is returned

- **Given** I make an API request from a client that only supports gzip
  **When** the server responds
  **Then** the response body is Gzip-compressed with at least a 60% reduction in payload size for typical JSON responses

## Notes
Enable compression at the reverse-proxy/CDN layer to avoid blocking the app thread. Minimum size threshold: 1,400 bytes before compressing. Exclude already-compressed media content.
