# How to: find out which queue file a memo can land in

**Goal:** know the full catalog of JSONL targets under
`llm.queueBasePath` (default `~/personal-development/queue/`) that the LLM
classifier can route a memo into.
**Prereqs:** none — this is a static, code-defined manifest
(`src/queue/manifest.rs`), identical to the macOS app's.

## Top-level

| File | Contents |
|---|---|
| `tasks.jsonl` | Actionable tasks with clear completion criteria |
| `todo.jsonl` | Short-term to-do items and chores |
| `work-items.jsonl` | Professional/work-related items |
| `reminders.jsonl` | Time-sensitive reminders |
| `binlog.jsonl` | Raw activity log entries, observations, stream-of-consciousness |

## `ideas/`
`agents` · `applications` · `blogging` · `books` · `business-development` ·
`experiments` · `improvements` · `mobile` · `papers` · `products` · `prompts` ·
`research` · `sites` · `tools` · `utilities` · `videos`

## `knowledge-base/`
`references` (links/resources to catalog) · `subjects` (areas to explore/document)

## `learning-plan/`
`goals` (objectives/milestones) · `smart` (SMART-formatted goals)

## `personal-development/`
`questions` (open questions to investigate) · `study` (study items, flashcard seeds, drill topics)

## `writing/`
`ideas` · `inspiration` · `genres` · `reading-list` · `resources` · `subjects`

Every entry is one JSON object per line:
```json
{"ts":"2026-07-17T12:00:00Z","type":"task","text":"...","source":"voice","processed":false}
```

**Verify:** `tail -f ~/personal-development/queue/tasks.jsonl` while approving
a memo the LLM classified as a task.
**Gotchas:** the LLM picks the file automatically from memo content — you
can't dictate the target file by voice; if it consistently misclassifies,
adjust `systemPromptOverride` in `config.json` rather than editing the
manifest (the manifest is compiled-in, not user-editable without a rebuild).
