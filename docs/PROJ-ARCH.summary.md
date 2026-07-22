# Project Architecture — Quick Reference

## System Components

```
User Clients (CLI, SDKs)
        ↓
HTTP/gRPC APIs
        ↓
Codex Backend (Rust)
├─ Indexing Engine
├─ Search Index
├─ Query Processor
└─ Storage Layer
        ↓
Data (Vector DB, Metadata DB)
```

## Component Summary

| Component | Type | Purpose | Tech |
|-----------|------|---------|------|
| **codex-rs** | Backend | Core indexing & search engine | Rust, async/await |
| **codex-cli** | Frontend | Command-line tool | Node.js |
| **Python SDK** | SDK | Python library for Codex integration | Python 3.x |
| **TypeScript SDK** | SDK | Node.js/browser library | TypeScript, Node.js |
| **Bazel Build** | Infrastructure | Hermetic multi-platform builds | Bazel, bzlmod |
| **Tools** | DevTools | Linters, formatters, validators | Python, Rust |
| **Scripts** | Automation | Build, packaging, testing utilities | Python, Shell |
| **Third-Party** | Dependencies | Vendored tools (V8, PowerShell, etc.) | Mixed |
| **Patches** | Compatibility | Platform-specific dependency fixes | Patch files |

## Architecture Layers

### Presentation Layer
- **CLI**: Command-line interface (Node.js)
- **SDKs**: Language bindings (Python, TypeScript)
- **Clients**: Web, desktop, or embedded applications

### API Layer
- **gRPC**: Type-safe binary protocol with Protocol Buffers
- **HTTP/REST**: JSON-based HTTP endpoints
- **Authentication**: JWT/OAuth token validation

### Business Logic (Backend)
- **Indexing**: Parse code, extract symbols, compute embeddings
- **Search**: Query processing, ranking, filtering
- **Storage Interface**: Abstract storage operations
- **Protocol Handlers**: Serialize/deserialize messages

### Persistence Layer
- **Vector DB**: Semantic search on embeddings
- **Metadata DB**: Symbols, definitions, file structure
- **Index Storage**: Full-text or inverted index

## Data Flow Summary

### Indexing
Source Code → Parser → Analyzer → Embeddings → Index Storage

### Search
Query → Parser → Index Lookup → Ranking → Results

## Build & Distribution

- **Build System**: Bazel (hermetic, reproducible)
- **Platforms**: Linux (x86_64, ARM64), macOS (x86_64, ARM64), Windows (x86_64)
- **Distribution**: Docker images, PyPI packages, npm packages, standalone binaries
- **CI/CD**: GitHub Actions with multi-platform matrix

## Key Design Patterns

1. **Protocol Buffers** → Type-safe communication between components
2. **Async/Await** → Non-blocking I/O for high concurrency
3. **Command Pattern** → CLI maps user commands to backend operations
4. **Visitor Pattern** → AST traversal during indexing
5. **Strategy Pattern** → Pluggable indexing strategies per language

## Quality Attributes

| Attribute | Mechanism |
|-----------|-----------|
| **Reliability** | Comprehensive testing, error recovery |
| **Scalability** | Async I/O, distributed storage support |
| **Maintainability** | Clear separation of concerns, SDKs |
| **Portability** | Hermetic builds, no external deps |
| **Security** | Token-based auth, input validation |

## Dependency Graph

```
CLI/SDKs
    ↓
gRPC Protocol (protobuf)
    ↓
Backend Core
    ├─→ Storage Interface
    ├─→ Indexing Logic
    └─→ Search Engine
        ↓
External Storage Systems
(Vector DB, Metadata DB)
```

---

See individual component docs for detailed architecture:
- Backend: `codex-rs/docs/PROJ-ARCH.md`
- CLI: `docs/codex-cli/PROJ-ARCH.md`
- SDKs: `docs/sdk/PROJ-ARCH.md`
- Build: `docs/bazel/PROJ-ARCH.md`
