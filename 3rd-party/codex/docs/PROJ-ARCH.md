# Project Architecture

Codex — AI-powered code indexing and search platform. Distributed system with a Rust-based indexing engine, multi-language SDKs, and hermetic build infrastructure.

## System Overview

```
User Interactions
├── CLI (Node.js)         → [docs/codex-cli/PROJ-ARCH.md](../codex-cli/docs/PROJ-ARCH.md)
├── Python SDK            → [docs/sdk/PROJ-ARCH.md](../sdk/docs/PROJ-ARCH.md)
└── TypeScript SDK        → [docs/sdk/PROJ-ARCH.md](../sdk/docs/PROJ-ARCH.md)
        ↓
    HTTP/gRPC APIs
        ↓
Codex Backend (Rust)     → see codex-rs/docs/PROJ-ARCH.md
├── Indexing Engine
├── Search Index
├── Query Processor
└── Protocol Handlers
        ↓
Data & Persistence
├── Vector Database
├── Index Storage
└── Metadata DB
```

## Core Architectural Components

### Backend (codex-rs)

Main indexing and serving engine written in Rust:
- **Indexing**: Process source code into searchable index
- **Search**: Query processing and result ranking
- **APIs**: HTTP and gRPC endpoints for clients
- **Storage**: Interface with persistent storage layer

→ *See codex-rs/docs/PROJ-ARCH.md for backend architecture*

### Frontend Clients

Multiple client options for different use cases:

| Client | Type | Details |
|--------|------|---------|
| **CLI** | Command-line | Developer-focused tool; local workflows |
| **Python SDK** | Library | Programmatic access; data science workflows |
| **TypeScript SDK** | Library | Browser and Node.js integration |

→ *See [docs/codex-cli/PROJ-ARCH.md](../codex-cli/docs/PROJ-ARCH.md) and [docs/sdk/PROJ-ARCH.md](../sdk/docs/PROJ-ARCH.md)*

### Build Infrastructure

Hermetic, reproducible builds across platforms:

| Layer | Purpose | Details |
|-------|---------|---------|
| **Bazel System** | Build orchestration | Multi-platform support (Linux, macOS, Windows) |
| **Modules & Rules** | Dependency & logic | Hermetic dependencies via bzlmod |
| **Toolchains** | Compilation | GCC, Clang, MSVC; x86_64, ARM, ARM64 |
| **Patches** | Compatibility | Platform-specific dependency fixes |
| **Scripts** | Automation | Build, packaging, validation utilities |

→ *See [docs/bazel/PROJ-ARCH.md](../bazel/docs/PROJ-ARCH.md) and [docs/scripts/PROJ-ARCH.md](../scripts/docs/PROJ-ARCH.md)*

### Developer Tools

Quality assurance and code validation:

| Tool | Purpose |
|------|---------|
| **argument-comment-lint** | Validate API documentation |
| **buildifier** | Format and lint Bazel files |

→ *See [docs/tools/PROJ-ARCH.md](../tools/docs/PROJ-ARCH.md)*

### Dependencies

Vendored third-party tools for specialized functionality:

| Component | Purpose |
|-----------|---------|
| **V8** | Embedded JavaScript runtime |
| **PowerShell** | Windows scripting support |
| **Wezterm** | Terminal emulation library |
| **Wine** | Cross-platform testing on CI |

→ *See [docs/third_party/PROJ-ARCH.md](../third_party/docs/PROJ-ARCH.md) and [docs/patches/PROJ-ARCH.md](../patches/docs/PROJ-ARCH.md)*

## Communication Patterns

```
HTTP/REST
└─ Used by: CLI, SDKs, web frontends
   ├─ Authentication via JWT/OAuth
   └─ Request/response JSON encoding

gRPC (with protobuf)
└─ Used by: Python SDK, TypeScript SDK
   ├─ Binary protocol for efficiency
   ├─ Type safety via protobuf definitions
   └─ Streaming support for large results
```

## Data Flow

### Indexing Flow

1. **Source Input** → Code repository or file stream
2. **Parsing** → Extract symbols, definitions, cross-references
3. **Analysis** → Compute metrics, embeddings, relationships
4. **Indexing** → Store in search index with metadata
5. **Persistence** → Write to vector DB + metadata storage

### Query Flow

1. **Query Input** → Via CLI, SDK, or HTTP API
2. **Parsing** → Interpret query syntax and filters
3. **Search** → Query index (vector similarity, keyword, filters)
4. **Ranking** → Score results by relevance
5. **Response** → Return formatted results to client

## Technology Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Rust, async/await (tokio) |
| **APIs** | gRPC, HTTP/REST, Protocol Buffers |
| **SDKs** | Python 3.x, TypeScript/Node.js |
| **Build** | Bazel, bzlmod, Rust rules |
| **Tools** | Python, Shell, Rust |
| **Databases** | Vector DB (TBD), SQL (metadata) |

## Design Principles

1. **Hermetic Builds** — Reproduce exact build artifacts from source
2. **Platform Agnostic** — Single codebase builds for Linux, macOS, Windows
3. **Scalability** — Index engine designed for large codebases (millions of files)
4. **SDK Idiomaticity** — Each SDK follows language conventions
5. **API Stability** — Version control for breaking changes
6. **Tool Integration** — CLI and SDKs for diverse use cases

## Deployment & Distribution

- **Standalone Binary** — Codex backend deployable as single executable
- **SDK Packages** — Distributed via PyPI (Python), npm (TypeScript)
- **CLI Tool** — npm install or prebuilt binaries
- **Docker** — Container images for server deployment
- **Cloud Ready** — No required local storage; compatible with cloud APIs

## Quality Gates

1. **Unit Tests** — Per-component testing via Bazel
2. **Integration Tests** — End-to-end flows (index → search)
3. **Linting** — Code quality via clippy (Rust), flake8 (Python)
4. **Build Validation** — Tools validate configuration and outputs
5. **Performance Tests** — Benchmark indexing and query latency

---

For detailed architectural discussions, see the component-specific documents linked above.
