# FAQ Summary — queue-populator (Linux)

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use a voice memo tool that classifies with an LLM instead of just typing a note?
- Why route my mic through virtual PipeWire devices instead of just switching each app's mic input?
- Why on-device STT (sherpa-onnx) instead of a cloud speech API?

## Fit
- When is this the wrong tool for me?
- I already use OS-level dictation (e.g. GNOME's built-in Whisper). Do I still need this?
- Does this help if I mostly work at a desk with a keyboard in reach?
- Why would I pause listening instead of just quitting the app?

## Comparison
- How does this differ from the macOS `queue-populator`?
- Why virtual mic devices instead of a browser extension or OS-level "mic sharing" feature?
- How is this different from just keeping four browser tabs open, one per assistant, each with mic already granted?

## Capability
- Can I use this without paying for an LLM API?
- Can I tell it by voice which file a memo should go to?
- Can I route my mic to two assistants (e.g. Claude and Codex) at the same time?
- Does queue-populator work fully offline?

## Caveats
- What does an always-on wake-phrase listener cost me in resources/privacy?
- What does each memo classification cost in LLM API spend?
- Are my voice recordings kept anywhere?
- What happens if the fuzzy wake/command phrase misfires?

## Trust
- Is my LLM API key stored in plaintext?
- What does the configured LLM provider actually see?
- Does uninstalling remove my memo history and config?
