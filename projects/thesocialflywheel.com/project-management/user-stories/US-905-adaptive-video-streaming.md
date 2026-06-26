---
id: US-905
title: "Adaptive Video Quality Streaming"
slug: adaptive-video-streaming
personas: [P-009]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [video, adaptive-bitrate, hls, streaming, creator]
---

# US-905: Adaptive Video Quality Streaming

## User Story

**As a** creator whose video content is viewed across many device types
**I want to** have my uploaded videos streamed at adaptive bitrates matched to each viewer's connection
**So that** viewers on slow connections see a lower-quality stream instead of buffering spinners

## Acceptance Criteria

- **Given** a viewer has a connection below 2 Mbps
  **When** they play an in-feed video
  **Then** the player automatically selects the 480p rendition and upgrades quality if bandwidth improves

- **Given** a viewer's bandwidth drops mid-playback
  **When** the buffer runs low
  **Then** the player steps down to a lower rendition within 2 seconds without interrupting playback

## Notes
Serve HLS with at minimum 360p, 480p, and 720p renditions. Transcode on ingest via job queue. First-frame thumbnail must load before the HLS manifest.
