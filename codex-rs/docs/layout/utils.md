# Utilities Layout

## Overview

Utility crates provide foundational, reusable code shared across the Codex project. These are typically low-level, domain-agnostic helpers with minimal dependencies.

## Async & Concurrency

```
async-utils/                 # Async utilities and helpers
                             # - Channel wrappers
                             # - Stream combinators
                             # - Timeout/cancellation helpers
```

## Encoding & Data Formats

```
ansi-escape/                 # ANSI escape sequence parsing and rendering
                             # - Color codes
                             # - Text styling (bold, underline, etc.)
                             # - Sequence manipulation
```

## Process & System

```
arg0/                        # Process argv[0] manipulation
                             # - Self-identification
                             # - Command name detection
```

## IPC & Transport

```
uds/                         # Unix-domain-socket utilities
                             # - Socket creation and connection
                             # - Listener abstractions
                             # - Error handling

stdio-to-uds/                # Bridge between stdio and Unix sockets
                             # - Used for sandboxed communication
                             # - Subprocess I/O redirection
```

## Patching & Transformation

```
apply-patch/                 # Patch application (binary and library)
                             # - Unified diff parsing
                             # - File patching
                             # - Conflict detection
```

## Network & Proxying

```
network-proxy/               # Network proxy support
                             # - Proxy configuration
                             # - Protocol handling (HTTP/HTTPS, SOCKS)
                             # - Connection routing
```

## Observability & Telemetry

```
otel/                        # OpenTelemetry instrumentation
                             # - Trace context propagation
                             # - Metric exports
                             # - Span instrumentation

analytics/                   # Analytics event types and reporting
                             # - Event schema
                             # - Telemetry ingestion
                             # - User analytics
```

## Real-Time Communication

```
realtime-webrtc/             # WebRTC real-time support
                             # - RTC session management
                             # - Data channel handling
                             # - Connection negotiation
```

## Design Principles

### Minimal Dependencies
- Prefer standard library when possible
- Reduce transitive dependency load
- Document external dependencies clearly

### Broad Reusability
- Design for multiple use cases
- Avoid domain-specific assumptions
- Keep concerns separated

### Documentation
- Include usage examples in doc comments
- Document error cases
- Provide clear integration patterns

### Testing
- Test in isolation
- Provide both unit and integration tests
- Use mock/stub patterns where needed

## Usage Guidelines

### When to Add a Utility Crate
- Code used by 3+ other crates
- Foundational capability with generic utility
- Distinct responsibility from core engine

### When to Inline
- Code used by 1-2 crates
- Tightly coupled to domain logic
- Specific to single context

### Integration Pattern
```rust
// In your crate
use utils::{async_utils, ansi_escape};

// Use helpers
let formatted = ansi_escape::ColorCode::Blue.apply("text");
```

