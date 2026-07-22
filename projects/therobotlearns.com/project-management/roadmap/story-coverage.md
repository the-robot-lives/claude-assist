# Story Coverage & Traceability Matrix

Every user story is assigned to exactly one primary milestone/lane (see
[`00-overview.md`](00-overview.md)). A story appears in **Notes** when a second lane materially
supports it — the only kind of duplication this matrix records.

All 100 stories are roadmapped (100% coverage). One story is deliberately **not built** this
release: **US-080 — Publish to a Public Community Library** is prioritized `wont-have` in the
corpus; it is still assigned a home (M5 / L5.B) and tracked here, but M5's exit criteria
explicitly defer it. Nothing else is excluded.

Count check: M0=14, M1=18, M2=20, M3=14, M4=21, M5=13 → 100.

## M0 — Foundation & Onboarding

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-039 | Install and Launch via npm | must-have | Onboarding & Setup | L0.A Launcher & Distribution | |
| US-040 | Bootstrap Agent Environment on First Run | must-have | Onboarding & Setup | L0.B Agent Environment & Bootstrap | |
| US-041 | Guided User Profile Creation | must-have | Onboarding & Setup | L0.C Profiles, Schemas & Write Substrate | |
| US-042 | Confirm Auto-Detected Machine Profile | must-have | Onboarding & Setup | L0.C Profiles, Schemas & Write Substrate | |
| US-043 | Detect and Guide Missing Claude Code Install | must-have | Onboarding & Setup | L0.A Launcher & Distribution | |
| US-044 | Re-run Setup Without Destroying KB Data | must-have | Onboarding & Setup | L0.B Agent Environment & Bootstrap | |
| US-045 | Seed KB with Starter Topics During Onboarding | must-have | Onboarding & Setup | L0.B Agent Environment & Bootstrap | |
| US-046 | Welcome Tour of Slash Commands | should-have | Onboarding & Setup | L0.B Agent Environment & Bootstrap | |
| US-047 | Maintain and Switch Between Named Profiles | could-have | Onboarding & Setup | L0.B Agent Environment & Bootstrap | |
| US-048 | Cleanly Uninstall While Preserving KB Data | must-have | Onboarding & Setup | L0.A Launcher & Distribution | |
| US-055 | Telemetry Is Opt-In and Clearly Disclosed | must-have | Settings & Preferences | L0.C Profiles, Schemas & Write Substrate | |
| US-084 | Clear, Actionable Error When Claude Code Is Unavailable | must-have | Resilience & Errors | L0.A Launcher & Distribution | pairs with US-043 |
| US-085 | Disk-Full or Write Failure Never Corrupts the KB | must-have | Resilience & Errors | L0.C Profiles, Schemas & Write Substrate | atomic-write substrate for all writers |
| US-086 | Concurrent-Session Guard Prevents Two Sessions Clobbering the KB | must-have | Resilience & Errors | L0.A Launcher & Distribution | |

