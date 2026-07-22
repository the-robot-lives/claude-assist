# The Robot Learns Roadmap TODO

This queue follows roadmap dependency order. Work only moves forward when the prior contract is usable.

## M0 - Foundation & Onboarding

- [x] T0.A.1 - npm launcher and query pass-through.
- [x] T0.A.2 - Claude Code presence check with actionable guidance.
- [x] T0.A.3 - Concurrent session lockfile guard.
- [x] T0.A.4 - Uninstall path preserves KB data.
- [x] T0.B.1 - First-run template bootstrap and data directories.
- [x] T0.B.2 - Re-setup is non-destructive.
- [x] T0.B.3 - Starter KB topics.
- [x] T0.B.4 - Welcome tour of slash commands.
- [x] T0.B.5 - Named profile switching protocol.
- [x] T0.C.1 - Nine template schema examples.
- [x] T0.C.2 - Guided user and machine profile creation protocol.
- [x] T0.C.3 - Atomic write helper.
- [x] T0.C.4 - Telemetry opt-in disclosure.

## M1 - Calibrated Q&A & Knowledge Base

- [x] T1.A.1 - Calibrated `/knowledge-base-query` reads user and machine profiles.
- [x] T1.A.2 - Follow-up context and single-query beginner override.
- [x] T1.A.3 - Adjacent topics and stale article refresh.
- [x] T1.B.1 - Auto-save answers as schema-shaped articles and update `knowledge/index.yaml`.
- [x] T1.B.2 - Inline citations and verified flag.
- [x] T1.B.3 - Cross-links and compare/contrast articles.
- [x] T1.B.4 - Tags, categories, and per-run session logs.
- [x] T1.C.1 - Terminal article rendering.
- [x] T1.C.2 - Session log listing and viewing.

## M2 - Retention & Assessment

- [x] T2.A.1 - Generate flashcards from articles.
- [x] T2.A.2 - Daily SM-2 queue and grade/reschedule loop.
- [x] T2.A.3 - Due counts and topic decks.
- [x] T2.B.1 - Generate mixed-question quizzes from topics/articles.
- [x] T2.B.2 - Terminal quiz runner.
- [x] T2.B.3 - Single-file React quiz SPA build.
- [x] T2.B.4 - Store results, weak areas, and missed-only retakes.
- [x] T2.C.1 - Terminal role-play simulation and graded debrief.
- [x] T2.C.2 - Graded project request, submit, evaluate.
- [x] T2.D.1 - SMART learning plans and milestone tracking.
- [x] T2.D.2 - Adapt plans from quiz/review performance.
- [x] T2.D.3 - Weekly summaries and decayed-topic resurfacing.

## M3 - Navigate & Tune

- [x] T3.A.1 - Article full-text search and card/quiz topic search.
- [x] T3.A.2 - Tag/category browse and recent feed.
- [x] T3.A.3 - "What do I know about X" synthesis and gaps report.
- [x] T3.A.4 - Related suggestions and serendipity mode.
- [x] T3.B.1 - Edit domain expertise and learning style.
- [x] T3.B.2 - Local preferences and query verbosity.
- [x] T3.B.3 - Quiz SPA theme, review cadence, daily card limits.

## M4 - Maintain, Harden & Scale

- [x] T4.A.1 - Validate KB files and rebuild index.
- [x] T4.A.2 - Duplicate detection and stale prune/archive.
- [x] T4.A.3 - Stats/growth and corrupted YAML quarantine.
- [x] T4.B.1 - Template migration and pre-migration backup.
- [x] T4.B.2 - Backup and restore.
- [x] T4.B.3 - Relocate KB and detect template-version mismatch.
- [x] T4.C.1 - Resume interrupted quiz/simulation.
- [x] T4.C.2 - Fast startup and token-frugal agent operations.
- [x] T4.C.3 - Scale to thousands and incremental index updates.
- [x] T4.D.1 - Screen-reader-friendly terminal output.
- [x] T4.D.2 - Quiz SPA WCAG 2.2 AA pass.
- [x] T4.D.3 - Preferred language, text size, high contrast.

## M5 - Collaboration, Cloud & Integrations

- [x] T5.A.1 - Article/deck bundle export and Anki export.
- [x] T5.A.2 - Conflict-safe bundle import and merge resolution.
- [x] T5.A.3 - External notes import.
- [x] T5.B.1 - therobotlearns.com cloud sync client.
- [x] T5.B.2 - Shared team KB and plan assignment.
- [x] T5.B.3 - Team progress dashboard.
- [x] T5.B.4 - Community publish tracked as deferred/wont-have.
- [x] T5.C.1 - Git KB versioning.
- [x] T5.C.2 - KB MCP server.
- [x] T5.C.3 - Open article in `$EDITOR`.
