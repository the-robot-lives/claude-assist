# How to: troubleshoot a broken install

**Goal:** diagnose the common failure modes without reading source.
**Prereqs:** `queue-populator --check` is your first move for every symptom below.

## Virtual mic source missing (`✗ virtual source robot_claude missing`)

1. Confirm the drop-in is installed:
   `ls ~/.config/pipewire/pipewire.conf.d/10-robot-virtual-mics.conf`
   — if missing, `cp config/10-robot-virtual-mics.conf ~/.config/pipewire/pipewire.conf.d/`.
2. Restart PipeWire: `systemctl --user restart pipewire pipewire-pulse wireplumber`.
3. Re-run `queue-populator --check`.

**Gotchas:** a stale WirePlumber session can hold old node names — full
logout/login (or reboot) clears it if step 2 doesn't.

## STT model not found (`✗ ...` under models)

1. Check the model dir: `ls ~/.local/share/queue-populator/models/` — expects
   `sherpa-onnx-streaming-zipformer-en-2023-06-26/tokens.txt`.
2. If partial/corrupt, delete the model subdirectory and re-run `./install.sh`
   to re-download (~200MB).
3. Custom model location: set `QP_MODEL_DIR` before running `install.sh`.

## App runs but never hears the wake phrase

1. `wpctl status | grep -A6 Sources` — confirm your physical mic is the
   default source, or set `recognition.inputDeviceId` in
   `~/.config/queue-populator/config.json` to pin it explicitly.
2. Check `~/.config/queue-populator/debug.log` (truncated fresh each launch)
   for STT engine start errors.
3. Run with extra logging: `queue-populator --verbose` (stderr, also mirrored
   to `debug.log`).

## LLM classification fails / memo stuck in Processing

1. `queue-populator --verbose`, then trigger a memo — look for HTTP errors
   from the `llm/` client in stderr/`debug.log`.
2. Verify the key resolves: if using `env:VAR`, confirm
   `echo $VAR` (or your shell profile) actually has it set; the resolver
   falls back to a login shell (`$SHELL -lic`) but a broken profile script
   can break that fallback too.
3. Wrong `baseUrl` for `custom`/`litellm`/`ollama` providers is the most common
   cause of connection-refused — see
   [configure-llm-provider.md](configure-llm-provider.md).

## Config won't save / API key encryption fails

`failed to encrypt API key — is dc installed at ~/.local/bin/dc?` — install
the repo's `dc` tool (`make install-utilities` from the monorepo root) or
switch the key to an `env:VAR_NAME` reference, which bypasses encryption
entirely.

## Sound cues or memo MP3 export missing

`--check` shows `△ ffmpeg not found` or `△ pw-play not found` — these are
soft dependencies; install `ffmpeg` (MP3 export) and/or `pipewire-utils`
(`pw-play`, sound cues). The app still runs without them.