## M1 — Calibrated Q&A & Knowledge Base

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-001 | Ask a Calibrated Question | must-have | Calibrated Q&A | L1.A Query & Calibration Agent | |
| US-002 | Adapt Depth Per Domain | must-have | Calibrated Q&A | L1.A Query & Calibration Agent | |
| US-003 | Respect My Machine Profile | must-have | Calibrated Q&A | L1.A Query & Calibration Agent | consumes M0 machine-profile |
| US-004 | Auto-Save Query Answers to the KB | must-have | Calibrated Q&A | L1.B KB Store & Article Formatting | supports US-001 (persists answers) |
| US-005 | Cross-Link Related Articles | should-have | Calibrated Q&A | L1.B KB Store & Article Formatting | |
| US-006 | Suggest Adjacent Topics After a Query | should-have | Calibrated Q&A | L1.A Query & Calibration Agent | |
| US-007 | Format Articles Per Knowledge-Article Schema | must-have | Calibrated Q&A | L1.B KB Store & Article Formatting | realizes C-ARTICLE |
| US-008 | Browse a Knowledge Article from the Terminal | must-have | Calibrated Q&A | L1.C Terminal Viewer | |
| US-009 | Refresh a Stale Article | must-have | Calibrated Q&A | L1.A Query & Calibration Agent | |
| US-010 | Ask a Follow-Up Question with Context | must-have | Calibrated Q&A | L1.A Query & Calibration Agent | |
| US-011 | Record Every Q&A Session to a Log | must-have | Knowledge Base | L1.B KB Store & Article Formatting | |
| US-012 | Review Past Session Logs | should-have | Knowledge Base | L1.C Terminal Viewer | |
| US-013 | Tag and Categorize Knowledge Articles | should-have | Knowledge Base | L1.B KB Store & Article Formatting | |
| US-014 | Auto-Update the KB Index | must-have | Knowledge Base | L1.B KB Store & Article Formatting | part of C-ARTICLE |
| US-015 | Cite Sources in Generated Articles | must-have | Knowledge Base | L1.B KB Store & Article Formatting | |
| US-016 | Mark an Article as Verified | must-have | Knowledge Base | L1.B KB Store & Article Formatting | |
| US-017 | Override to Beginner Mode for a Single Query | should-have | Knowledge Base | L1.A Query & Calibration Agent | |
| US-018 | Save a Compare/Contrast Query as a Comparison Article | should-have | Knowledge Base | L1.B KB Store & Article Formatting | |

## M2 — Retention & Assessment

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-019 | Generate Flashcards From a Knowledge Article | must-have | Flashcards & Spaced Repetition | L2.A Flashcards & Spaced Repetition | consumes C-ARTICLE |
| US-020 | Daily SM-2 Review Queue | must-have | Flashcards & Spaced Repetition | L2.A Flashcards & Spaced Repetition | |
| US-021 | Grade Recall Per Card to Reschedule It | must-have | Flashcards & Spaced Repetition | L2.A Flashcards & Spaced Repetition | |
| US-022 | See Due-Card Counts Per Deck Before Reviewing | should-have | Flashcards & Spaced Repetition | L2.A Flashcards & Spaced Repetition | |
| US-023 | Organize Cards Into Topic Decks | must-have | Flashcards & Spaced Repetition | L2.A Flashcards & Spaced Repetition | |
| US-024 | Generate a Quiz on a Topic or Article | must-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | consumes C-ARTICLE |
| US-025 | Take a Quiz in the Terminal | must-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | |
| US-026 | Take a Quiz in the Browser SPA | could-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | SPA parity with US-025 |
| US-027 | Store Quiz Results and Identify Weak Areas | must-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | feeds US-036 plan adaptation |
| US-028 | Retake Only Missed Questions | should-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | |
| US-029 | Mix Question Types in a Quiz | should-have | Quizzes | L2.B Quizzes (Gen, CLI & SPA) | |
| US-030 | Run a Terminal Role-Play Simulation | must-have | Simulations & Projects | L2.C Simulations & Projects | |
| US-031 | Get a Graded Debrief After a Simulation | must-have | Simulations & Projects | L2.C Simulations & Projects | |
| US-032 | Request a Graded Project Assignment Matched to My Level | must-have | Simulations & Projects | L2.C Simulations & Projects | |
| US-033 | Submit a Project for Grader Agent Evaluation | must-have | Simulations & Projects | L2.C Simulations & Projects | |
| US-034 | Create a Learning Plan for a Goal | must-have | Learning Plans | L2.D Learning Plans | provides C-PLAN |
| US-035 | Track and Check Off Learning-Plan Milestones | should-have | Learning Plans | L2.D Learning Plans | |
| US-036 | Adapt My Plan Based on Performance Data | should-have | Learning Plans | L2.D Learning Plans | supported by L2.B (C-QUIZ) + L2.A (C-DECK) |
| US-037 | Get a Weekly Progress Summary | should-have | Learning Plans | L2.D Learning Plans | |
| US-038 | Resurface Decayed Topics Automatically | could-have | Learning Plans | L2.D Learning Plans | |

