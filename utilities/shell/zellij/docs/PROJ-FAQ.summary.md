# FAQ Summary

Question-only companion to [PROJ-FAQ.md](PROJ-FAQ.md). Use for a cheap
relevance check before reading the full answer.

## Motivation
- Why would I use these scripts instead of just typing `zellij` commands myself?
- Why prefill the agent command instead of just running it immediately?
- Why generate a temporary KDL layout instead of always using `layouts/claude-dev.kdl`?
- Why does the `fzf` picker start with every directory pre-selected instead of none?
- Why isn't this wired into `share/k8-lib` like most other Noizu utilities?

## Fit
- When should I reach for `zj-tab`/`zj-panes` instead of `zj-claude`?
- When is the static `claude-dev.kdl` layout the better choice over the `zj-*` scripts?
- When is `zj-spawn` the right tool instead of `zj-claude`/`zj-codex`?
- Is a workspace YAML always better than the `fzf` picker?

## Comparison
- How does `zj-codex` differ from `zj-claude`?
- How does `--cerebras`/`--zai` differ from `--claude-command`?

## Capability
- Can I use an AI provider other than Claude Code or Codex?
- Can I preview what would launch without actually opening a session?

## Caveats
- What happens if I select zero directories in the `fzf` picker?
- Why is my session name truncated / suffixed with something I didn't ask for?
- Is it safe to put secrets in a workspace YAML or a `zj-spawn` scratch command?
- Does a missing directory in my workspace YAML abort the whole launch?

## Trust
- Does this package read or touch anything from the wider Noizu infra (cluster, `.infra-config.yaml`, secrets)?
