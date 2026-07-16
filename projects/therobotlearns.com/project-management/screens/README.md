# Screens

20 screens extracted from the 100 user stories in `project-management/user-stories/`. The product is a **local-first, terminal/CLI agent tool** — most "screens" here are distinct terminal command surfaces (slash-command output), not web pages. Exactly one screen (`quiz-spa`) is a real browser page; two screens (`team-lead-dashboard`, `cloud-sync-and-account`) describe the therobotlearns.com cloud tier, which is still future/pre-development per the project README.

## Category Index

| Category | Screens |
|---|---|
| Calibrated Q&A | 01-query-and-answer |
| Knowledge Base | 02-knowledge-article-viewer, 04-session-log-viewer |
| Search & Discovery | 03-kb-browse-and-search |
| Flashcards & Spaced Repetition | 05-flashcard-decks-and-review |
| Quizzes | 06-quiz-generator-and-runner, 07-quiz-spa |
| Simulations & Projects | 08-simulation-room, 09-graded-projects |
| Learning Plans | 10-learning-plan-dashboard |
| Onboarding & Setup | 11-setup-wizard, 12-profile-manager |
| Settings & Preferences | 13-settings-and-preferences |
| KB Maintenance | 14-kb-maintenance-console, 15-backup-and-restore |
| Collaboration & Cloud | 16-import-export-and-sharing, 17-cloud-sync-and-account, 18-team-lead-dashboard |
| Resilience & Errors | 19-error-and-recovery-notices |
| Integrations | 20-integrations |

Note: the **Performance & Scale** epic (US-092 to US-095) has no dedicated screen by design — those four stories are non-functional requirements that live inside existing surfaces (launcher boot speed inside Setup Wizard, index/search scale and incremental updates inside KB Maintenance Console, token-frugal operation inside Query & Answer) rather than being a screen of their own.

## Type Legend

| Type | Meaning | Screens |
|---|---|---|
| Primary | Main feature screens | 13 (01–09, 14–17) |
| Dashboard | Progress/status overview screens | 2 (10, 18) |
| Settings | Configuration surfaces | 3 (12, 13, 20) |
| Modal | Interrupt/overlay pattern, not a destination | 1 (19) |
| Storyboard | Multi-step flow | 1 (11) |

## Full Index

| # | Screen | Type | Category | User Stories |
|---|--------|------|----------|---------------|
| 01 | Query & Answer | Primary | Calibrated Q&A | US-001, US-002, US-003, US-004, US-005, US-006, US-007, US-010, US-017, US-018, US-054, US-069, US-090, US-094 |
| 02 | Knowledge Article Viewer | Primary | Knowledge Base | US-008, US-009, US-013, US-015, US-016, US-071, US-099 |
| 03 | KB Browse & Search | Primary | Search & Discovery | US-066, US-067, US-068, US-070, US-072, US-073 |
| 04 | Session Log Viewer | Primary | Knowledge Base | US-011, US-012 |
| 05 | Flashcard Decks & Review | Primary | Flashcards & Spaced Repetition | US-019, US-020, US-021, US-022, US-023, US-038, US-096 |
| 06 | Quiz Generator & Runner | Primary | Quizzes | US-024, US-025, US-027, US-028, US-029, US-083, US-088 |
| 07 | Quiz SPA | Primary | Quizzes | US-026, US-052, US-089, US-091 |
| 08 | Simulation Room | Primary | Simulations & Projects | US-030, US-031 |
| 09 | Graded Projects | Primary | Simulations & Projects | US-032, US-033 |
| 10 | Learning Plan Dashboard | Dashboard | Learning Plans | US-034, US-035, US-036, US-037 |
| 11 | Setup Wizard | Storyboard | Onboarding & Setup | US-039, US-040, US-041, US-042, US-043, US-044, US-045, US-046, US-092 |
| 12 | Profile Manager | Settings | Onboarding & Setup | US-047, US-048 |
| 13 | Settings & Preferences | Settings | Settings & Preferences | US-049, US-050, US-051, US-053, US-055 |
| 14 | KB Maintenance Console | Primary | KB Maintenance | US-014, US-056, US-057, US-058, US-059, US-060, US-061, US-065, US-093, US-095 |
| 15 | Backup & Restore | Primary | KB Maintenance | US-062, US-063, US-064 |
| 16 | Import / Export & Sharing | Primary | Collaboration & Cloud | US-074, US-075, US-080, US-100 |
| 17 | Cloud Sync & Account | Primary | Collaboration & Cloud | US-076, US-077, US-081 |
| 18 | Team Lead Dashboard | Dashboard | Collaboration & Cloud | US-078, US-079 |
| 19 | Error & Recovery Notices | Modal | Resilience & Errors | US-082, US-084, US-085, US-086, US-087 |
| 20 | Integrations | Settings | Integrations | US-097, US-098 |

**Total: 20 screens.**

## Story Coverage

All 100 user stories (US-001–US-100) map to exactly one screen above; none are orphaned. Coverage was verified by cross-checking every ID in `project-management/user-stories/index.yaml` against the User Stories column in this table.
