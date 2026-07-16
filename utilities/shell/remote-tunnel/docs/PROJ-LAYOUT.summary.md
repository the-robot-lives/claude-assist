# Project Layout — Summary

Remote-tunnel utility scripts: reverse SSH (autossh) + ngrok TCP tunnels for reaching machines behind NAT.

```
remote-tunnel/
├── docs/                       # PROJ-LAYOUT.md + this summary
├── .gitignore                  # swap files, .env, .envrc.local
├── Makefile                    # install/uninstall symlinks → $(PREFIX) (~/bin)
├── ngrok-cron.sh               # cron guard: start ngrok when remote flag file exists
├── ngrok-nomachine.sh          # ngrok TCP tunnel; push address to remote file
└── revtunnel.sh                # persistent reverse SSH tunnel via autossh
```
