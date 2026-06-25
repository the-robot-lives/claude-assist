# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenAI Core is an Elixir library that provides base protocols and structures for generative AI functionality. It uses a "Branch by Abstraction" pattern with vnext structures to isolate core functionality and make extensibility more straightforward.

## Common Development Commands

### Build and Dependencies
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Clean build artifacts
mix clean
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests with specific tag (e.g., :session)
mix test --only session

# Run tests with coverage
mix test --cover
```

### Code Quality
```bash
# Format code
mix format

# Run static analysis (Dialyzer) - if configured
mix dialyzer

# Generate documentation
mix docs
```

## Architecture Overview

### Directory Structure

The codebase follows a dual-structure approach with legacy and vnext implementations:

- **`lib/genai/`** - Legacy implementation structures
  - `graph/` - Graph-related functionality
  - `inference_provider/` - Provider abstractions
  - `model_meta_data/` - Model metadata handling

- **`lib/vnext_genai/`** - Next generation structures (primary focus)
  - `error/` - Error handling (e.g., RequestError)
  - `graph/` - Graph implementations with Mermaid protocol support
  - `inference_provider/` - Provider interfaces
  - `nodes/` - Various node types:
    - `chat_completion/` - Chat completion nodes
    - `message/` - Message handling with content and tool usage
    - `setting/` - Model, provider, and safety settings
    - `tool/` - Tool definitions and schemas
  - `records/` - Core record types (Directive, Node, Link)
  - `thread/` - Thread management:
    - `session/` - Session handling with state management
    - `state/` - State and directive handling

### Key Protocols and Behaviors

- **ThreadProtocol** - Main protocol for thread operations
- **DirectiveBehaviour** - Behavior for implementing directives
- **NodeProtocol** - Protocol for graph nodes
- **MermaidProtocol** - Protocol for generating Mermaid diagrams

### Core Concepts

1. **Sessions** (`GenAI.Thread.Session`) - Manage conversation state, directives, and runtime
2. **Directives** - Commands that modify session state
3. **Graph Structure** - Nodes and links forming computation graphs
4. **State Management** - Immutable state with structured access paths

### Testing Approach

- Tests use ExUnit with async capability
- Module tags for organization (e.g., `@moduletag :session`)
- Test fixtures defined within test modules
- Custom assertions in `test/support/custom_asserts.ex`

## Key Dependencies

- **noizu_labs_core** - Core utility library
- **jason** - JSON parsing
- **floki** - HTML parsing
- **finch** - HTTP client
- **ex_doc** - Documentation generation (dev only)
- **dialyxir** - Static analysis (dev only)

## Development Environment

Required versions (from .tool-versions):
- Erlang: 26.2.5.6
- Elixir: 1.16.3-otp-26
- Node.js: 23.3.0 (if needed for assets)