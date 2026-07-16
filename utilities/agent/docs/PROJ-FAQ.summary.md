# PROJ-FAQ.summary.md — utilities/agent (grouping directory)

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers. Group-level
questions only (picking a tool, installing the group, cross-tool workflows, group history);
child-internal questions live in each child's own `PROJ-FAQ.summary.md` (linked from
[PROJ-HOWTO.md](PROJ-HOWTO.md#where-to-go-for-tool-specific-tasks)).

## Motivation
- Why seven separate tools instead of one unified "agent-tools" CLI?
- Why reach for `skill-manage` instead of just symlinking into `~/.claude/skills` myself?
- Why use `mallm` instead of just relying on a tool's raw `--help` output?
- Why use `media-tool` instead of ad hoc one-off calls to an image/video/voice provider's API?
- Why use `claude-assist` instead of grepping past conversation JSONL by hand?
- Why does this exist as a grouping directory instead of each tool living top-level under `utilities/`?

## Fit
- Do I need all seven tools, or can I install just the one I want?
- I only need to sandbox agent runs — do I want `dangerously-safe` or `claude-desktop-sandbox`?

## Comparison
- `run-claude` and `mallm` both touch "LLMs" — how are they different?
- How does `skill-manage`'s enablement reach into a `dangerously-safe` or `claude-desktop-sandbox` environment?

## Capability
- Can I run a sandboxed agent whose model calls are also routed through `run-claude`?

## Caveats
- If I run a fully offline `dangerously-safe` sandbox, will `run-claude` routing still work inside it?
- If `make install-utilities` reports success, does that mean all seven tools installed cleanly?
- This changelog says milestones, not dates I can predict — why no release schedule?

## Trust
- Does anything at the grouping level (the shared `Makefile`, this docs tree) touch secrets or send data anywhere?
