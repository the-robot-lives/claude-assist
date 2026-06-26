---
id: US-422
title: "Format post text with markdown"
slug: markdown-formatting
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [markdown, formatting, text, rich-text]
---

# US-422: Format Post Text with Markdown

## User Story

**As a** Creator
**I want to** use markdown syntax to format my post text
**So that** I can add emphasis, headings, lists, and code blocks to improve readability

## Acceptance Criteria

- **Given** I type markdown syntax (e.g., **bold**, *italic*, `code`)
  **When** I toggle the preview mode
  **Then** the rendered output is shown with correct formatting

- **Given** a post with markdown is published
  **When** recipients view it
  **Then** the formatted version is displayed in all clients that support rich text

## Notes
Supported: bold, italic, inline code, code blocks, unordered lists, blockquotes. No raw HTML allowed.
