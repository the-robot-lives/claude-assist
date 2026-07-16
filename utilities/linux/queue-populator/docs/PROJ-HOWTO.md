# How-To — queue-populator (Linux)

Task-oriented guides for things you'll actually do with this tool. For *what
it is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live*, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install queue-populator and confirm it works

**Goal:** binary, PipeWire virtual mics, and STT model installed and verified in one pass.
**Prereqs:** Ubuntu GNOME/PipeWire; build deps `libpipewire-0.3-dev pkg-config clang libclang-dev`; runtime helpers `ffmpeg`, `pipewire-utils`.

1. `./install.sh` — builds release binary, installs it to `~/.local/bin`,
   drops the PipeWire virtual-mic config, restarts PipeWire/WirePlumber,
   downloads the sherpa-onnx STT model (~200MB, once), and adds a GNOME
   autostart entry.
2. `queue-populator --check` — runs automatically at the end of `install.sh`,
   or re-run it any time.

**Verify:** `--check` prints `✓` for STT models, all four virtual sources
(`robot_recording`/`claude`/`codex`/`llama`), `ffmpeg`, `pw-play`, then
`all checks passed`.
**Gotchas:**
- `✗ virtual source ... missing` → the PipeWire config didn't apply; restart
  manually: `systemctl --user restart pipewire pipewire-pulse wireplumber`.
- `△ ffmpeg not found` → memo MP3 export is disabled but the app still runs;
  install `ffmpeg` to fix.
- Model download fails/interrupted → delete the partial dir under
  `~/.local/share/queue-populator/models/` and re-run `./install.sh`.

## How to: capture a voice memo

**Goal:** speak a memo and have it land as a structured JSONL entry in your queue.
**Prereqs:** app running (`queue-populator`, or via autostart after login).

1. Say **"hey robot"** to start recording (tray icon changes state).
2. Speak your memo.
3. Say **"that is all"** to end recording → the app transcribes, classifies
   via the configured LLM, and shows a review.
4. Say **"approve memo"** (or **"looks good"** on the classified entries) to
   commit, **"revise that"** to re-classify, or **"cancel that"** to discard.

**Verify:** the new line appears in the target file under
`~/personal-development/queue/` — see the file catalog in
[howto/queue-files.md](howto/queue-files.md) for which file a topic lands in.
**Gotchas:** wake phrase not detected → check the STT model loaded (`--check`)
and that your input mic is the one queue-populator captures (see
`recognition.inputDeviceId` in [howto/configure-llm-provider.md](howto/configure-llm-provider.md)'s
neighbor, `~/.config/queue-populator/config.json`).

## How to: let Claude/Codex/Llama "hear" me without switching mics

**Goal:** route your live voice into a browser/app's mic input by voice command, no device picker.
**Prereqs:** app running; target app's mic input set once to the matching virtual source (`Claude`, `Codex`, or `Llama`) in its own settings.

1. Say **"robot open claude"** (or `codex` / `llama`) while idle — that
   virtual source now carries your live mic; the others stay muted (silent).
2. Say **"robot close claude"** to mute it again.
3. Opening a different assistant automatically mutes the previous one —
   they're mutually exclusive.

**Verify:** `wpctl status | grep -A6 Sources` shows `Recording`/`Claude`/`Codex`/`Llama`;
`pw-record --target robot_claude test.wav` captures your voice while `Claude` is open.
**Gotchas:** commands are idle-only — mid-memo "robot open ..." is ignored;
say "that is all" or "cancel that" first.

## How to: configure the LLM provider, model, and API key
Set which LLM classifies your memos and how its key is stored.
→ *See [howto/configure-llm-provider.md](howto/configure-llm-provider.md)*

## How to: customize wake and command phrases
Change "hey robot" and the other trigger phrases to your own words.
→ *See [howto/customize-phrases.md](howto/customize-phrases.md)*

## How to: find out which queue file a memo can land in
Full catalog of the ~30 JSONL targets under `~/personal-development/queue/`.
→ *See [howto/queue-files.md](howto/queue-files.md)*

## How to: find, disable, or delete memo audio recordings
Locate the exported MP3 for each approved memo and stop or clean up that trail.
→ *See [howto/manage-memo-recordings.md](howto/manage-memo-recordings.md)*

## How to: troubleshoot a broken install (missing mics, silent app, bad key)
The sharp edges: virtual mics not appearing, STT model issues, `dc`/API key failures, debug log.
→ *See [howto/troubleshooting.md](howto/troubleshooting.md)*

## How to: pause listening or quit from the tray

**Goal:** stop the always-on wake-phrase listener temporarily, or exit the app.
**Prereqs:** app running (tray icon visible).

1. Click the tray icon → **Pause Listening** to stop reacting to the wake
   phrase without killing the process (icon dims to gray).
2. Click again to resume, or choose **Quit** to exit.

**Verify:** tray icon turns gray when paused; saying "hey robot" while paused
does nothing until you un-pause.

## How to: uninstall queue-populator

**Goal:** remove the binary, autostart entry, and PipeWire virtual-mic config.
**Prereqs:** none.

1. `./uninstall.sh`

**Verify:** `which queue-populator` fails; `wpctl status | grep -A6 Sources`
no longer lists `Recording`/`Claude`/`Codex`/`Llama`.
**Gotchas:** your `~/.config/queue-populator` (config, API key) and downloaded
STT models under `~/.local/share/queue-populator/models` are **kept** —
delete them by hand if you want a fully clean removal.
