# queue-populator — How-To (Summary)

Quick task index. Full steps in [PROJ-HOWTO.md](PROJ-HOWTO.md) and `howto/`.

- **Build, install, and verify it for the first time** — get the app installed, permissioned, and capturing your first voice memo into a queue file.
- **Configure the LLM provider and API key** — point queue-populator at Anthropic, OpenAI, Groq, Cerebras, DeepSeek, Z.AI, LiteLLM, Ollama, or a custom endpoint, and store the key safely.
- **Capture and approve a voice memo (the everyday workflow)** — speak an item and have it land in the right queue file.
- **Change wake/trigger phrases or the queue base path** — use your own wording for wake/end/approve/cancel/revise/memo-approve, or point the queue at a different directory.
- **Route your voice into Claude/Codex/Llama as a virtual microphone** — let another app receive your live voice as a selectable input device, opened/closed by voice command.
- **Add a new queue category** — add a target `.jsonl` file the LLM can route memos into.
- **Debug when something isn't working** — find out why a memo wasn't captured, classified, or written, using the structured debug log.
- **Uninstall** — remove the app, its launch agent, and old binaries, without touching your queue data or config.
