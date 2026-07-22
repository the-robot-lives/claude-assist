# Prompt Optimizer — Run Tracker

Track a single optimization run (one source prompt → variants → promoted best). Copy per run.

## Run Metadata
- **Source prompt:** <path, e.g. CLAUDE.md>
- **Target axis:** <compactness N | token_budget T | style S>
- **Declared intent / key_requirements:** <short statement>
- **Protect:** <list>
- **Lossy_ok:** <list>
- **NPL detected?:** <yes (NPLLoad/NPLSpec | projects/NoizuPromptLingo) | no — using static pointers>
- **Baseline size:** <bytes / tokens>
- **Date:** <YYYY-MM-DD>

## Phase Checklist

| Phase | Status | Notes |
|-------|--------|-------|
| 1. Intake (intent, axes, baseline size) | ☐ Not Started | — |
| 2. Classify (rules / reference / filler) | ☐ Not Started | — |
| 3. Transform (compress / restyle / NPL) | ☐ Not Started | — |
| 4. Ledger (what / why / recoverable-where) | ☐ Not Started | — |
| 5. Evaluate (rubric + dataset + adhoc) | ☐ Not Started | — |
| 6. Select (pin / repoint symlink) | ☐ Not Started | — |

## Variant Tracker

| slug | level | style | size (tok) | aggregate | required_pass | pass? | notes |
|------|-------|-------|-----------|-----------|---------------|-------|-------|
| baseline | 0 | — | — | (reference) | — | — | retained forever |
| <slug> | <n> | <style> | <n> | <0-1> | <all/which> | ☐ | — |

## Selection

- **Pinned target:** <slug> — <reason (best passing within budget | explicit pin)>
- **Symlink:** `<name>.md -> .<name>.md/<slug>.md`
- **Failing variants:** <slug → the case it failed>
- **Budget note:** <met | reached level N to fit | protect overage of X>

## Ledger Rollup (across promoted variant)

| what | why | recoverable-where | verified? |
|------|-----|-------------------|-----------|
| <fact> | <level/method> | <docs/… | NPLLoad … | DROPPED> | ☐ |

## Handoff / Follow-ups
- <e.g. lift into MCP prompt-store record; add adhoc case to spec dataset; media-tool AssetType::Prompt not yet wired>
