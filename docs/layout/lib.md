# lib/ — Application Source

```
lib/
├── application.ex                  # GenAILocal.Application — OTP app, starts supervisor
├── local_llama.ex                  # GenAI.Provider.LocalLLama — main provider module
└── local_llama/
    ├── encoder.ex                  # GenAI.Provider.LocalLLama.Encoder — prompt encoding
    ├── encoder_protocol.ex         # GenAI.Provider.LocalLLama.EncoderProtocol — encoding protocol
    ├── models.ex                   # GenAI.Provider.LocalLLama.Models — model listing/metadata
    └── manager/
        ├── local_llama_manager.ex      # GenAI.Provider.LocalLLamaManager — model lifecycle
        ├── local_llama_server.ex       # GenAI.Provider.LocalLLamaServer — GenServer for inference
        └── local_llama_supervisor.ex   # GenAI.Provider.LocalLLamaSupervisor — supervision tree
```

## Module Overview

- **LocalLLama** — Top-level provider implementing the GenAI provider interface
- **Encoder / EncoderProtocol** — Handles prompt formatting for different model architectures
- **Models** — Discovers and lists available local models
- **Manager** — OTP supervision tree managing model server lifecycles
