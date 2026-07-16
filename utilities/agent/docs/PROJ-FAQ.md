# PROJ-FAQ.md — utilities/agent (grouping directory)

Anticipated why/when/compared-to-what questions about the **grouping directory** itself —
picking between children, installing the group, and group-wide history. Child-internal
questions ("can `mallm` do X", "is `run-claude`'s proxy secure") live in each child's own
`docs/PROJ-FAQ.md` — linked from the table in [PROJ-HOWTO.md](PROJ-HOWTO.md#where-to-go-for-tool-specific-tasks).
See [PROJ-ARCH.md](PROJ-ARCH.md) for why the children are structured as peers, and
[PROJ-LAYOUT.md](PROJ-LAYOUT.md) for the directory map.

## Motivation

### Why seven separate tools instead of one unified "agent-tools" CLI?

Because they solve unrelated concerns with no shared runtime — sandboxing (`dangerously-safe`,
`claude-desktop-sandbox`), model routing (`run-claude`), skill management (`skill-manage`),
CLI documentation (`mallm`), transcript indexing (`claude-assist`), and media generation
(`media-tool`) don't call each other at runtime and don't share state. Forcing them into one
binary would mean one Rust/TS/Python monolith, one release cadence, and one failure domain
for problems that are genuinely independent. The cost is real: you install/learn seven
surfaces instead of one, and there's no single `agent-tools --help`.
→ *See [PROJ-ARCH.md](PROJ-ARCH.md#system-view) for the "peers, not layers" system diagram.*

### Why reach for `skill-manage` instead of just symlinking into `~/.claude/skills` myself?

Because hand-symlinking only fixes one harness at a time and forgets itself the moment you
add a second provider — `skill-manage` tracks a catalog and bundle state so re-enabling for
Codex or another install root is a repeat of the same command, not a fresh round of manual
symlinks per skill per harness. The trade-off: you're trusting its catalog/bundle bookkeeping
instead of a directory listing you can `ls` yourself, and a sandboxed environment with its
own `$HOME` still needs its own catalog or a bind-mount (see the Comparison entry below).
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-keep-the-same-skill-set-enabled-across-every-harness-you-use).*

### Why use `mallm` instead of just relying on a tool's raw `--help` output?

Because raw `--help` text is unstructured and inconsistent across tools, forcing an agent to
re-parse a different format every time; `mallm` gives it a structured, validated YAML entry
(usage/arguments/subcommands/context) it can query the same way for every CLI you've
documented. The cost is upfront authoring time — `mallm init` + filling in the schema — so it
only pays off for tools you or your agents touch repeatedly, not a one-off script you'll run
once.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-make-an-agent-friendly-reference-for-one-of-your-own-tools).*

### Why use `media-tool` instead of ad hoc one-off calls to an image/video/voice provider's API?

Because `media-tool` wraps a `.media.prompt` declarative file, quality-gated eval loops, and a
reusable FIM (find-in-media) library, so a generation you'll want to repeat or tune stays
reproducible instead of living in a throwaway curl command. If you genuinely need one image
once and will never revisit the prompt, a direct API call is less overhead — the declarative
file format only earns its keep across iteration or reuse.
→ *See [media-tool/docs/PROJ-HOWTO.summary.md](../media-tool/docs/PROJ-HOWTO.summary.md).*

### Why use `claude-assist` instead of grepping past conversation JSONL by hand?

Because transcript JSONL isn't meant for human reading — nested tool-call/result blocks and
one-line-per-event framing make raw `grep` output nearly unusable past a trivial search;
`claude-assist` parses that structure so search, edit, and convert-to-skill operate on actual
conversation turns. For a single quick keyword check in a small transcript, `grep` is still
faster to reach for — the tool earns its keep on larger or repeated transcript work.
→ *See [claude-assist/docs/PROJ-HOWTO.summary.md](../claude-assist/docs/PROJ-HOWTO.summary.md).*

### Why does this exist as a grouping directory instead of each tool living top-level under `utilities/`?

So cross-tool docs (which-tool-when, combined workflows like sandbox+routing) have one home
instead of being duplicated or omitted. The grouping buys a shared install fan-out (one
`Makefile`, one `make install-utilities` reaches all seven) and one place to document
workflows that span children — at the cost of an extra directory hop and the discipline of
never letting internals leak up into these group-level docs.
→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions) — "Grouping directory, not a project."*

## Fit

### Do I need all seven tools, or can I install just the one I want?

