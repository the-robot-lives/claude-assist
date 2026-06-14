# Project Layout — Summary

```
my-knowledge-base/
├── bin/                        # CLI launcher (robot-learns.js)
├── quiz-app/                   # React quiz SPA (Vite)
│   └── src/components/         #   Question-type renderers
├── quiz-cli/                   # Terminal quiz runner
│   └── src/renderers/          #   Terminal renderers
├── schemas/                    # 9 YAML schema examples
├── template/                   # Bootstrapped agent environment
│   ├── CLAUDE.md               #   Agent brain
│   ├── knowledge/              #   Articles + indexes
│   ├── flashcards/             #   Anki-format decks
│   ├── quizzes/                #   Quiz defs + results
│   ├── simulations/            #   Scenarios + results
│   ├── projects/               #   Project assignments
│   └── sessions/               #   Session logs
├── docs/                       # Documentation
├── .gemini/                    # Gemini config
├── package.json                # npm: the-robot-learns
└── README.md
```
