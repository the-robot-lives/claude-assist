# Project Layout

```
my-knowledge-base/
├── bin/                            # CLI launcher
│   └── robot-learns.js             #   Entry point — bootstraps agent environment
├── quiz-app/                       # React quiz SPA (Vite + React, builds to single HTML)
│   ├── src/
│   │   ├── components/             #   Question-type renderers + results view
│   │   ├── App.tsx                 #   Quiz orchestrator
│   │   ├── main.tsx                #   Vite entry
│   │   ├── styles.css              #   Quiz styles
│   │   └── types.ts                #   Shared quiz types
│   ├── index.html                  #   SPA shell
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   └── tsconfig.node.json
├── quiz-cli/                       # Terminal quiz runner (@inquirer/prompts)
│   ├── src/
│   │   ├── bin/
│   │   │   └── quiz.ts            #   CLI entry point
│   │   ├── renderers/             #   Terminal renderers per question type
│   │   ├── runner.ts              #   Quiz execution engine
│   │   └── types.ts               #   Shared types
│   ├── package.json
│   └── tsconfig.json
├── schemas/                        # YAML schema examples (9 formats)
│   ├── flashcard-deck.yaml.example
│   ├── index.yaml.example
│   ├── knowledge-article.yaml.example
│   ├── learning-plan.yaml.example
│   ├── local-preference.yaml.example
│   ├── machine-profile.yaml.example
│   ├── quiz.yaml.example
│   ├── simulation.yaml.example
│   └── user-profile.yaml.example
├── template/                       # Bootstrapped to ~/.config/the-robot-learns-kb/
│   ├── CLAUDE.md                   #   Agent brain — instructions for the KB agent
│   ├── knowledge/                  #   Knowledge articles (hybrid hierarchy + index)
│   │   └── index.yaml
│   ├── flashcards/                 #   Anki-format spaced repetition decks
│   │   └── _deck-index.yaml
│   ├── quizzes/                    #   Quiz definitions
│   │   └── results/                #     Score history
│   ├── simulations/                #   Interactive scenario definitions
│   │   └── results/                #     Simulation results
│   ├── projects/                   #   Learning plan project assignments
│   └── sessions/                   #   Session logs
├── docs/                           # Project documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   └── PROJ-LAYOUT.summary.md     #   Quick-reference tree
├── .gemini/                        # Gemini agent configuration
│   ├── config.yaml
│   └── styleguide.md
├── package.json                    # npm package: the-robot-learns
└── README.md                       # Project overview + architecture
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `~/.config/the-robot-learns-kb/user-profile.yaml` | Created on first run via `/knowledge-base-setup` |
| `~/.config/the-robot-learns-kb/machine-profile.yaml` | Created on first run via `/knowledge-base-setup` |

## Distribution

The npm package (`the-robot-learns`) ships:
- `bin/` — CLI launcher
- `template/` — Agent environment bootstrapped to user's config dir
- `quiz-app/dist/` — Pre-built quiz SPA
- `quiz-cli/dist/` — Pre-built terminal quiz runner
- `schemas/` — YAML schema documentation
