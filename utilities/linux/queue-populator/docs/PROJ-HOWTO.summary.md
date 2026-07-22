# PROJ-HOWTO Summary — queue-populator (Linux)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **Install queue-populator and confirm it works** — binary, PipeWire virtual mics, and STT model installed and verified in one pass.
- **Capture a voice memo** — speak a memo and have it land as a structured JSONL entry in your queue.
- **Let Claude/Codex/Llama "hear" me without switching mics** — route your live voice into a browser/app's mic input by voice command, no device picker.
- **Configure the LLM provider, model, and API key** — set which LLM classifies your memos and how its key is stored.
- **Customize wake and command phrases** — change "hey robot" and the other trigger phrases to your own words.
- **Find out which queue file a memo can land in** — full catalog of the ~30 JSONL targets under `~/personal-development/queue/`.
- **Find, disable, or delete memo audio recordings** — locate the exported MP3 for each approved memo and stop or clean up that trail.
- **Troubleshoot a broken install** — the sharp edges: virtual mics not appearing, STT model issues, `dc`/API key failures, debug log.
- **Pause listening or quit from the tray** — stop the always-on wake-phrase listener temporarily, or exit the app.
- **Uninstall queue-populator** — remove the binary, autostart entry, and PipeWire virtual-mic config.
