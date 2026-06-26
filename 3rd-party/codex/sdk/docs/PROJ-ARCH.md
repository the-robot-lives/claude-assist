# Codex SDKs — Architecture

## Overview

Multi-language client libraries providing programmatic access to Codex backend services. Each SDK abstracts away HTTP/gRPC protocol details and offers idiomatic interfaces for its target language.

## Architecture

```
Application Code
     ↓ (imports SDK)
Python SDK | TypeScript SDK
     ↓
  Protocol Buffers / gRPC
     ↓
Codex Backend API (codex-rs)
```

## SDK Design

Each SDK (Python, TypeScript) provides:

| Component | Purpose |
|-----------|---------|
| **Client Class** | Main entry point for API access |
| **Protocol Bindings** | Generated gRPC/protobuf code |
| **Request/Response Types** | Strongly typed data structures |
| **Authentication** | Token/credential handling |
| **Error Mapping** | Language-specific exception types |

## Python SDK (`sdk/python/`)

- **Runtime**: Python 3.x
- **Protocol**: gRPC (protobuf generated)
- **Package Manager**: Poetry
- **Key Features**:
  - Async/await support (asyncio)
  - Sync and async clients
  - Type hints for IDE support
  - Comprehensive test suite

## TypeScript SDK (`sdk/typescript/`)

- **Runtime**: Node.js, Browser (ESM/CommonJS)
- **Protocol**: gRPC-web (for browser compatibility)
- **Package Manager**: npm/yarn
- **Key Features**:
  - Promise-based async API
  - TypeScript types generated from protobuf
  - Tree-shakeable exports
  - Browser and server-side usage

## Shared Patterns

1. **Protocol Abstraction** — Both SDKs hide gRPC complexity
2. **Generated Code** — Protocol definitions in parent generate SDK stubs
3. **Error Handling** — Map backend errors to language conventions
4. **Authentication** — Inject credentials into request metadata

## Python Runtime (`sdk/python-runtime/`)

Utility functions and classes shared across Python implementations:
- Connection pooling
- Retry logic
- Logging infrastructure
- Common type conversions

## Design Goals

- **Language Idiomaticity** — Each SDK feels native to its language
- **Code Generation** — Minimize hand-written code; use protobuf generators
- **Consistency** — Identical operations produce similar interfaces across SDKs
- **Minimal Dependencies** — Keep SDKs lightweight for easy integration
