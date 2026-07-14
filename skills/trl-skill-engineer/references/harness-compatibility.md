# Harness Compatibility: Claude Code, Codex, Grok

Concrete per-harness requirements for the SKILL.md folder format, verified against each
harness's own native skill-creator tooling (Codex `.system/skill-creator`, Grok
`create-skill`) and primary docs (July 2026). All three implement the open **Agent Skills
spec** ([agentskills.io/specification](https://agentskills.io/specification.md), Anthropic-
originated; adopters include Codex, Gemini CLI, Copilot, Cursor, and ~30 more — xAI is absent
from the official adopter list but implements Claude-compatible reading). Same core anatomy —
a folder with a frontmatter'd SKILL.md plus optional `scripts/`, `references/`, `assets/` —
differing at the edges. Design to the common core; declare the deltas. Validate with
`skills-ref validate ./my-skill` (spec reference tool).

## Frontmatter Requirements

Open spec: `name` (required; 1–64 chars, `a-z0-9-`, no leading/trailing/consecutive hyphens,
**must match the directory name**), `description` (required; 1–1024 chars, what + when),
optional `license`, `compatibility` (env requirements), `metadata` (string map),
`allowed-tools` (experimental). Compliant runtimes ignore unknown keys — extras degrade
gracefully.

| Field | Claude Code | Codex | Grok |
|-------|------------|-------|------|
| `name` | Required, kebab-case, matches dir | Required, per spec | Required — its own tooling enforces 2–64 chars, `a-z0-9-`, alphanumeric ends, matches folder |
| `description` | Required — drives auto-trigger routing | Required — the ONLY routing signal; may be truncated when the skills list exceeds ~2% of context (~8,000 chars total), so stay well under 1024 chars | Required — drives auto-invocation; should name the slash command (e.g. "Use when the user runs /deploy-k8s") |
| `metadata.short-description` | Ignored (harmless) | Optional — UI label | Optional — UI label |
| `allowed-tools` | Supported (pre-approved tools) | **Not supported** — tool/permission config lives in `agents/openai.yaml` (`policy`, `dependencies.tools`) | Unverified — assume ignored |
| `license`, `compatibility` | Supported | Ignored/undocumented | Ignored/undocumented |

**Portable rule:** put nothing load-bearing outside `name` + `description`. Optional
`metadata.short-description` is understood by Codex and Grok and harmless on Claude.
Never rely on `allowed-tools` for safety on any harness — it is advisory and experimental.

## Discovery Paths & Install

| Harness | User scope | Project scope | Notes |
|---------|-----------|---------------|-------|
| Claude Code | `~/.claude/skills/<name>/` | `.claude/skills/<name>/` or repo `skills/` | Invocable as `/<name>`; does NOT scan `.agents/skills/` |
| Codex | `~/.agents/skills/` (documented) — `~/.codex/skills/` is legacy but still what `skill-installer` writes (openai/skills#420) | `.agents/skills/` walked from CWD up to repo root | `/etc/codex/skills` admin scope; `skills/.system/` reserved; explicit invoke `$skill-name` or `/skills` picker; per-skill toggle via `[[skills.config]]` in `~/.codex/config.toml`; duplicates shown side-by-side, symlinks OK |
| Grok | `~/.grok/skills/` — also reads `~/.agents/skills/` | `<repo>/.grok/skills/<name>/` walked to repo root | **Auto-reads `.claude/` assets zero-config** (skills, agents, CLAUDE.md family); reads AGENTS.md family; extra roots via `[skills] paths` in `~/.grok/config.toml`; auto-reloads on change; `grok inspect` shows discovery |

**Neutral repo location:** `.agents/skills/` at repo root is the closest thing to a
cross-harness path — Codex reads it natively and Grok reads the user-level equivalent —
but Claude Code doesn't scan it, so symlink into `.claude/skills/` for Claude. Avoid the
same skill name at multiple scopes: duplicate handling differs per harness (Codex shows
both; Claude Code project-over-user precedence).

In this monorepo, use **`skill-manage`** (`utilities/agent/skill-manage`) to enable/disable
skills per provider via symlinks from these roots into the canonical `skills/` source tree:

```bash
export SKILL_REPO=/path/to/Noizu/skills
skill-manage enable skills trl-skill-engineer --provider claude   # also: codex / grok
skill-manage audit skills --strict
```

Never hand-`cp` into provider roots; symlinks keep one canonical source.

> **Note:** skill-manage v1's Codex provider targets `~/.codex/skills/` — the legacy root.
> Codex's documented path is now `~/.agents/skills/` (legacy still honored; openai/skills#420
> tracks the tooling mismatch). Symlinks are accepted by Codex, so re-pointing the provider
> root is a config change, not a redesign.

## Harness-Specific Extras

### Codex: `agents/openai.yaml` (recommended)

Codex recommends a metadata/policy file per skill:

```
skill-name/
├── SKILL.md
└── agents/
    └── openai.yaml    # interface: display_name, short_description, default_prompt, icon,
                       #   brand color
                       # policy: allow_implicit_invocation (default true)
                       # dependencies: tools (MCP/tool requirements)
```

`interface` powers skill lists/chips in Codex UIs; `policy` and `dependencies.tools` are
Codex's replacement for `allowed-tools`-style frontmatter. Inert on Claude Code and Grok —
safe to ship in a portable skill. Generate it from SKILL.md content (display name = H1
title, short description ≤ the frontmatter description's first sentence, default_prompt =
the most common invocation). Keep it in sync when the description changes.

### Codex/Grok: instruction-file interplay

Codex layers `AGENTS.md` (root→CWD walk, concatenated) alongside skills and its docs let
AGENTS.md reference additional skills; its old custom-prompts mechanism (`~/.codex/prompts`)
is deprecated in favor of skills. Grok reads both the AGENTS.md family and the CLAUDE.md
family. Claude Code reads CLAUDE.md only. A portable repo should carry both `AGENTS.md` and
`CLAUDE.md` (or symlink one to the other).

### Codex: conciseness doctrine

Codex's authoring guidance is stricter than ours on token budget: "the context window is a
public good," "default assumption: the model is already very smart." Its degrees-of-freedom
model is worth adopting everywhere:

| Freedom | Use when | Form |
|---------|----------|------|
| High | Many valid approaches, context-dependent | Text instructions / heuristics |
| Medium | Preferred pattern, some variation OK | Pseudocode or parameterized scripts |
| Low | Fragile, must-be-exact sequences | Specific scripts, few parameters |

Also from Codex: if a reference file exceeds ~10k words, include grep search patterns for
it in SKILL.md; never duplicate content between SKILL.md and references.

### Grok: body-as-prompt

Grok treats the SKILL.md body as **a prompt, not documentation** — focused, actionable,
step-numbered. Long encyclopedic bodies degrade Grok behavior more than Claude's. Keep the
canonical layered structure (lean SKILL.md, depth in references/) and Grok gets this for free.

### Grok: name validation

Grok is the strictest on names: 2–64 chars, `[a-z0-9-]`, alphanumeric at both ends.
Since it's the tightest constraint, adopt it as the universal rule — any name valid for
Grok is valid everywhere. (All `trl-*` names in this repo comply.)

## What Ports Cleanly vs. What Doesn't

**Ports as-is:** SKILL.md + name/description frontmatter, `references/` lazy-loading — all
three do progressive disclosure (metadata at startup, body on activation, bundled files on
demand) — `scripts/`, `assets/`, description-driven auto-trigger, slash/explicit invocation.
Spec guidance: keep the SKILL.md body under ~500 lines / ~5,000 tokens; keep bundled-file
references one level deep with paths relative to the skill root.

**Needs harness-specific handling:**

| Item | Issue | Handling |
|------|-------|----------|
| `agents/openai.yaml` | Codex-only (interface + policy + tool deps) | Ship it; inert elsewhere |
| `INTRODUCTION.md` | This repo's convention, not read natively by any harness router | Keep — it serves invoking *agents*, not the router |
| Claude-specific tools in workflows (Task/Agent spawning, MCP wiring) | Absent on Grok, different on Codex | Isolate in `references/`; mark `> **Requires:** ...` |
| `allowed-tools` frontmatter | Claude Code only; spec-experimental | Optional; never load-bearing for safety |
| Claude Code extras (`disable-model-invocation`, `context: fork`, `` !`command` `` preprocessing, plugin packaging) | Not in the open spec; Codex won't honor; Grok subset unverified | Don't use in portable skills; isolate in Claude-only variants |
| Enable/disable state | `[[skills.config]]` TOML (Codex) vs config.toml + extensions modal (Grok) vs settings (Claude) | Document per harness; skill-manage abstracts this locally |
| Codex path churn | `~/.codex/skills` legacy vs `.agents/skills` documented | Mention both until openai/skills#420 resolves |

## Portable Authoring Checklist

- [ ] `name`: 2–64 chars, `[a-z0-9-]`, starts/ends alphanumeric, matches directory
- [ ] `description`: 3–8 lines; capability first, then triggers/keywords; mentions the slash command
- [ ] Optional `metadata.short-description` (one line) for Codex/Grok UI
- [ ] SKILL.md body reads as an actionable prompt (Grok) and is token-frugal (Codex)
- [ ] No load-bearing content in frontmatter keys beyond name/description
- [ ] Harness-specific instructions isolated in `references/` with `> **Requires:**` markers
- [ ] `agents/openai.yaml` generated and in sync with the description (if targeting Codex)
- [ ] Enabled per provider via `skill-manage`, not copied
