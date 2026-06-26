---
id: US-535
title: "Send a Voice Message"
slug: send-a-voice-message
personas: [P-009]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: high
tags: [voice-message, media, chat, audio]
---

# US-535: Send a Voice Message

## User Story

**As a** Creator (P-009)
**I want to** record and send a short voice message in a DM or channel
**So that** I can communicate tone and personality that text alone cannot convey

## Acceptance Criteria

- **Given** I hold down the microphone icon in the compose area
  **When** I speak and release
  **Then** a voice message up to 3 minutes long is recorded and sent as an audio clip with waveform visualization and duration label

- **Given** a voice message is received
  **When** I tap the play button
  **Then** it plays inline with a scrubber bar; double-tapping the speed button toggles 1x / 1.5x / 2x playback

- **Given** I begin recording but change my mind
  **When** I slide my finger left (iOS) or tap the trash icon
  **Then** the recording is cancelled and discarded without sending

## Notes
Voice messages respect mute settings. Transcription (auto-generated text summary) is a future enhancement.
