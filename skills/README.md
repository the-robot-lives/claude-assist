# Skills

A collection of 49 trl- (the-robot-lives) prefixed skills for Claude Code, Codex, and Grok — executable knowledge modules for monetization, engineering, design, security, knowledge management, and AI agent development.

Skills are **self-contained**: each can be invoked independently via `/skill-name` in Claude Code. They reference each other but don't require each other.

## Quick Start

```
/trl-monetization-strategy    # Start here — choose your income stream
/trl-market-intelligence      # Validate your niche before building
/trl-skill-engineer           # Build new skills or improve existing ones
```

## Skills by Category

### Passive Income & Strategy

| Skill | Description |
|-------|-------------|
| [trl-monetization-strategy](trl-monetization-strategy/) | Decision framework for choosing and sequencing passive income streams based on skills, constraints, and risk tolerance |
| [trl-market-intelligence](trl-market-intelligence/) | Identify, validate, and score underserved niches and audiences across any monetization stream |
| [trl-conversion-engineer](trl-conversion-engineer/) | Coordinate a multi-stream portfolio across AI Templates, Content Publishing, and Print on Demand |
| [trl-ai-templates](trl-ai-templates/) | Build, launch, and scale AI-powered digital products — prompt libraries, automation workflows, GPT configs, MCP packages |
| [trl-content-publishing](trl-content-publishing/) | Build authority and recurring revenue through newsletters, technical articles, tutorials, and courses |
| [trl-print-on-demand](trl-print-on-demand/) | Design and sell niche merchandise through fulfillment partners with zero inventory risk |
| [trl-marketing](trl-marketing/) | Product marketing and launch execution — positioning, announcements, social campaigns, press outreach, launch metrics |

**Flow:** `trl-monetization-strategy` (pick a path) → `trl-market-intelligence` (validate the niche) → execute with `trl-ai-templates`, `trl-content-publishing`, or `trl-print-on-demand` → `trl-conversion-engineer` (orchestrate the portfolio)

### Knowledge Management & Learning

| Skill | Description |
|-------|-------------|
| [trl-kb](trl-kb/) | Gather, organize, and structure knowledge into learning paths, bibliographies, and research digests |
| [trl-kb-research](trl-kb-research/) | Find and evaluate books, articles, papers, and open-access materials using parallel searches |
| [trl-kb-curriculum](trl-kb-curriculum/) | Design structured learning paths with prerequisite mapping, difficulty calibration, and milestones |
| [trl-kb-digest](trl-kb-digest/) | Synthesize research into knowledge digests calibrated from ELI5 through doctoral depth |

**Flow:** `trl-kb-research` (find resources) → `trl-kb-curriculum` (sequence them) → `trl-kb-digest` (synthesize at target level)

### MCP Server Development

| Skill | Description |
|-------|-------------|
| [trl-mcp-builder](trl-mcp-builder/) | Parent coordinator for the full MCP lifecycle — routes between architect and forge phases |
| [trl-mcp-architect](trl-mcp-architect/) | Checklist-driven specification and design: tool surface, transport, auth, security |
| [trl-mcp-forge](trl-mcp-forge/) | Implementation engineer: scaffold, build, test, containerize, and deploy MCP servers |

**Flow:** `trl-mcp-builder` (coordinate) → `trl-mcp-architect` (design) → `trl-mcp-forge` (build)

### AI & Agent Engineering

| Skill | Description |
|-------|-------------|
| [trl-agent-architect](trl-agent-architect/) | Design, build, and validate AI agents with research-backed patterns — subagents, multi-agent systems, persona definitions, prompt/context engineering, tool design, memory, guardrails |
| [trl-agentic-harness-engineer](trl-agentic-harness-engineer/) | Design, implement, evaluate, and security-harden LLM agentic systems — from architecture through production deployment |
| [trl-rapid-prototype](trl-rapid-prototype/) | Rapid prototyping and feasibility validation — from idea to working demo to go/no-go recommendation in a single session |
| [trl-research-and-development](trl-research-and-development/) | Design and execute structured R&D workflows: hypothesis formation, experiment design, data collection, analysis, and publication |

### Mobile & Desktop Engineering

| Skill | Description |
|-------|-------------|
| [trl-ios-mobile-engineer](trl-ios-mobile-engineer/) | Production-ready iOS apps from concept through App Store submission using SwiftUI and Swift |
| [trl-android-mobile](trl-android-mobile/) | Production-ready Android apps using Kotlin, Jetpack Compose, and Material Design 3 |
| [trl-osx-design-and-develop](trl-osx-design-and-develop/) | Production-ready macOS desktop apps using SwiftUI — menu bar apps, document-based apps, multi-window, Mac App Store and notarized distribution |

### Design & Frontend

