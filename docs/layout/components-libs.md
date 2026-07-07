# components/ & libs/ — Reusable Scaffolds and Shared Libraries

## components/ — App Scaffolds

Reusable app templates that portfolio projects are scaffolded from (via
`utilities/start-app-scaffold/bin/init-proj-scaffold`).

```
components/
├── start-app/                  # Canonical full-stack scaffold: Elixir backend + Next.js
│   │                           # frontend + Helm chart + sandbox Dockerfile
│   ├── backend/                #   Elixir/Phoenix API
│   ├── frontend/               #   Next.js + design system
│   ├── .env.example            #   Env template (copy to .env)
│   └── .tool-versions          #   asdf/mise tool pins
├── static-site/                # Static-site scaffold + Helm chart (helm/static-site)
└── styleguide/                 # @noizu/styleguide — design-system generator
    └── app/                    #   Styleguide app (Cypress e2e, theme YAML → CSS)
```

## libs/ — Shared Libraries

```
libs/
├── elixir-mcp/                 # Elixir MCP server+client library (Peer arch, JSV, Bandit SSE)
├── ai/
│   └── elixir-weaviate/        #   Weaviate vector-DB client for Elixir (noizu_weaviate)
└── scaffolding/
    └── core/                   #   Core scaffolding library (Noizu.Entity/Repo/Service, etc.)
```

> The Noizu Elixir framework ecosystem (genai, noizu_labs_*, fragmented_keys, smart_token, …)
> is consumed by the Elixir apps here; see the `noizu-frameworks` skill for the full library
> reference.
