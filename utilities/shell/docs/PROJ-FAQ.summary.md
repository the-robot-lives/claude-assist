# PROJ-FAQ.summary — utilities/shell

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md). Group-level
(cross-tool) questions only — each child's own FAQ covers that tool's
internals.

## Motivation
- Why is this eleven separate tools instead of one CLI with subcommands?
- Why do only two of these tools (`repo-lock`, `secret-bucket`) share a design contract, instead of all eleven?
- Why bother with `zellij` + `tabbing-on` + `auto-sudo` together instead of a plain terminal or tmux?

## Fit
- Should a new one-off script I wrote go in here, or somewhere else in the monorepo?
- I only need one of these eleven tools — do I have to install the whole group?

## Comparison
- I want a git/GitHub helper — how do I know which of the five git-adjacent tools to reach for?
- Why do both `direnv-config` and `secret-bucket` exist — doesn't one make the other redundant?

## Capability
- Can I run `repo-lock hook install` and `doc-pointers hook` (misc-git-utils) in the same repo without one clobbering the other?
- Can several agent sessions (Claude/Codex/human) actually share one checkout safely with these tools?

## Caveats
- If I skip the pre-commit hook install step, do the lock/lane tools still protect me?
- Is there any version pinning or compatibility matrix across these eleven tools?
- Isn't writing passwordless sudo entries for agent-run commands (`auto-sudo`) a security risk?

## Trust
- Does anything in this group read or touch `.infra-config.yaml`, the cluster, or deploy-time secrets?