| Skill | Description |
|-------|-------------|
| [trl-user-experience-engineer](trl-user-experience-engineer/) | Design and implement UIs from brief through production — web, terminal, SVG mockups, logos |
| [trl-react-engineer](trl-react-engineer/) | Production-grade React engineering with Next.js 15-16, Redux Toolkit, React Server Components, View Transitions, and TypeScript |
| [trl-lit-dev](trl-lit-dev/) | Design and implement production-ready Lit v3 web components — from single elements through full design systems |
| [trl-seo-guru](trl-seo-guru/) | Audit and optimize for search engines and AI answer engines (GEO, AEO, schema markup, llms.txt) |
| [trl-tui-engineer](trl-tui-engineer/) | Design and build terminal UIs across Rust, Go, C/C++, TypeScript, Java, and shell — dashboards, forms, wizards, and interactive CLI tools |
| [trl-zellij-engineer](trl-zellij-engineer/) | Extend Zellij itself — WASM plugins, KDL layouts and keybinds, core Rust internals, and fork rebases |
| [trl-theme-designer](trl-theme-designer/) | Fine-tune styleguide-engine theme YAML from UX treatise documents — seed extraction, facet overrides, variants, contrast verification |
| [trl-ui-test-engineer](trl-ui-test-engineer/) | Non-fragile UI test architecture — data-cy selector schema, fluent Cypress commands, step libraries, fixture seams, jump-to-SUT sessions, agentic test exploration |

### Backend & Infrastructure

| Skill | Description |
|-------|-------------|
| [trl-kubernetes-engineer](trl-kubernetes-engineer/) | Production K8s and Helm engineering — chart authoring, CRD design, security hardening, autoscaling (Karpenter, KEDA), GitOps, and operational cookbook |
| [trl-terraform-engineer](trl-terraform-engineer/) | Production-grade Terraform infrastructure across AWS, GCP, Azure, Kubernetes, and Cloudflare — modules, state, CI/CD, testing, policy-as-code |
| [trl-dba-db-designer-and-tuning](trl-dba-db-designer-and-tuning/) | Database schema design, query optimization, migration planning, and PostgreSQL tuning |
| [trl-threat-modeler](trl-threat-modeler/) | Defensive security analysis using STRIDE, PASTA, and OWASP — threat modeling, compliance, hardening |
| [trl-metal-graphics-dev](trl-metal-graphics-dev/) | GPU-accelerated macOS/iOS apps with Apple Metal — shaders, render/compute pipelines, profiling |
| [trl-media-solution-architect](trl-media-solution-architect/) | Design, build, and optimize self-hosted CDN and media streaming systems from ingest to playback |
| [trl-plugin-architect](trl-plugin-architect/) | Design plugin architectures for extensible software — extension points, registries, lifecycle management, SDK generation |
| [trl-api-designer](trl-api-designer/) | API contract design and evolution — REST/GraphQL/gRPC modeling, OpenAPI workflows, versioning, auth, error taxonomy |
| [trl-story-to-release](trl-story-to-release/) | Implement user stories from backlog to shipped release, constrained by style guides and persona expectations |

### Elixir Framework Reference

| Skill | Description |
|-------|-------------|
| [trl-noizu-frameworks](trl-noizu-frameworks/) | Comprehensive reference for the Noizu Elixir ecosystem — 13 libraries covering GenAI/LLM providers, entity persistence, distributed worker pools, cache invalidation, vector databases, and utilities |

### Documentation, Professional Services & Meta

| Skill | Description |
|-------|-------------|
| [trl-technical-writer](trl-technical-writer/) | Author, proof-edit, and review technical docs — READMEs, API references, onboarding guides, runbooks |
| [trl-proposal-writer](trl-proposal-writer/) | Draft, structure, and refine professional proposals and statements of work for consulting and freelance engagements |
| [trl-content-generator](trl-content-generator/) | Research-driven content ideation, trend validation, and platform-optimized abstract creation for technical publishing pipelines |
| [trl-skill-engineer](trl-skill-engineer/) | Design, build, and validate new skills from requirements through production-ready scaffolds |
| [trl-game-design](trl-game-design/) | End-to-end game design, production, and monetization across mobile, PC, console, and cross-platform — from concept through live ops |

## Metadata (skill-manage)

YAML metadata for listing, tagging, work-type profiles, and enable-sets:

| File | Purpose |
|------|---------|
| [`catalog.yaml`](catalog.yaml) | skill-manage catalog — per-skill tags, work_types, providers; work-type bundles; editor profiles |
| [`categories.yaml`](categories.yaml) | README-aligned category index + recommended flows |
| [`tags.yaml`](tags.yaml) | Controlled tag vocabulary |

```bash
export SKILL_REPO=/path/to/Noizu/skills
# In ~/.config/skill-manage/config.yaml:
#   catalog: /path/to/Noizu/skills/catalog.yaml

skill-manage list skills --tag infra
skill-manage enable-set --work-type agents --provider claude
skill-manage profiles -i
```

Keys in `catalog.yaml` match **directory names** (`trl-*`).

## Skill Structure

Each skill follows a consistent layout:

```
skill-name/
├── SKILL.md              # Entry point — persona, instructions, workflows
├── references/           # Detailed playbooks, guides, and frameworks
└── assets/               # Templates, trackers, and reusable artifacts
```

## Adding a New Skill

Use the `trl-skill-engineer` skill to scaffold and validate new skills:

```
/trl-skill-engineer
```

It walks through interactive discovery, generates the file tree, and evaluates against quality rubrics.
