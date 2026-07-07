# queue-populator (Linux)

Rust port of `utilities/osx/queue-populator` for Ubuntu GNOME / PipeWire.
Voice-driven multi-channel input tool: listens for a wake phrase, records a
spoken memo, classifies it with an LLM, and appends structured JSONL entries
to queue files under `~/personal-development/queue/`. Also routes the live
microphone into virtual mic devices on voice command.

## Voice commands (defaults, configurable)

| Command | Phrase |
|---|---|
| Start memo | "hey robot" |
| End memo | "that is all" |
| Approve memo | "approve memo" |
| Approve entries | "looks good" |
| Revise entries | "revise that" |
| Cancel | "cancel that" |
| Open/close assistant mic | "robot open/close claude / codex / llama" (idle only) |

## Virtual microphones (Claude / Codex / Llama)

Four persistent PipeWire virtual sources — `Recording`, `Claude`, `Codex`,
`Llama` — are created by `config/10-robot-virtual-mics.conf` (installed to
`~/.config/pipewire/pipewire.conf.d/`). They appear as normal microphones in
GNOME Settings and browser device pickers. While queue-populator is listening
it feeds `Recording`; the assistant devices are opened/closed by voice and are
exclusive — opening one mutes the others. When muted (or when the app is not
running) a device produces silence.

## Stack

- STT: sherpa-onnx streaming zipformer (int8, on-device, English), endpoint
  detection finalizes utterances. Models in `~/.local/share/queue-populator/models`.
- Audio: PipeWire (`pipewire-rs`) — one capture stream fanned out in-process
  to STT + the four virtual sources.
- UI: ksni tray (state-colored icon + menu) + egui transcript/config/review
  windows + desktop notifications. No always-on-top overlay on GNOME Wayland.
- LLM: same providers/config-file schema as the macOS app
  (`~/.config/queue-populator/config.json`); API keys encrypted via `dc`.

## Build & install

```bash
# build deps (Ubuntu): libpipewire-0.3-dev pkg-config clang libclang-dev
# runtime helpers: ffmpeg (memo MP3 export), pipewire-utils (pw-play/pw-cli)
./install.sh        # build, install binary + pipewire config + models + autostart
queue-populator --check   # verify models, virtual mics, helpers
queue-populator           # run
./uninstall.sh      # remove binary/autostart/pipewire config (keeps config+models)
```

## Verify routing

```bash
wpctl status | grep -A6 Sources         # Recording/Claude/Codex/Llama visible
pw-record --target robot_claude t.wav   # then say "robot open claude" and speak
```
