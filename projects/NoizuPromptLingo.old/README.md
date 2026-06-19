# NoizuPromptLingo

NoizuPromptLingo (formerly Tobor Locker) is a multi-domain MCP (Model Context Protocol) collaboration platform — a two-tier application combining an **Elixir/Phoenix API backend** with domain-specific MCP servers and a **Next.js 15 dashboard frontend** for web-based project management.

## Purpose

The platform provides:
- **MCP-native interfaces** for AI agents and human collaborators
- **Eight domain-specific MCP servers** (Sessions, Tickets, Chat, Wiki, Projects, Artifacts, Assets, Reviews)
- **Web dashboard** with OIDC authentication via Authentik
- **Unified persistence** via PostgreSQL with Liquibase migrations
- **Kubernetes deployment** via Helm (`npl-mcp`)

## Core Architecture

### Backend (Elixir/Phoenix @ :4040)
- Phoenix router with **subdomain dispatch** to domain MCP servers
- Eight bounded contexts, each a self-contained MCP server with a GenServer-backed tool catalog
- REST API controllers consumed by the Next.js dashboard
- Root MCP server exposing discovery tools, NPL specification loading, and agent orchestration

### Frontend (Next.js 15 @ :3000)
- React 19 + NextAuth v5 with Authentik OIDC
- Project-scoped CRUD interfaces for all domains
- Real-time chat, ticket review, and wiki editing

### Domain MCP Servers
| Subdomain | Purpose | Tools |
|-----------|---------|-------|
| `sessions.tobor.locker` | Agent session management | Sessions list, create, get, delete |
| `tickets.tobor.locker` | Ticket/lifecycle management | Ticket CRUD, status transitions |
| `chat.tobor.locker` | Real-time messaging | Room management, message streaming |
| `review.tobor.locker` | Workflow state & reviews | Workflow tracking, review tools |
| `wiki.tobor.locker` | Documentation | Pages, spaces, search |
| `projects.tobor.locker` | Project orchestration | Project CRUD, assignment |
| `artifacts.tobor.locker` | Artifact management | Upload, retrieval, lifecycle |
| `assets.tobor.locker` | Asset library | Media, templates, digital assets |

## Technology Stack

| Layer | Technology |
|-------|------------|
| Backend | Elixir 1.18+, Phoenix 1.7, OTP 29 |
| Frontend | Next.js 15.3, React 19, NextAuth v5 |
| Database | PostgreSQL, Ecto 3.13, **Liquibase** |
| MCP | `noizu_mcp ~> 0.1.3` (StreamableHTTP) |
| Auth | Authentik OIDC, JOSE JWT |
| Deploy | Docker (multi-stage), Helm 3, Kubernetes |
| Observability | Telemetry, Phoenix LiveDashboard |

## Key Architectural Decisions

- **MCP-first design**: Each bounded context is a first-class MCP server — AI agents get structured tool interfaces, not raw HTTP
- **Subdomain routing**: Isolates MCP tool namespaces per domain while sharing a single Phoenix endpoint
- **Liquibase over Ecto migrations**: Aligns with the monorepo's Liquibase-based migration infrastructure
- **Authentik OIDC**: Centralized SSO across the Noizu platform; user sync on sign-in
- **Project-scoped data**: All domain entities link to a `project_id` for multi-tenancy

## Deployment

Two Docker images (Elixir backend, Next.js frontend) deployed via a single Helm chart on Kubernetes. Requires wildcard DNS for `*.tobor.locker` for subdomain routing.

## Database Migration (Important)

**NoizuPromptLingo uses Liquibase for database migrations, not Ecto migrations.**

Schema changes must be written as Liquibase changelog YAML/ XML files in `db/changelog/`. Do NOT use `mix ecto.migrate` or add files to `priv/repo/migrations/`.

Migration targets are configured in the monorepo's `.infra-config.yaml` under `liquibase_targets` and run via the `liquibase-shell` utility.

## Reference Implementations

- **Current code**: `projects/NoizuPromptLingo.new` — The full implementation being preserved for reference
- **Deprecated**: `projects/NoizuPromptLingo.deprecated` — Earlier version
- **MCP library**: `libs/elixir-mcp-lib` — The `noizu_mcp` Hex package (MCP server + client library)

## Status

🚧 **Project is being rebuilt from scratch.** This directory is a clean slate for the new implementation.

## Related Documentation

- Project Architecture: `projects/NoizuPromptLingo.new/docs/PROJ-ARCH.md`
- Project Layout: `projects/NoizuPromptLingo.new/docs/PROJ-LAYOUT.md`
- MCP Library Guide: See `libs/elixir-mcp-lib/guides/` for `noizu_mcp` usage
- Monorepo Infrastructure: See `CLAUDE.md` at repo root for DevOps utilities and deployment workflows