Just the one you want — nothing here requires the others. `cd utilities/agent/<child> && make install`
installs a single child; the group-level `make install` is a convenience fan-out, not a
dependency graph. The one exception is the combined sandbox+routing workflow, which
genuinely needs two children (`dangerously-safe` + `run-claude`) — see the HOWTO for that.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-every-agent-utility-in-one-shot).*

### I only need to sandbox agent runs — do I want `dangerously-safe` or `claude-desktop-sandbox`?

`dangerously-safe`, almost certainly — it isolates a **CLI agent + a fresh worktree**;
`claude-desktop-sandbox` isolates the **claude-desktop GUI app** (separate login/session,
bwrap not Docker). They share the word "sandbox" but nothing else in scope. If you're
running `claude`/Codex/OpenCode from a terminal, that's `dangerously-safe`; if you want two
logged-in claude-desktop windows side by side, that's `claude-desktop-sandbox`.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-pick-the-right-tool-for-the-job) decision table.*

## Comparison

### `run-claude` and `mallm` both touch "LLMs" — how are they different?

They don't overlap at all despite the family resemblance: `run-claude` routes an agent's
*outbound model traffic* (which provider/profile answers its API calls); `mallm` gives an
agent *structured docs about your own CLI tools* so it stops guessing at `--help` output.
One is a network proxy layer, the other is a documentation resolver — you could use both in
the same session and they'd never interact.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-pick-the-right-tool-for-the-job).*

### How does `skill-manage`'s enablement reach into a `dangerously-safe` or `claude-desktop-sandbox` environment?

It doesn't, automatically — both sandbox tools give the agent a different `$HOME` (container
or bwrap root), so host-side skill symlinks aren't visible inside. You either bind-mount the
shared skill source tree at sandbox creation or re-run `skill-manage` inside the sandbox
itself; there's no cross-boundary sync today.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-keep-the-same-skill-set-enabled-across-every-harness-you-use).*

## Capability

### Can I run a sandboxed agent whose model calls are also routed through `run-claude`?

Yes, but the routing has to be configured **before** entering the sandbox — `run-claude`
keys its directory-based routing off the host path, so if the sandbox mounts a worktree
*copy* rather than the original path, routing can silently miss. Route by the sandbox's
mounted path, or set the profile as the container's global default instead of per-directory.
→ *Full steps: [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-run-a-sandboxed-session-with-routed-model-traffic).*

## Caveats

### If I run a fully offline `dangerously-safe` sandbox, will `run-claude` routing still work inside it?

Not without an explicit allowance — `run-claude`'s routed traffic depends on its front proxy
pair (`:4443` front / `:4444` LiteLLM) being reachable from inside the sandbox's network
namespace, and a fully offline sandbox blocks exactly that by design. You have to punch a
specific hole for those ports/host when configuring the sandbox's network policy; there's no
way to get routed model traffic and a fully offline sandbox simultaneously without one.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-run-a-sandboxed-session-with-routed-model-traffic)
Gotchas, and `dangerously-safe/docs/PROJ-HOWTO.md` → "Allow the sandbox limited network access."*

### If `make install-utilities` reports success, does that mean all seven tools installed cleanly?

Not necessarily — the fan-out doesn't abort on a child failure; a child missing its build
dependency (no `cargo`, `pnpm`, or `uv`) prints a skip/error line for that child only and the
run continues. Always verify with `which claude-assist claude-sandbox agent-sandbox mallm
media-tool run-claude skill-manage` after a fresh install rather than trusting exit code 0
alone.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-every-agent-utility-in-one-shot) Verify/Gotchas.*

### This changelog says milestones, not dates I can predict — why no release schedule?

Because this is a monorepo grouping directory, not a versioned product — history is
recorded per meaningful batch of subtree work (a new child arriving, a cross-cutting docs
pass), not on a cadence. Per-child release/version history, if a child has its own, lives in
that child's own `CHANGELOG.md`; this file only tracks group-level milestones.
→ *See [CHANGELOG.md](../CHANGELOG.md).*

## Trust

### Does anything at the grouping level (the shared `Makefile`, this docs tree) touch secrets or send data anywhere?

No — the group level is pure documentation and a five-line Makefile fan-out; it holds no
credentials, makes no network calls, and has no state of its own. Any trust question about
API keys, transcripts, or telemetry is a **child-specific** question — see that child's own
`PROJ-FAQ.md` (e.g. `run-claude`'s proxy logging, `claude-assist`'s conversation storage,
`media-tool`'s provider API keys).
→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit) for the loose-coupling rationale.*