## M3 — Navigate & Tune

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-049 | Edit Per-Domain Expertise Levels | should-have | Settings & Preferences | L3.B Settings & Preferences | |
| US-050 | Set Learning-Style Preferences | should-have | Settings & Preferences | L3.B Settings & Preferences | |
| US-051 | Configure Local Preferences via Local-Preference Schema | should-have | Settings & Preferences | L3.B Settings & Preferences | uses C-SCHEMAS local-preference |
| US-052 | Choose a Visual Theme for the Quiz SPA | should-have | Settings & Preferences | L3.B Settings & Preferences | applies to L2.B quiz SPA |
| US-053 | Configure Review Cadence and Daily Card Limits | should-have | Settings & Preferences | L3.B Settings & Preferences | tunes L2.A review loop |
| US-054 | Set Default Verbosity for /query | could-have | Settings & Preferences | L3.B Settings & Preferences | tunes L1.A query |
| US-066 | Full-Text Search Across KB Articles | should-have | Search & Discovery | L3.A Search & Discovery | consumes C-ARTICLE |
| US-067 | Search Flashcards and Quizzes by Topic | should-have | Search & Discovery | L3.A Search & Discovery | consumes C-DECK, C-QUIZ |
| US-068 | Browse the KB by Tag/Category Tree | should-have | Search & Discovery | L3.A Search & Discovery | |
| US-069 | Ask 'What Do I Know About X' for a Synthesized Summary | must-have | Search & Discovery | L3.A Search & Discovery | |
| US-070 | Knowledge-Gaps Report: Adjacent Topics Not Covered | should-have | Search & Discovery | L3.A Search & Discovery | |
| US-071 | Related-Article Suggestions While Reading | could-have | Search & Discovery | L3.A Search & Discovery | |
| US-072 | Recently Added/Updated Articles Feed | should-have | Search & Discovery | L3.A Search & Discovery | |
| US-073 | Serendipity Mode: Resurface a Random Old Article | could-have | Search & Discovery | L3.A Search & Discovery | |

## M4 — Maintain, Harden & Scale

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-056 | Validate KB Files Against Their Schemas | should-have | KB Maintenance | L4.A KB Hygiene & Integrity | validates C-SCHEMAS/C-ARTICLE |
| US-057 | Rebuild index.yaml from Files on Disk | must-have | KB Maintenance | L4.A KB Hygiene & Integrity | |
| US-058 | Detect Duplicate Articles and Suggest Merges | should-have | KB Maintenance | L4.A KB Hygiene & Integrity | |
| US-059 | Prune or Archive Stale Articles | should-have | KB Maintenance | L4.A KB Hygiene & Integrity | |
| US-060 | View KB Stats and Growth Over Time | should-have | KB Maintenance | L4.A KB Hygiene & Integrity | |
| US-061 | Migrate KB on New Launcher Template Version | must-have | KB Maintenance | L4.B Backup, Restore & Migration | pairs with US-087 |
| US-062 | Automatic Pre-Migration Backup on Schema Changes | must-have | KB Maintenance | L4.B Backup, Restore & Migration | provides C-BACKUP |
| US-063 | Back Up the KB On Demand or On Schedule | should-have | KB Maintenance | L4.B Backup, Restore & Migration | |
| US-064 | Restore the KB from a Chosen Backup | should-have | KB Maintenance | L4.B Backup, Restore & Migration | |
| US-065 | Relocate the KB to a Custom Directory | could-have | KB Maintenance | L4.B Backup, Restore & Migration | |
| US-082 | Corrupted YAML File Is Quarantined With Clear Guidance | must-have | Resilience & Errors | L4.A KB Hygiene & Integrity | |
| US-083 | Resume an Interrupted Quiz or Simulation Session | must-have | Resilience & Errors | L4.C Resilience & Performance | consumes C-QUIZ |
| US-087 | Launcher-vs-Template Version Mismatch Is Detected With Guided Resolution | must-have | Resilience & Errors | L4.B Backup, Restore & Migration | |
| US-088 | Screen-reader-friendly terminal output | must-have | Accessibility & i18n | L4.D Accessibility & i18n | hardens L1.C terminal surface |
| US-089 | Quiz SPA meets WCAG 2.2 AA compliance | must-have | Accessibility & i18n | L4.D Accessibility & i18n | hardens L2.B quiz SPA |
| US-090 | Receive content in preferred language | should-have | Accessibility & i18n | L4.D Accessibility & i18n | |
| US-091 | Adjustable text size and high-contrast theme | must-have | Accessibility & i18n | L4.D Accessibility & i18n | |
| US-092 | Fast launcher startup | should-have | Performance & Scale | L4.C Resilience & Performance | |
| US-093 | KB scales to thousands of entries | should-have | Performance & Scale | L4.C Resilience & Performance | |
| US-094 | Token-frugal agent operations | should-have | Performance & Scale | L4.C Resilience & Performance | |
| US-095 | Incremental index updates | should-have | Performance & Scale | L4.C Resilience & Performance | optimizes C-ARTICLE index |

