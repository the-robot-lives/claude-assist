# Zellij Layouts (KDL)

> **Verified against Zellij `0.45.0`.** Examples copied from `zellij-utils/assets/layouts/`.
> Parser: `zellij-utils/src/kdl/kdl_layout_parser.rs`; types: `zellij-utils/src/input/layout.rs`.

## The Mental Model

A layout is a **tree of nested panes**, not a grid. Each `pane` either splits into children or is
a leaf holding a terminal or plugin. Sizing is resolved top-down within each split.

```kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane
    pane size=1 borderless=true {
        plugin location="status-bar"
    }
}
```
*(`assets/layouts/default.kdl` — verbatim. This is the default Zellij UI: a 1-row tab bar, the
work area, and a 1-row status bar.)*

Direct children of `layout` stack **horizontally** (rows) by default — `split_direction` on the
parent flips this.

## Node Reference

### `layout`

Root. May contain `pane`, `tab`, `pane_template`, `tab_template`, `floating_panes`,
`swap_tiled_layout`, `swap_floating_layout`.

> **`tab` and top-level `pane` are alternatives, not siblings to mix casually.** A `layout` whose
> children are `pane`s describes *one* tab's contents. Add `tab` nodes and each becomes its own tab.

### `pane`

| Property | Type | Meaning |
|---|---|---|
| `split_direction` | `"vertical"` \| `"horizontal"` | How **this pane's children** are arranged |
| `size` | int (rows/cols) or `"N%"` | Fixed or percentage extent |
| `borderless` | bool | Drop the frame (used for bars) |
| `focus` | bool | Focus this pane on load |
| `name` | string | Pane title |
| `cwd` | path | Working directory |
| `command` | string | Run this instead of the shell |
| `args` | strings | Args for `command` |
| `start_suspended` | bool | Spawn but don't run until the user says so |
| `stacked` | bool | Render children as a stack |

> `split_direction` is **case-insensitive in practice** — `assets/layouts/strider.kdl` uses
> `"Vertical"` while `default.swap.kdl` uses `"vertical"`. Prefer lowercase for consistency.

> **`split_direction` describes children, not self.** `pane split_direction="vertical" { pane; pane }`
> gives two side-by-side panes. Setting it on a leaf does nothing. This is the single most common
> layout mistake.

Commands:
```kdl
pane command="cargo" {
    args "watch" "-x" "test"
}
pane command="htop" start_suspended=true
```
> `args` is a **child node**, not a property — `args="watch -x test"` is wrong and won't parse
> as you intend.

### `tab`

```kdl
layout {
    tab name="edit" focus=true {
        pane
    }
    tab name="logs" split_direction="vertical" {
        pane
        pane
    }
}
```
Properties: `name`, `focus`, `split_direction`, `cwd`, plus `hide_floating_panes`.

### Plugin panes

```kdl
pane {
    plugin location="zellij:status-bar"
}
pane size=1 borderless=true {
    plugin location="file:/abs/path/my-plugin.wasm" {
        some_config_key "value"      // → BTreeMap<String,String> in load()
    }
}
```
`location` forms: `zellij:<builtin>`, `file:<path>`, `https://…`, or an alias from the config's
`plugins` block. Children of the `plugin` node become the plugin's configuration map.

### Templates

`pane_template` / `tab_template` define reusable shapes. The magic word is **`children`** — the
placeholder marking where the template's body is injected.

```kdl
tab_template name="ui" {
   pane size=1 borderless=true {
       plugin location="tab-bar"
   }
   children
   pane size=1 borderless=true {
       plugin location="status-bar"
   }
}

ui {          // invoke the template by name
    pane
    pane
}
```
*(from `assets/layouts/default.swap.kdl`)*

> A template **without** `children` swallows its body silently — the panes you nested inside the
> invocation simply never appear. If a templated layout renders with panes missing, look for the
> missing `children` first.
>
> `children` appears both bare (`children`) and as `{ children; }` inside a `pane`. Both are valid;
> the latter places the injection point inside that specific sub-pane.

### Floating panes

```kdl
layout {
    pane
    floating_panes {
        pane {
            x "10%"
            y "10%"
            width "80%"
            height "80%"
        }
    }
}
```
Coordinates map to `FloatingPaneCoordinates` (`zellij-utils/src/data.rs:3030`): `x`, `y`, `width`,
`height` (each percent-or-fixed), plus `pinned` and `borderless`.

