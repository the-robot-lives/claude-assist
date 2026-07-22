# Story Coverage & Traceability Matrix

Every active story maps to exactly one primary milestone/lane; cancelled stories are listed at the end, outside any milestone.

| Story | Title | Pri | Wave | Category | Milestone | Lane | Notes |
|---|---|---|---|---|---|---|---|
| US-001 | Create an empty script with name and description | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-002 | Add a user-turn node to a script | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-003 | Attach a prompt to a script node | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-004 | Add an expectation to a script node | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-005 | Add a directed edge between two nodes with a match condition | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-006 | Publish the first version of a script | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-007 | Import a script from a YAML file | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-008 | Export a script to YAML | P0 | Wave 1 | script-authoring | M2 | A — Script graph & versioning | |
| US-009 | Create a standalone prompt | P0 | Wave 1 | prompt-management | M1 | A — Prompts | |
| US-010 | Publish a new prompt version | P0 | Wave 1 | prompt-management | M1 | A — Prompts | |
| US-011 | Reference a published prompt from a script node | P0 | Wave 1 | prompt-management | M1 | A — Prompts | stub; finalizes in M2 |
| US-012 | Configure an OpenAI agent adapter | P0 | Wave 1 | agent-connectors | M2 | B — Agent connectors | |
| US-013 | Test agent connectivity with a health check | P0 | Wave 1 | agent-connectors | M2 | B — Agent connectors | |
| US-014 | Publish an agent version | P0 | Wave 1 | agent-connectors | M2 | B — Agent connectors | |
| US-015 | Trigger a one-off run from the editor | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-016 | View run status update in real time | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-017 | See each step's prompt and agent response in run detail | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-018 | Cancel an in-flight run | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-019 | Get run-level pass/warn/fail verdict | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-020 | See individual step scores | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-021 | See aggregate score summary for a run | P0 | Wave 1 | run-execution | M3 | A — Runner core | |
| US-022 | Fall through to freeball when no authored edge matches | P0 | Wave 1 | freeball-protocol | M3 | B — Freeball engine | |
| US-023 | See freeball-generated prompt in run detail | P0 | Wave 1 | freeball-protocol | M3 | B — Freeball engine | |
| US-024 | See freeball runner confidence per tentative node | P0 | Wave 1 | freeball-protocol | M3 | B — Freeball engine | |
| US-025 | List recent runs for an organization | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-026 | Filter the run list by script | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-027 | Filter the run list by agent | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-028 | Filter the run list by status | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-029 | Open run detail from the list | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-030 | View the conversation as a linear timeline | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-031 | Drill down into a single step's full JSON payload | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-032 | Export a single run as JSON | P0 | Wave 1 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-033 | Create a simple rubric with LLM-as-judge scoring | P0 | Wave 1 | rubric-and-scoring | M1 | B — Rubrics | |
| US-034 | Attach a rubric to an expectation | P0 | Wave 1 | rubric-and-scoring | M1 | B — Rubrics | stub; finalizes in M2 |
| US-035 | Create a basic persona with a tone tag | P0 | Wave 1 | persona-management | M1 | C — Personas | |
| US-036 | Attach a persona to a run | P0 | Wave 1 | persona-management | M1 | C — Personas | schema-side only; runtime finalizes in M3 |
| US-037 | Run a script via codefresh CLI with a YAML file | P0 | Wave 1 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-038 | Get a pass/fail exit code from the CLI | P0 | Wave 1 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-039 | Create an organization | P0 | Wave 1 | tenancy-and-admin | M0 | A — Platform foundations | |
| US-040 | Invite a user as a member of an organization | P0 | Wave 1 | tenancy-and-admin | M0 | A — Platform foundations | |
| US-041 | Add a system-prompt node to a script | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-042 | Add a terminal node to mark the end of a conversation path | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-043 | Add a freeball-anchor node to explicitly invite freeball from a point | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-044 | Start a new draft from a published script version | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-045 | Diff two script versions visually | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-046 | Fork a published script into a new independent head | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-047 | Archive a script | P1 | Wave 2 | script-authoring | M2 | A — Script graph & versioning | |
| US-048 | Define template variables on a prompt | P1 | Wave 2 | prompt-management | M1 | A — Prompts | |
| US-049 | Define tool/function schemas on a prompt | P1 | Wave 2 | prompt-management | M1 | A — Prompts | |
| US-050 | Browse the prompt library and reuse across scripts | P1 | Wave 2 | prompt-management | M1 | A — Prompts | |
| US-051 | Attach persona-layered expectations to script nodes | P1 | Wave 2 | persona-management | M1 | C — Personas | stub; finalizes in M2 |
| US-052 | Fan out a run across multiple personas in parallel | P1 | Wave 2 | persona-management | M3 | C — Persona runtime | |
| US-053 | Attach a system-prompt preamble to a persona | P1 | Wave 2 | persona-management | M1 | C — Personas | |
| US-054 | See per-persona results breakdown on a run | P1 | Wave 2 | persona-management | M4 | A — Results & dashboards | deferred tail from M1 |
| US-055 | Import a persona from a shared starter library | P1 | Wave 2 | persona-management | M1 | C — Personas | |
| US-056 | Define a weighted multi-criterion rubric | P1 | Wave 2 | rubric-and-scoring | M1 | B — Rubrics | |
| US-057 | Configure a rubric to use a ladder / enum scoring scale | P1 | Wave 2 | rubric-and-scoring | M1 | B — Rubrics | |
| US-058 | Preview a rubric by scoring a sample response | P1 | Wave 2 | rubric-and-scoring | M1 | B — Rubrics | |
| US-059 | Re-score a past run with a newer rubric version | P1 | Wave 2 | rubric-and-scoring | M4 | A — Results & dashboards | deferred tail from M1 |
| US-060 | See side-by-side score comparison across rubric versions | P1 | Wave 2 | rubric-and-scoring | M4 | A — Results & dashboards | deferred tail from M1 |
| US-061 | Configure an Anthropic agent adapter | P1 | Wave 2 | agent-connectors | M2 | B — Agent connectors | |
| US-062 | Configure a LangChain agent adapter | P1 | Wave 2 | agent-connectors | M2 | B — Agent connectors | |
| US-063 | Configure an arbitrary HTTP agent adapter | P1 | Wave 2 | agent-connectors | M2 | B — Agent connectors | |
| US-064 | Set per-agent cost cap and rate limit | P1 | Wave 2 | agent-connectors | M2 | B — Agent connectors | |
| US-065 | See agent connection health at a glance on the agent list | P1 | Wave 2 | agent-connectors | M2 | B — Agent connectors | |
| US-066 | Retry a failed run from the failing step | P1 | Wave 2 | run-execution | M3 | A — Runner core | |
| US-067 | Enforce run-level cost cap (auto-cancel when exceeded) | P1 | Wave 2 | run-execution | M3 | A — Runner core | |
| US-068 | Stream scores in real time alongside the step stream | P1 | Wave 2 | run-execution | M3 | A — Runner core | |
| US-069 | Schedule recurring runs via cron expression | P1 | Wave 2 | run-execution | M3 | A — Runner core | |
| US-070 | Trigger a batch run against multiple agents | P1 | Wave 2 | run-execution | M3 | A — Runner core | |
| US-071 | Configure the freeball runner model and prompt per organization | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-072 | Enforce a freeball depth cap / budget | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-073 | Support freeball-within-freeball nesting | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-074 | Enforce strict mode on a node (reject freeball) | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-075 | Require freeball mode on a node (force freeball) | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-076 | Warn when freeball runner model is weaker than the target agent | P1 | Wave 2 | freeball-protocol | M3 | B — Freeball engine | |
| US-077 | Side-by-side diff view of two runs | P1 | Wave 2 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-078 | Trend chart of aggregate scores over time for a script | P1 | Wave 2 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-079 | Filter the run list by date range | P1 | Wave 2 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-080 | Filter the run list by persona | P1 | Wave 2 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-081 | Stand up an OTLP gRPC receiver endpoint for inbound agent spans | P1 | Wave 2 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-082 | Correlate inbound OTel spans to run_steps | P1 | Wave 2 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-083 | Emit JUnit XML from the CLI | P1 | Wave 2 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-084 | Run with --personas flag from the CLI | P1 | Wave 2 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-085 | Publish a GitHub Actions reusable workflow for CodeFresh | P1 | Wave 2 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-086 | Publish a GitLab CI template for CodeFresh | P1 | Wave 2 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-087 | codefresh login and local token management | P1 | Wave 2 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-088 | Show the freeball review queue | P1 | Wave 2 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-089 | Claim, approve, or reject a freeball node | P1 | Wave 2 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-090 | Promote a freeball chain to a new script version | P1 | Wave 2 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-091 | Python SDK core — install, authenticate, trigger runs | P1 | Wave 2 | sdks | M6 | B — SDKs & webhooks | |
| US-092 | Elixir SDK core — install, authenticate, trigger runs | P1 | Wave 2 | sdks | M6 | B — SDKs & webhooks | |
| US-093 | TypeScript SDK core — install, authenticate, trigger runs | P1 | Wave 2 | sdks | M6 | B — SDKs & webhooks | |
| US-094 | SDK OTel bridge helper for emitting spans to CodeFresh | P1 | Wave 2 | sdks | M6 | B — SDKs & webhooks | cross-milestone dependency — consumes M6 Lane A OTel receiver |
| US-095 | SDK query helpers for runs, steps, and scores | P1 | Wave 2 | sdks | M6 | B — SDKs & webhooks | |
| US-096 | Issue an API token for SDK / CLI use | P1 | Wave 2 | tenancy-and-admin | M0 | A — Platform foundations | forward-loaded — CLI login contract |
| US-097 | Revoke or rotate an API token | P1 | Wave 2 | tenancy-and-admin | M0 | A — Platform foundations | forward-loaded |
| US-098 | Query OTel spans by attribute | P1 | Wave 2 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-099 | Drill down from a run step into its OTel span tree | P1 | Wave 2 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-100 | Semantic search over OTel span names and messages | P1 | Wave 2 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-101 | Create a dataset of request / expected-output pairs | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-102 | Publish a new dataset version | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-103 | Add entries to a dataset manually | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-104 | Import a dataset from CSV or JSON | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-105 | Run a dataset against an agent (model-based eval) | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-106 | Flag an OTel span or production interaction for future eval use | P1 | Wave 2 | flagged-captures | M5 | C — Flagged captures, manual mode | manual mode only; auto mode finalizes in M6 via US-147 |
| US-107 | Browse the flagged captures library | P1 | Wave 2 | flagged-captures | M5 | C — Flagged captures, manual mode | |
| US-108 | Promote a flagged capture to a script node input | P1 | Wave 2 | flagged-captures | M5 | C — Flagged captures, manual mode | |
| US-109 | Promote a flagged capture to a dataset entry | P1 | Wave 2 | flagged-captures | M5 | C — Flagged captures, manual mode | |
| US-110 | Attach a rubric to a dataset | P1 | Wave 2 | datasets | M5 | B — Datasets | |
| US-114 | Prompt testing sandbox | P2 | Wave 3 | prompt-management | M1 | A — Prompts | |
| US-115 | Loops and conditionals in prompt templating | P3 | Wave 3 | prompt-management | M1 | A — Prompts | |
| US-116 | Import a persona from a shared marketplace | P2 | Wave 3 | persona-management | M1 | C — Personas | |
| US-118 | Per-step persona switching mid-run | P3 | Wave 3 | persona-management | M3 | C — Persona runtime | |
| US-119 | Import a rubric from a shared marketplace | P2 | Wave 3 | rubric-and-scoring | M1 | B — Rubrics | |
| US-120 | Rubric confidence bands on scores | P2 | Wave 3 | rubric-and-scoring | M1 | B — Rubrics | |
| US-121 | Rubric disagreement analytics across runs | P3 | Wave 3 | rubric-and-scoring | M4 | A — Results & dashboards | deferred tail from M1 |
| US-122 | Bedrock and Vertex AI agent adapters | P2 | Wave 3 | agent-connectors | M2 | B — Agent connectors | |
| US-123 | Agent response streaming support | P2 | Wave 3 | agent-connectors | M2 | B — Agent connectors | |
| US-124 | Cost prediction before a run is triggered | P2 | Wave 3 | run-execution | M3 | A — Runner core | |
| US-125 | Dataset-run persona fan-out | P3 | Wave 3 | run-execution | M5 | B — Datasets | |
| US-126 | Freeball confidence distribution histograms | P3 | Wave 3 | freeball-protocol | M3 | B — Freeball engine | |
| US-127 | Freeball learning mode (promoted paths tune the runner) | P3 | Wave 3 | freeball-protocol | M3 | B — Freeball engine | cross-milestone dependency — needs M5 promotion data; deferred tail, schedule last in lane |
| US-128 | Adaptive freeball depth based on confidence | P3 | Wave 3 | freeball-protocol | M3 | B — Freeball engine | |
| US-129 | Cohort comparison across multiple runs | P2 | Wave 3 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-130 | Custom dashboard builder | P3 | Wave 3 | results-and-dashboards | M4 | A — Results & dashboards | |
| US-131 | OTel partition + retention admin | P2 | Wave 3 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-132 | OTLP ingest sampling configuration | P2 | Wave 3 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-133 | ClickHouse mirror for OTel spans and logs | P3 | Wave 3 | otel-ingestion | M6 | A — OTel ingestion & auto-flagging | |
| US-134 | codefresh init — project scaffolding | P2 | Wave 3 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-135 | CLI watch mode for file changes | P3 | Wave 3 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-136 | TAP and Allure output formats from CLI | P3 | Wave 3 | cli-and-cicd | M4 | B — CLI & CI/CD | |
| US-137 | Regression suite from rejected freeballs | P2 | Wave 3 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-138 | Bulk actions on the freeball review queue | P2 | Wave 3 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-139 | Promote a freeball expectation to a persona-scoped expectation | P3 | Wave 3 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-140 | Review assignment workflow | P2 | Wave 3 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-141 | Freeball SLA aging alerts | P3 | Wave 3 | review-and-promotion | M5 | A — Freeball review & promotion | |
| US-142 | SSO via SAML / OIDC | P2 | Wave 3 | tenancy-and-admin | M6 | C — Enterprise tenancy | |
| US-143 | Audit log export | P2 | Wave 3 | tenancy-and-admin | M6 | C — Enterprise tenancy | |
| US-144 | SDK webhook subscriptions | P2 | Wave 3 | sdks | M6 | B — SDKs & webhooks | |
| US-145 | React hooks package for run state | P3 | Wave 3 | sdks | M6 | B — SDKs & webhooks | |
| US-146 | SDK publish for Deno and Bun runtimes | P3 | Wave 3 | sdks | M6 | B — SDKs & webhooks | |
| US-147 | Auto-flagging rules for production captures | P2 | Wave 3 | flagged-captures | M6 | A — OTel ingestion & auto-flagging | finalizes US-106 auto mode |
| US-148 | Flag digest email | P3 | Wave 3 | flagged-captures | M5 | C — Flagged captures, manual mode | |
| US-149 | HuggingFace datasets integration | P2 | Wave 3 | datasets | M5 | B — Datasets | |
| US-150 | Export datasets as Parquet | P2 | Wave 3 | datasets | M5 | B — Datasets | |

## Cancelled

- US-111 — Bulk node operations in the graph editor (script-authoring) — cancelled; not in any milestone.
- US-112 — Inline comments on script nodes (script-authoring) — cancelled; not in any milestone.
- US-113 — Auto-layout the script graph (script-authoring) — cancelled; not in any milestone.
- US-117 — Persona heatmap visualization (persona-management) — cancelled; not in any milestone.

## Reconciliation

| Milestone | Active story count |
|---|---|
| M0 | 4 |
| M1 | 21 |
| M2 | 25 |
| M3 | 27 |
| M4 | 28 |
| M5 | 22 |
| M6 | 19 |
| **Total active** | **146** |
| Cancelled | 4 |
| **Total authored** | **150** |

146 active + 4 cancelled = 150, matching US-001 through US-150 with no gaps and no duplicates.
