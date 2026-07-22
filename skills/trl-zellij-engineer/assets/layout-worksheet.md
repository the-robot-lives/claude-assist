# Zellij Layout — Design Worksheet

> Copy into your project. Fill the top half before writing any KDL.

## Purpose

*One sentence: what is this layout for, and who opens it?*

| Field | Value |
|-------|-------|
| **Layout name** | |
| **Zellij version** | |
| **Shared with others?** | yes / no *(if yes: no absolute paths — use plugin aliases)* |
| **Target terminal size** | *(must survive 80×24)* |

## Shortcut First

If you can build the arrangement by hand in a live session:

```bash
zellij action dump-layout
```

That emits **canonical KDL for the current session** — faster than authoring from scratch and
always schema-correct. Start there and edit, unless the layout is conditional/templated.

- [ ] Considered `dump-layout` before hand-authoring

## Content Inventory

| Pane | What runs in it | Fixed size? | Notes |
|------|-----------------|-------------|-------|
| | | | |
| | | | |

## Sketch

*ASCII at your target size. Do this before KDL — it catches `split_direction` mistakes early.*

```
┌──────────────────────────────────────┐
│ tab-bar                       size=1 │
├──────────────────┬───────────────────┤
│                  │                   │
│                  │                   │
│                  ├───────────────────┤
│                  │                   │
├──────────────────┴───────────────────┤
│ status-bar                    size=1 │
└──────────────────────────────────────┘
```

## Tree

*Express the nesting. Remember: `split_direction` goes on the **parent** and describes how its
**children** are arranged.*

```
layout
├── pane size=1 borderless=true (tab-bar)
├── pane split_direction="vertical"
│   ├── pane            ← editor
│   └── pane
│       ├── pane        ← shell
│       └── pane        ← logs
└── pane size=1 borderless=true (status-bar)
```

## Tabs

- [ ] Single tab (top-level `pane`s)
- [ ] Multiple tabs (`tab` nodes)

| Tab | Name | Focus? | Contents |
|-----|------|--------|----------|
| | | | |

## Floating Panes

- [ ] None
- [ ] Yes → coordinates below

| Pane | x | y | width | height | pinned |
|------|---|---|-------|--------|--------|
| | | | | | |

## Templates

Only if a shape repeats.

- [ ] Not needed
- [ ] `pane_template` / `tab_template` used

| Template | Wraps | Has `children`? |
|----------|-------|-----------------|
| | | ☐ |

> A template **without** `children` silently swallows its body — the panes nested inside the
> invocation just never appear. If panes are missing, check this first.

## Swap Layouts

Does the useful arrangement change with pane count?

- [ ] No — skip
- [ ] Yes → variants below

| Variant | Constraint | Arrangement |
|---------|-----------|-------------|
| | `max_panes=` | |
| | `max_panes=` | |

- [ ] Constraints ordered **narrowest → widest** (first match wins; reversed makes later variants
      dead code)
- [ ] `auto_layout` behavior considered

## Authoring Checklist

- [ ] Read `zellij-utils/assets/layouts/{default,compact,strider}.kdl` first — maintained,
      correct examples beat recalled schema
- [ ] `split_direction` on parents, describing children
- [ ] `args` written as a **child node**, not a property (`pane command="cargo" { args "watch" }`)
- [ ] Bars are `size=1 borderless=true`
- [ ] Sizes within each split sum sensibly
- [ ] Plugin panes use an **alias**, not an absolute path (if shared)
- [ ] No machine-specific `cwd` (if shared)
- [ ] `focus=true` on at most one pane

## Verification

**Parsing clean ≠ rendering right.** Open it.

| Check | Result |
|-------|--------|
| Loads without error (`zellij --layout ./x.kdl`) | |
| Renders as sketched | |
| **80×24** | |
| Resize behaves | |
| Swap variants fire (add/remove panes) | |
| Commands actually start | |

## Symptom → Cause

| Symptom | Look at |
|---|---|
| Panes side-by-side when you wanted stacked | `split_direction` on the wrong node |
| Template body missing | no `children` in the template |
| Later swap variants never apply | constraints ordered widest-first |
| Plugin pane blank | bad `location`, or plugin built for another Zellij version |
| Layout ignored | wrong `layout_dir`, or name collides with a builtin |
| Command pane exits instantly | command not found, or `args` written as a property |

## Notes / Decisions
