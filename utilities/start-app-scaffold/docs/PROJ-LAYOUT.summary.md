# Project Layout Summary — start-app-scaffold

```
start-app-scaffold/
├── bin/                          # Executable tools → ~/.local/bin
│   ├── init-proj-scaffold        #   New project from start-app template
│   ├── start-app-scaffold        #   Scaffold + provision an instance
│   ├── llm-merge-start-app       #   Stage scaffold, hand merge to LLM agent
│   └── build-start-app-tarball   #   Rebuild start-app.tar.gz template archive
├── lib/                          # Shared shell lib → ~/.local/share/start-app-scaffold
│   └── repo-root.sh              #   Repo-root resolver
├── docs/                         # Documentation
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
└── Makefile                      # test / install targets
```
