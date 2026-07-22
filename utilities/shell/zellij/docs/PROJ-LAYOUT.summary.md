# Project Layout — Summary

```
zellij/
├── bin/                        # Launchers → ~/.local/bin
│   ├── zj-claude               #   claude session per dir
│   ├── zj-codex                #   codex session per dir
│   ├── zj-panes                #   split current tab: claude|nvim|shell
│   ├── zj-tab                  #   add claude dev tab
│   └── zj-spawn                #   tab/pane-grid per subdir, any command
├── layouts/                    # KDL layouts → ~/.config/zellij/layouts
│   └── claude-dev.kdl          #   claude|nvim|shell layout
├── docs/                       # PROJ-LAYOUT.md + this summary
├── .gitignore
└── Makefile                    # make install
```