### Swap layouts

The feature that makes Zellij layouts *adaptive*. Live in a **sibling `.swap.kdl`** file (e.g.
`default.kdl` + `default.swap.kdl`) or inline. Zellij picks the first swap layout whose constraint
matches the current pane count, and re-picks as panes are added/removed.

```kdl
swap_tiled_layout name="vertical" {
    ui max_panes=5 {
        pane split_direction="vertical" {
            pane
            pane { children; }
        }
    }
    ui max_panes=8 {
        pane split_direction="vertical" {
            pane { children; }
            pane { pane; pane; pane; pane; }
        }
    }
}
```
*(from `assets/layouts/default.swap.kdl` — note each variant invokes the `ui` tab_template)*

Constraints: `max_panes=N`, `min_panes=N`, `exact_panes=N`.
Also `swap_floating_layout` for the floating set.

> **Constraint ordering matters.** Variants are evaluated in order and the first match wins, so
> list them **narrowest-to-widest** (`max_panes=5` before `max_panes=8`). Reversed, the widest
> constraint matches everything and the rest are dead code — a layout that "ignores" its later
> variants almost always has this bug.
>
> This is also what `auto_layout` (config option) drives, and what
> `Action::NextSwapLayout`/`PreviousSwapLayout` cycle through manually.

## Builtin Layouts

`zellij-utils/assets/layouts/`:

| File | Purpose |
|---|---|
| `default.kdl` + `.swap.kdl` | tab-bar + status-bar |
| `compact.kdl` + `.swap.kdl` | single `compact-bar` |
| `classic.kdl` + `.swap.kdl` | the pre-0.40 look |
| `strider.kdl` + `.swap.kdl` | file-explorer sidebar |
| `welcome.kdl` | first-run screen |
| `disable-status-bar.kdl`, `no-plugins.kdl` | minimal variants |

**Read these before authoring.** They are the maintained, correct examples — `compact.kdl` is
four lines and shows the whole idea:
```kdl
layout {
    pane
    pane size=1 borderless=true {
        plugin location="compact-bar"
    }
}
```

## Using a Layout

```bash
zellij --layout ./my-layout.kdl        # a path
zellij --layout compact                # a builtin, or a name in layout_dir
zellij action new-tab --layout ./t.kdl # a tab layout at runtime
```
`layout_dir` (config / `--layout-dir` / `ZELLIJ_LAYOUT_DIR`) defaults to
`~/.config/zellij/layouts`. Plugins resolve it via `get_layout_dir()`.

## Authoring Checklist

- [ ] `split_direction` set on the **parent**, describing children
- [ ] `args` written as a child node, not a property
- [ ] Every template that should wrap content contains `children`
- [ ] Swap constraints ordered narrowest → widest
- [ ] `size` percentages within a split sum sensibly
- [ ] Bars are `size=1 borderless=true`
- [ ] No machine-specific absolute `cwd`/`command` paths if sharing the layout
- [ ] Loads cleanly and renders correctly at 80×24
- [ ] Actually opened in a live session — a parse-clean layout can still render wrong

## Debugging

| Symptom | Likely cause |
|---|---|
| Panes side-by-side when you wanted stacked | `split_direction` on the wrong node |
| Template body missing | no `children` in the template |
| Later swap variants never apply | constraints ordered widest-first |
| Plugin pane blank | bad `location`, or plugin built for another Zellij version |
| Layout ignored | wrong `layout_dir`, or name collides with a builtin |
| Command pane exits instantly | `command` not found / needs `args` as child node |

Round-trip a live session to see canonical KDL for what you have:
```bash
zellij action dump-layout
```
This is the fastest way to learn the schema — build it interactively, dump it, read the output.

## Source Map

| What | Where |
|---|---|
| Parser | `zellij-utils/src/kdl/kdl_layout_parser.rs` |
| Types (`TiledPaneLayout`, `FloatingPaneLayout`, `SwapTiledLayout`) | `zellij-utils/src/input/layout.rs` |
| `FloatingPaneCoordinates` | `zellij-utils/src/data.rs:3030` |
| Builtin layouts | `zellij-utils/assets/layouts/` |
| Parser tests (worked examples) | `zellij-utils/src/input/unit/layout_test.rs` |
| Applying a layout | `zellij-server/src/tab/layout_applier.rs` |
| Dump/restore | `zellij-utils/src/session_serialization.rs` |
