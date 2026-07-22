# The Robot Learns

**Project ID:** TRL-KB
**Domain:** therobotlearns.com (cloud application)
**Status:** Pre-development / Architecture

Cloud knowledge and learning application with a local agent workspace.

**Distribution:** Shell script (`bin/robot-learns`) + npm package (`the-robot-learns`)

---

## Problem

Users accumulate knowledge across scattered sources with no shared system to retain, test, sync, or surface it across devices and teams. There's no way to ask questions and get answers calibrated to your expertise level, build a growing knowledge base from those Q&A sessions, or track what you know vs. what you've forgotten.

## Solution

A cloud-first, agent-powered knowledge and learning system. `therobotlearns.com` is the primary product surface for accounts, sync, shared KBs, team learning, dashboards, and integrations. The `robot-learns` CLI boots a local agent workspace in `~/.config/the-robot-learns-kb/` for developer workflows, offline capture, bulk import/export, and Claude Code-assisted content generation; it syncs that workspace with the cloud app when credentials are configured.

## Architecture

```
therobotlearns.com cloud app
        |
        v
cloud account / team KB / dashboards / sync API
        ^
        |
robot-learns (CLI workspace agent)
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
| **Cloud app** | Primary hosted product: accounts, synced KBs, shared team spaces, dashboards, cloud search, and API integrations. |
| **CLI launcher** | `bin/robot-learns` (shell) + `the-robot-learns` (npm). Bootstraps a local workspace, launches Claude Code, and syncs with the cloud API. |
| **Template system** | `template/` dir copied to `~/.config/` on first run. Local agent workspace contract used by the cloud sync client. |
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
| therobotlearns.com | Primary cloud app: accounts, sync, shared KBs, team learning |
| therobotwrites.com | Documentation generation; feeds into KB content |

## Usage

```bash
# From the monorepo (bin/ is on PATH via .envrc)
robot-learns                          # Launch agent in KB directory
robot-learns what is a zebra          # Ask a question directly
robot-learns --validate               # Validate workspace KB layout/contracts
robot-learns --rebuild-index          # Rebuild article indexes from disk
robot-learns --search linux           # Search articles, decks, and quizzes
robot-learns --what "async rust"      # Summarize saved knowledge on a topic
robot-learns --stats                  # Show KB counts
robot-learns --backup                 # Create a local backup directory
robot-learns --export kb-bundle.json  # Export articles and flashcard decks

# Via npm (for distribution)
npx the-robot-learns
npx the-robot-learns how do I mount ntfs
```

First run bootstraps a local workspace at `~/.config/the-robot-learns-kb/` and walks through profile setup. For production use, configure cloud credentials so that workspace syncs to therobotlearns.com.

Additional local flags cover roadmap maintenance and interchange flows:

```bash
robot-learns --view computing/learning-systems
robot-learns --logs
robot-learns --due
robot-learns --review-card flashcards/deck.yaml card-001 4
robot-learns --dedupe
robot-learns --prune 180
robot-learns --restore ~/.config/the-robot-learns-kb/backups/kb-...
robot-learns --anki flashcards/deck.yaml deck.tsv
robot-learns --notes ~/notes
robot-learns --git status
robot-learns --mcp
robot-learns --editor computing/learning-systems
```

Cloud sync defaults to a local mirror bundle:

```bash
robot-learns --cloud-sync ~/.cache/the-robot-learns-cloud
```

For a real therobotlearns.com-compatible endpoint, set:

```bash
export TRL_CLOUD_URL=https://therobotlearns.com
export TRL_CLOUD_TOKEN=<account-token>
robot-learns --cloud-sync
```

The client posts the local bundle to `POST $TRL_CLOUD_URL/api/kb/sync` with a bearer token.
