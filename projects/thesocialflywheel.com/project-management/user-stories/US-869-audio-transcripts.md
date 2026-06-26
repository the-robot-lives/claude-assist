---
id: US-869
title: "Transcripts for Audio and Video Posts"
slug: audio-transcripts
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: high
tags: [transcripts, audio, video, wcag-2.2]
---

# US-869: Transcripts for Audio and Video Posts

## User Story

**As a** deaf or hard-of-hearing user
**I want to** have a downloadable or expandable transcript for every audio and video post
**So that** I can read the full content without relying only on captions

## Acceptance Criteria

- **Given** a video or audio post
  **When** I open the post detail
  **Then** a "Read transcript" button is available

- **Given** I click "Read transcript"
  **When** the panel opens
  **Then** the full transcript text is rendered as readable HTML with timestamps

- **Given** no transcript exists
  **When** I view the post
  **Then** the button reads "Request transcript" and submits a generation job

## Notes
Transcripts should be stored as structured data (paragraphs with start/end times) and rendered in an accessible collapsible panel using `<details>`/`<summary>` or an ARIA disclosure pattern; a plain-text download option should accompany the HTML view.
