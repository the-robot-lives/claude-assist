# FAQ: Comparison — queue-populator (Linux)

Full treatment of the "how does this differ from Y" questions. Short
answers live in [PROJ-FAQ.md](../PROJ-FAQ.md#comparison).

### How does this differ from the macOS `queue-populator`?

Same config schema, queue format, and manifest (files interchange between
machines), but a different implementation end to end: Rust instead of Swift,
PipeWire instead of CoreAudio, ksni/egui instead of AppKit, and no
always-on-top overlay (not available on GNOME Wayland). Functionally
near-identical; expect Linux-specific rough edges the macOS app doesn't have
(see [Caveats](../PROJ-FAQ.md#caveats)).

→ *See [PROJ-ARCH.md](../PROJ-ARCH.md) for the architecture and
`../../osx/queue-populator` for the original.*

### Why virtual mic devices instead of a browser extension or OS-level "mic sharing" feature?

Browser extensions only cover browser tabs; this covers any app that reads a
PipeWire/PulseAudio source, including native apps and non-Chromium browsers.
It also requires zero per-site permissions — the virtual device just looks
like a normal microphone to anything that queries audio sources.

### How is this different from just keeping four browser tabs open, one per assistant, each with mic already granted?

That works too, and needs no PipeWire config — but you're limited to
browser-based assistants and still juggle tabs/windows. This tool's routing
is app-agnostic (native apps included) and switches with a spoken command
instead of an alt-tab.
