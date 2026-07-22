# How to: route your voice into Claude/Codex/Llama as a virtual microphone

**Goal:** let another app (browser, voice client, Zoom, OBS) pick "Claude"/"Codex"/"Llama" as its input mic and receive your live voice on command, without it also hearing when you don't want it to.
**Prereqs:** queue-populator installed and running (see [first-hour.md](first-hour.md)); full Xcode app (not just Command Line Tools) for the one-time driver build; admin password.

1. Build and install the four virtual mic devices (one-time, needs Xcode + admin):
   ```bash
   cd utilities/osx/queue-populator/Driver
   ./build-virtual-mics.sh
   ```
   This clones a pinned BlackHole ref, builds four uniquely-named/UID'd HAL drivers (`Recording`, `Claude`, `Codex`, `Llama`), ad-hoc signs them, installs to `/Library/Audio/Plug-Ins/HAL/`, and restarts `coreaudiod`.

2. In the target app, select **Claude** (or **Codex** / **Llama**) as the microphone input.

3. While queue-populator is listening (menu bar app running, not paused), speak:
   - `"robot open claude"` — starts routing your live mic into the Claude device
   - `"robot close claude"` — mutes it again
   (same pattern for `codex` / `llama`)

**Verify:**
```bash
system_profiler SPAudioDataType | grep -A2 "Recording:\|Claude:\|Codex:\|Llama:"
```
All four devices should be listed. `Recording` carries audio whenever queue-populator is listening; `Claude`/`Codex`/`Llama` are silent until opened by voice command.

**Gotchas:**
- Opening one assistant device mutes the others — routing is exclusive by design, so only one of Claude/Codex/Llama carries audio at a time. `Recording` is unaffected.
- Build fails without Xcode → the Command Line Tools alone aren't enough; install full Xcode from the App Store first.
- To remove the devices: `./uninstall-virtual-mics.sh` (same directory).
- Full background and design rationale (why BlackHole, signing/Gatekeeper notes, override env vars like `CHANNELS`/`BLACKHOLE_REF`): [`Driver/README.md`](../../Driver/README.md).
