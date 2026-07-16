# How to: configure the LLM provider, model, and API key

**Goal:** point memo classification at the LLM provider/model you want, with
the API key stored safely.
**Prereqs:** `~/.local/bin/dc` installed (repo direnv-config tool) if you want
keys encrypted at rest; otherwise use an `env:` reference instead.

Config lives at `~/.config/queue-populator/config.json` under the `llm` key
(same schema as the macOS app, so files interchange). Edit it directly or via
the app's config window (tray → open window, if enabled by
`ui.showTranscriptWindow`).

## Supported providers

| Provider | Default model | Default base URL | Needs API key |
|---|---|---|---|
| `anthropic` | `claude-sonnet-4-20250514` | `https://api.anthropic.com/v1` | yes |
| `openai` | `gpt-4o` | `https://api.openai.com/v1` | yes |
| `groq` | `llama-3.3-70b` | `https://api.groq.com/openai/v1` | yes |
| `cerebras` | `llama-3.3-70b` | `https://api.cerebras.ai/v1` | yes |
| `deepseek` | `deepseek-chat` | `https://api.deepseek.com/v1` | yes |
| `zai` | `glm-4` | `https://api.z.ai/api/paas/v4` | yes |
| `litellm` | `claude-sonnet-4-6` | `https://inference.noizu.com/v1` | yes |
| `ollama` | `llama3` | `http://localhost:11434` | no |
| `custom` | `model-name` | (you supply `baseUrl`) | yes |

1. Set `llm.provider` to one of the values above.
2. Optionally set `llm.model` — if empty, the table default is used.
3. Set `llm.apiKey` (see key formats below). `ollama` needs none.
4. For `custom`/`litellm`/`ollama`, set `llm.baseUrl` if you're not using the
   provider default.

## API key formats accepted by `apiKey`

- **Plaintext** — `sk-...`. On next save-to-disk it is automatically
  encrypted (see below); don't hand-edit an already-encrypted value.
- **`env:VAR_NAME`** — resolved from your process/login-shell environment at
  read time (e.g. `env:ANTHROPIC_API_KEY`); never touched by the encrypt-on-save
  step. Falls back to running `$SHELL -lic` to pick up direnv/profile-only
  exports if the var isn't in the process env.
- **Unset** — falls back to the provider's well-known env var
  (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GROQ_API_KEY`, `CEREBRAS_API_KEY`,
  `DEEPSEEK_API_KEY`, `ZAI_API_KEY`/`ZHIPU_API_KEY`, `LITELLM_API_KEY`/`OPENAI_API_KEY`
  for `litellm`), resolved the same way as `env:`.

## Encryption on save

Whenever the app (or you) writes `config.json` with a plaintext `apiKey`, it
is transparently encrypted by shelling out to `~/.local/bin/dc encrypt` and
replacing the field with a `🔒:v1:...` token plus a generated
`apiKeyAlias` (e.g. `amber-arch-dove`) for identification in the UI.

**Verify:** after any save, `cat ~/.config/queue-populator/config.json | grep apiKey`
shows either `env:...` or a `🔒:v1:` token — never raw `sk-...` text.
**Gotchas:**
- `dc` missing at `~/.local/bin/dc` → save fails with "failed to encrypt API
  key — is dc installed?". Install it (`make install-utilities` from repo
  root) or switch to an `env:` reference instead.
- Editing an encrypted `apiKey` by hand corrupts it — change the underlying
  secret via `dc` (`dc config set ...`) or replace the whole field with a new
  plaintext value / `env:` reference and let the app re-encrypt.
