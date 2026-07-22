# queue-populator — FAQ (Summary)

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I speak a memo through an LLM classifier instead of just typing it into the right file myself?
- Why is there a human approve/revise step instead of writing the LLM's output directly?
- Why does queue-populator launch manually instead of starting automatically at login?
- Why route audio through virtual mic devices instead of just using the system default mic in Claude/Codex/etc.?

## Fit
- Is this the right tool if I just want a quick CLI note-taker?
- Is this the right tool if I'm not on macOS?
- Is this the right tool if I need multi-user or networked queue access?

## Comparison
- How does this differ from just using macOS Dictation or Siri Shortcuts?
- How does the virtual-mic feature differ from BlackHole or Loopback used directly?

## Capability
- Can I add a new destination queue file without rebuilding the app?
- Can multiple LLM providers be used, or is it locked to Anthropic?
- Can I run recognition fully on-device, with no network calls at all?

## Caveats
- What happens if I say a short/common trigger word by accident?
- What's the risk in installing the virtual-mic HAL driver?
- What happens to my queue data and config on uninstall?
- Does the memo audio get kept, and in what format?

## Trust
- Are my LLM API keys stored in plain text?
- Does any of my voice/memo content leave my Mac?
