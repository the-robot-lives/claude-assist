# How to: configure the LLM provider and API key

**Goal:** point queue-populator at your preferred LLM (Anthropic, OpenAI, Groq, Cerebras, DeepSeek, Z.AI, LiteLLM, Ollama, or a custom OpenAI-compatible endpoint) for memo classification.
**Prereqs:** the app installed and launched at least once (creates `~/.config/queue-populator/`).

## Option A — env var (fastest, no UI)

Export the provider's key in your shell profile before launching the app; it's picked up automatically per-provider:

| Provider | Env var |
|---|---|
| anthropic (default) | `ANTHROPIC_API_KEY` |
| openai | `OPENAI_API_KEY` |
| groq | `GROQ_API_KEY` |
| cerebras | `CEREBRAS_API_KEY` |
| deepseek | `DEEPSEEK_API_KEY` |
| zai | `ZAI_API_KEY` (falls back to `ZHIPU_API_KEY`) |
| litellm | `LITELLM_API_KEY` (falls back to `OPENAI_API_KEY`) |

`ollama` and `custom` need no key by default; `litellm`/`ollama`/`custom` also need a base URL (see Option B).

## Option B — Configure dialog (for a non-default provider/model/base URL)

1. Click the menu bar icon → **Configure...**.
2. Under the LLM section, pick **Provider** from the dropdown; the **Base URL** and **Model** fields auto-fill with defaults for that provider.
3. To use a different model, click **Fetch Models** (queries the provider's `/models` endpoint) and pick from the list, or type one directly.
4. To store a key through the UI instead of an env var, type it into **API Key** and save — it is encrypted at rest via `dc` (see Gotchas) and stored in `~/.config/queue-populator/config.json` as a `🔒:v1:...` token, never plaintext.
5. To force a specific env var name regardless of provider default, type `env:MY_VAR_NAME` into **API Key**.

**Verify:**
```bash
cat ~/.config/queue-populator/config.json   # llm.provider / llm.model / llm.apiKeyAlias
```
Speak a memo end-to-end (see [first-hour.md](first-hour.md)) and confirm the Review window shows classified entries instead of an error.

**Gotchas:**
- "Failed to encrypt API key. Is dc installed at ~/.local/bin/dc?" → the encryption step shells out to this repo's `dc` secret tool; install it first (`make install-utilities` from repo root), or paste `env:VARNAME` instead to skip encryption entirely.
- Env var not found even though it's exported → `EnvResolver` falls back to shelling out via your login shell (`$SHELL -lic`) if `ProcessInfo` doesn't have it (e.g. launched from Finder, not a terminal); make sure the var is set in your shell rc file, not just the current terminal session.
- `ollama`/`litellm`/`custom` return errors → these need **Base URL** set (Ollama default `http://localhost:11434`, LiteLLM default `https://inference.noizu.com/v1`); confirm the endpoint is reachable.
