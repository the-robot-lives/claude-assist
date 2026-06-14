# The Robot Learns

**Project ID:** TRL-KB
**Domain:** therobotlearns.com (future cloud service)
**Status:** Pre-development / Architecture

Agent-powered personal knowledge base and learning system.

**Distribution:** Shell script (`bin/robot-learns`) + npm package (`the-robot-learns`)

---

## Problem

Users accumulate knowledge across scattered sources with no system to retain, test, or surface it. There's no way to ask questions and get answers calibrated to your expertise level, build a growing personal knowledge base from those Q&A sessions, or track what you know vs. what you've forgotten.

## Solution

A local-first, Claude Code agent-powered knowledge system. The "backend" IS Claude Code — no server, no web app. A CLI launcher boots the agent environment in `~/.config/the-robot-learns-kb/`, which reads user profiles, searches existing knowledge, answers questions, and simultaneously builds documentation, flashcards, quizzes, and topic stubs.

## Architecture

```
robot-learns (CLI)
        |
        v
~/.config/the-robot-learns-kb/
+-- CLAUDE.md                  <- Agent brain
+-- user-profile.yaml          <- Expertise levels, learning style
+-- machine-profile.yaml       <- OS, tools, versions
+-- local-preference.yaml      <- Overrides, UI preferences
+-- learning-plan.yaml         <- SMART goals + checkpoints
+-- knowledge/                 <- Docs (hybrid hierarchy + index)
+-- flashcards/                <- Anki-format decks (SM-2)
+-- quizzes/                   <- Quiz definitions + results
+-- simulations/               <- Terminal role-play scenarios
+-- projects/                  <- Graded project assignments
+-- sessions/                  <- Session logs
        |
        v
.claude/agents/                .claude/commands/
+-- kb-doc-writer              +-- /knowledge-base-query
+-- kb-flashcard-generator     +-- /knowledge-base-learning-plan
+-- kb-topic-expander          +-- /knowledge-base-quiz
+-- kb-quiz-generator          +-- /knowledge-base-flashcard
+-- kb-grader                  +-- /knowledge-base-simulate
                               +-- /knowledge-base-setup
```

## Components

| Component | Description |
|-----------|-------------|
| **CLI launcher** | `bin/robot-learns` (shell) + `the-robot-learns` (npm). Bootstraps config dir, launches Claude Code. |
| **Template system** | `template/` dir copied to `~/.config/` on first run. Self-contained agent environment. |
| **6 slash commands** | query, learning-plan, quiz, flashcard, simulate, setup |
| **5 sub-agents** | doc-writer (sonnet), flashcard-generator (haiku), topic-expander (haiku), quiz-generator (sonnet), grader (sonnet) |
| **React quiz SPA** | Standalone single-HTML quiz runner. Vite + React, builds to one file. |
| **CLI quiz runner** | Terminal quiz via @inquirer/prompts. Same quiz format, no browser needed. |
| **9 YAML schemas** | Documented schemas for all data formats (schemas/*.example) |

## Design System

Four style guide directions live in `design/theme/`, each targeting the `@noizu/styleguide` engine. Preview with:

```bash
npx @noizu/styleguide serve ./design/theme/
# or from repo root:
./serve-project.sh therobotlearns.com
```

| Theme | Style | Accent | Font | Personality |
|-------|-------|--------|------|-------------|
| **Scholar** | Minimal Tech | Indigo `#6366F1` | Inter + JetBrains Mono | Precise, developer-focused, clean |
| **Atlas** | Editorial | Amber `#b45309` | Source Serif 4 + Fraunces | Typography-first, contemplative, authoritative |
| **Spark** | Consumer Playful | Violet `#8b5cf6` | Nunito + Fira Code | Friendly, vibrant, encouraging |
| **Deep Focus** | Nocturne | Teal `#14b8a6` | IBM Plex Sans + Mono | Immersive dark mode, calm intensity |

Each theme contains 4 YAML files (all that's needed — the engine derives ~300 CSS properties from these seeds):

```
design/theme/theme-{name}/
  style-guide.meta.yaml        # Identity and slug
  branding.yaml                # Brand intent, audience, tone
  style-guide.vars.yaml        # ~12 seed tokens (colors, fonts, radius)
  style-guide.color-modes.yaml # Light/dark surface/text/border values
```

## Related Services

| Service | Role |
|---------|------|
| therobotlearns.com | Cloud sync, shared KBs, team learning (future) |
| therobotwrites.com | Documentation generation; feeds into KB content |

## Usage

```bash
# From the monorepo (bin/ is on PATH via .envrc)
robot-learns                          # Launch agent in KB directory
robot-learns what is a zebra          # Ask a question directly

# Via npm (for distribution)
npx the-robot-learns
npx the-robot-learns how do I mount ntfs
```

First run bootstraps `~/.config/the-robot-learns-kb/` and walks through profile setup.
