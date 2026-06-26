---
id: US-516
title: "Send Video or File in Chat"
slug: send-video-or-file-in-chat
personas: [P-002]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: high
tags: [media, video, file-sharing, chat]
---

# US-516: Send Video or File in Chat

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** share short videos and document files in channel chat
**So that** I can distribute topic-relevant resources without leaving the platform

## Acceptance Criteria

- **Given** I attach a video file (MP4, MOV) under 100 MB
  **When** the message is sent
  **Then** the video displays as an inline player with playback controls in the thread

- **Given** I attach a non-media file (PDF, ZIP, etc.) under 50 MB
  **When** the message is sent
  **Then** the file appears as a named attachment card with file type icon, size, and a download button

- **Given** an upload exceeds the allowed size limit
  **When** I try to attach it
  **Then** I see an in-line error and the upload is blocked before transmission

## Notes
Video playback should be lazy-loaded; channel chat should not auto-play video with audio.
