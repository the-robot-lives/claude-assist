# Architecture Summary

**GenAI Local** — Elixir extension providing local LLM inference via ExLLama (llama.cpp NIF) behind the GenAI provider interface.

## Components

- **LocalLLama** — Provider entry point, implements InferenceProviderBehaviour
- **LocalLLamaManager** — Public API facade for model queries
- **LocalLLamaServer** — GenServer managing loaded model state
- **LocalLLamaSupervisor** — OTP supervisor (one_for_one)
- **EncoderProtocol** — Extensible protocol for message/tool encoding
- **Models** — Loads GGUF models from priv directory

## Inference Flow

Resolve model → encode messages/tools via protocol → build request → ExLLama.chat_completion NIF call → return ChatCompletion

## Supervision Tree

Application → LocalLLamaSupervisor → LocalLLamaServer (holds local_models map)

## Stack

Elixir 1.19 / OTP 28, ExLLama (Rust NIF / llama.cpp), GGUF model format, Mix + cmake
