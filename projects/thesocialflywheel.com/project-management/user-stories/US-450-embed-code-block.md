---
id: US-450
title: "Embed a formatted code block in a post"
slug: embed-code-block
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: low
tags: [markdown, code, formatting, developer]
---

# US-450: Embed a Formatted Code Block in a Post

## User Story

**As a** Creator
**I want to** embed a syntax-highlighted code block in my post
**So that** I can share code snippets readably with developer-focused communities

## Acceptance Criteria

- **Given** I use triple-backtick markdown with an optional language hint (e.g., ```python)
  **When** I preview the post
  **Then** the code block is rendered with monospace font and syntax highlighting for the declared language

- **Given** a post with a code block is published
  **When** recipients view it
  **Then** the code block renders with a "Copy" button that copies raw code to the clipboard

## Notes
Supported languages: JavaScript, TypeScript, Python, Elixir, Rust, Go, SQL, Bash, and generic plaintext.
