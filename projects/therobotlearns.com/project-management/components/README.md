# Components

25 reusable components extracted from the 20 screens in `project-management/screens/`. Because the product is CLI/terminal-first, most components are terminal output/interaction patterns rather than GUI widgets — "Size Variants" map to output density (inline line, compact block, expanded detail) rather than literal widget sizing, except where a component genuinely renders in the one browser screen (Quiz SPA).

## Category Index

| Category | Components |
|---|---|
| Data Display | 02-Citation List, 04-Expertise Level Badge, 09-Score / Results Summary, 13-KB Stat Tile, 20-Machine / Environment Profile Card |
| Cards & Tiles | 06-Flashcard, 07-Deck Summary Tile, 08-Quiz Question Card |
| Navigation & Layout | 03-Related Topics Chips, 11-Profile Selector, 12-Setup Step Indicator, 17-Tag / Category Tree |
| Input & Forms | 10-Theme Picker, 18-Search Input Bar, 21-Verbosity / Depth Slider, 25-Accessibility Toggle |
| Feedback & Indicators | 05-Progress Bar / Milestone Tracker, 14-Error / Warning Banner |
| AI-Specific | 01-Calibrated Answer Block, 22-Roleplay Transcript, 23-Project Rubric Feedback Block |
| Modals & Overlays | 15-Confirmation Prompt |
| Domain-Specific | 16-Diff / Merge Conflict Resolver |
| Tables & Lists | 19-Session Log Entry, 24-Backup / Restore Timeline |

## Full Index

| # | Component | Category | Used In (screen count) |
|---|-----------|----------|--------------------------|
| 01 | Calibrated Answer Block | AI-Specific | 2 |
| 02 | Citation List | Data Display | 3 |
| 03 | Related Topics Chips | Navigation & Layout | 3 |
| 04 | Expertise Level Badge | Data Display | 4 |
| 05 | Progress Bar / Milestone Tracker | Feedback & Indicators | 4 |
| 06 | Flashcard | Cards & Tiles | 2 |
| 07 | Deck Summary Tile | Cards & Tiles | 2 |
| 08 | Quiz Question Card | Cards & Tiles | 2 |
| 09 | Score / Results Summary | Data Display | 4 |
| 10 | Theme Picker | Input & Forms | 2 |
| 11 | Profile Selector | Navigation & Layout | 2 |
| 12 | Setup Step Indicator | Navigation & Layout | 1 |
| 13 | KB Stat Tile | Data Display | 4 |
| 14 | Error / Warning Banner | Feedback & Indicators | 3 |
| 15 | Confirmation Prompt | Modals & Overlays | 5 |
| 16 | Diff / Merge Conflict Resolver | Domain-Specific | 2 |
| 17 | Tag / Category Tree | Navigation & Layout | 2 |
| 18 | Search Input Bar | Input & Forms | 3 |
| 19 | Session Log Entry | Tables & Lists | 2 |
| 20 | Machine / Environment Profile Card | Data Display | 3 |
| 21 | Verbosity / Depth Slider | Input & Forms | 2 |
| 22 | Roleplay Transcript | AI-Specific | 1 |
| 23 | Project Rubric Feedback Block | AI-Specific | 1 |
| 24 | Backup / Restore Timeline | Tables & Lists | 1 |
| 25 | Accessibility Toggle | Input & Forms | 2 |

**Total: 25 components.** 21 are reused across 2+ screens; the remaining 4 (Setup Step Indicator, Roleplay Transcript, Project Rubric Feedback Block, Backup / Restore Timeline) are single-screen but kept for their complex, distinct interaction patterns — each screen's Key Components section in `project-management/screens/` cross-references back into this library, and every entry here is used by at least one documented screen.
