# Past Attempts and Lessons Learned

## Scope Reviewed

I reviewed multiple codebase incarnations under `~/Github/ai/swarm` to extract reusable patterns for:

- documentation that explains architecture/contracts
- schema and persistence approaches
- coding conventions and startup/setup structure
- message passing/event routing
- agent orchestration primitives

## Observations

### Most Useful Base: `noizu-teams`

- Strongest runnable message stack with clear production flow.
- Uses Phoenix PubSub with wildcard and concrete routing keys (`subject:instance:event`, `subject:*:*`, etc.).
- End-to-end channel message path includes:
  - message persistence
  - `:message` event emission
  - audience resolution (`@mentions`, `@everyone`, `@channel`)
  - stream messaging support (`start_stream`, `send_stream`, `end_stream`)
  - LiveView subscription updates for UI.
- Agent model is concrete: per-project `ProjectManager` supervisor plus per-agent GenServer.
- Schema is concrete and practical: projects, channel memberships, messages, message statuses, and role/type enums.

### Strong Message Semantics: `intellect.legacy`

- Most complete message schema semantics:
  - typed message/event entities
  - dedicated link entities (`audience`, `responding_to`, `read`)
  - helpers for response chains and read/status history
- Channel/entity logic covers async delivery and audience expansion patterns reused in newer versions.
- Good source of legacy-but-stable message contracts and graph-style query patterns.

### Best Interop/Schema Docs: `noizu-collab`

- Best collection of external interoperability docs:
  - `tools/README.md`
  - protocol/docs schema files (`issue.yaml`, `wiki.yaml`, `master-payload.yaml`)
  - `gpt-interop` tooling and schema docs
- Useful when defining provider/agent-facing payload contracts.

### Best Infrastructure Template: `noizu-labs-ai`

- Solid infra bootstrap reference:
  - docker-compose service graph (Redis + analytics + vector DB + LLM tooling)
  - clear schema/migration baseline
- Useful as deployment scaffold when spinning a new environment quickly.

### Alternative/Event Bus Variant: `virtual_teams`

- Custom distributed event approach via `Noizu.LiveViewEvent` + `Noizu.LiveViewEventServer` with `:syn`.
- Potentially useful when session-aware distributed dispatch is needed.

### Fast Schema Scaffolding Reference: `intellect.copy`

- Strongest entity generation and migration helper pattern:
  - `SETUP.md` generation commands
  - `support/migration.ex` helper for migration workflows
- Best for accelerating new schema bootstrapping.

### Intent-Only Prototype: `noizu-ai`

- Primarily protocol and abstraction skeleton for model providers.
- Mostly placeholder implementations; useful for shape reference, not runtime behavior.

## Recommendation

For a new implementation of **The Robots' Day Job** stack, blend:

1. `noizu-teams` for message transport + agent lifecycle + streaming
2. `intellect.legacy` for deep message semantics
3. `noizu-collab` for schema/interoperability contracts
4. `noizu-labs-ai` for infra template if needed
5. `virtual_teams` only if distributed session-aware bus behavior is needed

## Lessons

- Runtime message flow was strongest in one codebase (`noizu-teams`), while schema semantics were strongest in another (`intellect.legacy`); split-reuse is better than forcing one repo to own both.
- Documentation quality does not correlate with runtime completeness; `noizu-collab` is a key reference despite weaker runtime depth.
- For future consolidation, define message/event contracts first, then adapt runtime layers to that contract to avoid drift.