## M5 — Collaboration, Cloud & Integrations

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-074 | Export a Flashcard Deck or Article Bundle | should-have | Collaboration & Cloud | L5.A Sharing & Interchange | consumes C-DECK, C-ARTICLE |
| US-075 | Import a Shared Bundle with Conflict-Safe Merge | should-have | Collaboration & Cloud | L5.A Sharing & Interchange | |
| US-076 | Sync KB to a therobotlearns.com Cloud Account | could-have | Collaboration & Cloud | L5.B Cloud & Team | reuses C-BACKUP |
| US-077 | Shared Team Knowledge Base | could-have | Collaboration & Cloud | L5.B Cloud & Team | |
| US-078 | Team Lead Assigns Learning Plans to Team Members | could-have | Collaboration & Cloud | L5.B Cloud & Team | consumes C-PLAN |
| US-079 | Team Progress Dashboard for Leads | could-have | Collaboration & Cloud | L5.B Cloud & Team | |
| US-080 | Publish an Article or Deck to a Public Community Library | wont-have | Collaboration & Cloud | L5.B Cloud & Team | **deferred — not built this release** |
| US-081 | Resolve Merge Conflicts When a Shared or Synced KB Diverges | could-have | Collaboration & Cloud | L5.A Sharing & Interchange | supports US-075/US-076 |
| US-096 | Export flashcard decks to Anki | should-have | Integrations | L5.A Sharing & Interchange | consumes C-DECK |
| US-097 | Git integration for KB versioning | should-have | Integrations | L5.C Local Tooling Integrations | |
| US-098 | Expose the KB via an MCP server | should-have | Integrations | L5.C Local Tooling Integrations | exposes C-SEARCH |
| US-099 | Open any article in $EDITOR | could-have | Integrations | L5.C Local Tooling Integrations | |
| US-100 | Import existing external notes | could-have | Integrations | L5.A Sharing & Interchange | |

## Epic → milestone summary

| Epic | Milestone(s) |
|---|---|
| Calibrated Q&A | M1 |
| Knowledge Base | M1 |
| Flashcards & Spaced Repetition | M2 |
| Quizzes | M2 |
| Simulations & Projects | M2 |
| Learning Plans | M2 |
| Onboarding & Setup | M0 |
| Settings & Preferences | M0 (telemetry), M3 |
| KB Maintenance | M4 |
| Search & Discovery | M3 |
| Collaboration & Cloud | M5 |
| Resilience & Errors | M0 (launcher/write), M4 (recovery) |
| Accessibility & i18n | M4 |
| Performance & Scale | M4 |
| Integrations | M5 |
