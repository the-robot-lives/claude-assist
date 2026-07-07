# skills/ — Claude Code Skill Definitions

Skill definitions (NPL/Noizu authored). **Note**: skills exist in two unsynced copies — edit
the monorepo `skills/` source *and* `cp` to `~/.claude/skills/` (separate git repo, no
auto-sync). `skills/shared/` holds assets shared across skills; `skills/evals/` holds skill
evaluation harnesses.

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
