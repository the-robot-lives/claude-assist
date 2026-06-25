# Encoding Layer

## Overview

The encoding layer translates GenAI's generic message and tool types into the format expected by the local model inference engine. It uses Elixir's protocol dispatch for extensibility.

## Protocol

`GenAI.Provider.LocalLLama.EncoderProtocol` defines a single function:

```elixir
def encode(subject, model, session, context, options)
# Returns {:ok, {encoded_map, session}}
```

## Implementations

### GenAI.Tool

Encodes tool definitions into a function-call schema:

```elixir
%{type: :function, function: %{name: ..., description: ..., parameters: ...}}
```

### GenAI.Message

Handles text and multipart content (text + images). Image content is base64-encoded inline. Output varies by content type:

- **String content** → `%{role: role, content: text}`
- **List content** → `%{role: role, content: [%{type: :text, ...}, %{type: :image_url, ...}]}`

### GenAI.Message.ToolResponse

Encodes tool results with JSON-serialized response body:

```elixir
%{role: :tool, tool_call_id: ..., content: Jason.encode!(response)}
```

### GenAI.Message.ToolUsage

Encodes assistant messages containing tool calls, with each call's arguments JSON-serialized.

## Extensibility

To support a new message type, implement `GenAI.Provider.LocalLLama.EncoderProtocol` for it. For types that are variations of existing ones, cast to a known type and re-invoke the protocol.

## Encoder Behaviour

`GenAI.Provider.LocalLLama.Encoder` uses `GenAI.Model.EncoderBehaviour` but is currently a stub — the protocol implementations handle all encoding. The behaviour module exists as a hook point for model-specific encoding overrides.
