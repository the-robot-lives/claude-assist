# skills/ — Claude Code Skill Definitions

Skill definitions (NPL/Noizu authored). Canonical source is monorepo `skills/`. Prefer
**`llm-toolkit skill`** (skill-manage crate embedded in `utilities/agent/llm-toolkit/`) to
enable/disable provider installs via symlinks instead of manual `cp`:

```bash
export SKILL_REPO=/path/to/Noizu/skills   # or llm-toolkit skill init-config
llm-toolkit skill enable skills <name> --provider claude   # also codex / grok
llm-toolkit skill list skills --provider all
llm-toolkit skill audit skills
```

Config lives under `~/.config/skill-manage/` (multi-source roots, YAML catalog for tags /
work types) — paths unchanged from the standalone `skill-manage` tool. **Agents**
(`~/.claude/agents/*.md`) and **commands** (`~/.claude/commands/*.md`) are sibling artifact
kinds managed by the same tool — not the same as skills.

`skills/shared/` holds assets shared across skills; `skills/evals/` holds skill evaluation
harnesses. Repo-level metadata for `llm-toolkit skill`:

| File | Role |
|------|------|
| `skills/catalog.yaml` | Tags, work types, enable-set bundles, editor profiles |
| `skills/categories.yaml` | Category index + flows |
| `skills/tags.yaml` | Controlled tag vocabulary |

```
skills/
├── README.md                   # Skill catalog overview
├── shared/                     # Assets shared across skills
├── evals/                      # Skill evaluation harnesses
│
│   # ── Engineering / platform ──
├── kubernetes-engineer/        ├── terraform-engineer/
├── signoz-terraform-provider/  ├── mcp-architect/
├── mcp-builder/                ├── mcp-forge/
├── plugin-architect/           ├── agent-architect/
├── agentic-harness-engineer/   ├── skill-engineer/
├── skill-evaluator/            ├── dba-db-designer-and-tuning/
│
│   # ── App / UI development ──
├── react-engineer/             ├── lit-dev/
├── android-mobile/             ├── ios-mobile-engineer/
├── osx-design-and-develop/     ├── metal-graphics-dev/
├── unity-developer/            ├── tui-engineer/
├── user-experience-engineer/   ├── conversion-engineer/
├── rapid-prototype/            ├── game-design/
│
│   # ── Content / knowledge / marketing ──
├── content-generator/          ├── content-publishing/
├── technical-writer/           ├── kb/  kb-curriculum/  kb-digest/  kb-research/
├── seo-guru/                   ├── market-intelligence/
├── monetization-strategy/      ├── print-on-demand/
├── proposal-writer/            ├── media-solution-architect/
├── ai-templates/               ├── noizu-frameworks/
│
│   # ── Research / security / process ──
├── research-and-development/   ├── threat-modeler/
├── site-walkthrough/           └── persona-session/
```

Each skill dir contains a `SKILL.md` (or equivalent) plus supporting references/assets. See
each skill's own description for trigger conditions and scope.
