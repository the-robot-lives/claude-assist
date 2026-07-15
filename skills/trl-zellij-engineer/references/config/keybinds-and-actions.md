# Zellij Keybinds & the Action Vocabulary

> **Verified against Zellij `0.45.0`.** Examples copied from `zellij-utils/assets/config/default.kdl`.
> `Action`: `zellij-utils/src/input/actions.rs:117` (**137 variants**). `InputMode`:
> `zellij-utils/src/data.rs:1146`.

## Modes

Zellij is **modal**. A key means different things per mode, and every binding lives inside a mode
block. `InputMode` (`data.rs:1146`):

| Mode | Purpose |
|---|---|
| `Normal` | Input goes to the terminal; only mode-entry shortcuts intercepted |
| `Locked` | **Everything** goes to the terminal except the key back to Normal |
| `Pane` | Create/close/move between panes |
| `Tab` | Create/close/move between tabs |
| `Resize` | Resize panes |
| `Move` | Move panes around |
| `Scroll` | Scroll within a pane |
| `Search` | Search the scrollback (superset of Scroll) |
| `EnterSearch` | Type the search needle |
| `RenameTab` / `RenamePane` | Type a new name |
| `Session` | Session management |
| `Tmux` | tmux-compatible bindings |
| `Prompt` | Confirmation prompts |

`Locked` exists because Zellij's shortcuts otherwise collide with the apps running inside it —
it's the escape hatch for nested multiplexers and TUI apps that want raw keys.

## Bind Syntax

```kdl
keybinds {
    pane {
        bind "Ctrl p" { SwitchToMode "Normal"; }
        bind "h" "Left" { MoveFocus "Left"; }        // multiple keys, same action
        bind "n" { NewPane; SwitchToMode "Normal"; } // multiple actions, in order
        bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0; }
    }
}
```
*(verbatim from `default.kdl`)*

Rules worth internalizing:
- **`bind` takes N keys** — `bind "h" "Left"` binds both to the same action list.
- **The block is an ordered action *list*.** `{ NewPane; SwitchToMode "Normal"; }` runs both.
  This is why nearly every binding ends with `SwitchToMode "Normal"` — Zellij does not auto-return
  from a mode. **Omit it and the user is stuck in Pane mode** wondering why their typing does
  nothing. This is the #1 custom-keybind bug.
- **Semicolons matter.** Each action is `;`-terminated inside the block.
- Arguments are quoted strings or bare numbers: `Resize "Increase Left"`, `PaneNameInput 0`.

### Key names

`"Ctrl g"`, `"Alt c"`, `"Left"`, `"Tab"`, `"="`, `"+"`, `"-"`, `"]"`, and plain chars `"h"`.
Case is significant: `"H"` is shift-h (`bind "H" { Resize "Decrease Left"; }`).

### Shared bindings

Avoid repeating a binding in every mode:

```kdl
shared_except "locked" {
    bind "Ctrl g" { SwitchToMode "Locked"; }
}
shared_except "pane" "locked" {
    bind "Ctrl p" { SwitchToMode "Pane"; }
}
shared_among "pane" "tab" {
    bind "x" { CloseFocus; }
}
```
*(`shared_except` at `default.kdl:191,209-230`)*

`shared_except "locked"` is the dominant idiom: bind everywhere **except** Locked — which is
precisely what makes Locked an escape hatch.

### Removing bindings

```kdl
keybinds clear-defaults=true {   // drop ALL defaults, start clean
    normal { }
}

keybinds {
    pane {
        unbind "x"               // remove one default
    }
}
```
> `clear-defaults=true` is all-or-nothing and leaves you with **no way to reach any mode** unless
> you rebind it yourself. `unbind` is almost always what you want.

## The Action Vocabulary

The **same 137 `Action` variants** back keybinds, the `zellij action` CLI, and plugin `run_action`.
Learn once, use in three places. (KDL uses `PascalCase`; the CLI uses `kebab-case`:
`Action::SaveSession` ↔ `zellij action save-session`.)

Grouped from `actions.rs:117`:

| Group | Actions |
|---|---|
| **Modes/meta** | `Quit`, `SwitchToMode`, `SwitchModeForAllClients`, `Detach`, `NoOp`, `Confirm`, `Deny`, `SkipConfirm` |
| **Write** | `Write`, `WriteChars`, `WriteToPaneId`, `WriteCharsToPaneId`, `Paste` |
| **Focus** | `FocusNextPane`, `FocusPreviousPane`, `SwitchFocus`, `MoveFocus`, `MoveFocusOrTab`, `FocusPaneByPaneId`, `FocusTerminalPaneWithId`, `FocusPluginPaneWithId` |
| **Move panes** | `MovePane`, `MovePaneBackwards`, `MovePaneByPaneId`, `MovePaneBackwardsByPaneId` |
| **Resize** | `Resize`, `ResizeByPaneId` |
| **New panes** | `NewPane`, `NewTiledPane`, `NewFloatingPane`, `NewInPlacePane`, `NewStackedPane`, `NewBlockingPane`, `EditFile`, `Run` |
| **New plugin panes** | `NewTiledPluginPane`, `NewFloatingPluginPane`, `NewInPlacePluginPane`, `LaunchPlugin`, `LaunchOrFocusPlugin`, `StartOrReloadPlugin` |
| **Close** | `CloseFocus`, `CloseFocusByPaneId`, `CloseTerminalPane`, `ClosePluginPane`, `CloseTab`, `CloseTabById` |
| **Fullscreen/float/frames** | `ToggleFocusFullscreen`, `ToggleFocusFullscreenByPaneId`, `TogglePaneFrames`, `TogglePaneEmbedOrFloating`(`ByPaneId`), `ToggleFloatingPanes`(`ByTabId`), `ShowFloatingPanes`, `HideFloatingPanes`, `AreFloatingPanesVisible`, `TogglePanePinned`(`ByPaneId`), `TogglePaneBorderless`, `SetPaneBorderless`, `StackPanes`, `ChangeFloatingPaneCoordinates` |
| **Scroll** | `ScrollUp`/`Down`(`At`), `ScrollToTop`/`Bottom`, `PageScrollUp`/`Down`, `HalfPageScrollUp`/`Down`, and `*ByPaneId` variants |
| **Tabs** | `NewTab`, `GoToNextTab`, `GoToPreviousTab`, `GoToTab`, `GoToTabName`, `GoToTabById`, `ToggleTab`, `MoveTab`, `MoveTabByTabId`, `ToggleActiveSyncTab`(`ByTabId`), `QueryTabNames`, `CurrentTabInfo` |
| **Naming** | `PaneNameInput`, `UndoRenamePane`(`ByPaneId`), `TabNameInput`, `UndoRenameTab`(`ByTabId`), `RenameTab`, `RenameTabById`, `RenameTerminalPane`, `RenamePluginPane`, `RenamePaneByPaneId`, `RenameSession` |
| **Break panes** | `BreakPane`, `BreakPaneRight`, `BreakPaneLeft` |
| **Screen/scrollback** | `ClearScreen`(`ByPaneId`), `DumpScreen`, `DumpLayout`, `EditScrollback`(`ByPaneId`), `SaveSession` |
| **Search** | `SearchInput`, `Search`, `SearchToggleOption` |
| **Layout** | `PreviousSwapLayout`(`ByTabId`), `NextSwapLayout`(`ByTabId`), `OverrideLayout` |
| **Theme** | `SetDarkTheme`, `SetLightTheme`, `ToggleTheme`, `SetPaneColor` |
| **Mouse** | `MouseEvent`, `ToggleMouseMode` |
| **Clipboard** | `Copy` |
| **Session** | `SwitchSession`, `ListClients`, `ListPanes`, `ListTabs` |
| **Pipes** | `CliPipe`, `KeybindPipe` |
| **Grouping** | `TogglePaneInGroup`, `ToggleGroupMarking` |

> **The `*ByPaneId` / `*ByTabId` pattern.** Most actions come in two forms: implicit (acts on the
> focused pane/tab) and explicit (takes an id). Keybinds almost always want the implicit form —
> the user's focus *is* the target. The `ById` forms exist for plugins and scripts acting on panes
> they didn't focus. Reaching for `ById` in a keybind is usually a mistake.

## The Same Vocabulary from the CLI

```bash
zellij action new-pane --direction right
zellij action go-to-tab-name "logs"
zellij action dump-layout
zellij action write-chars "hello"
```
`CliAction` (`zellij-utils/src/cli.rs`) mirrors `Action`, and
`zellij-utils/src/input/actions.rs:904` maps `CliAction → Vec<Action>`.

> One `CliAction` may expand to **several** `Action`s (the return is `Vec<Action>`), so CLI and
> keybind behavior can differ subtly for composite verbs. `zellij action --help` is generated from
> the same source — trust it over any doc.

## Worked Example: a custom binding

Goal: `Alt f` opens a floating pane running `lazygit`, from any mode except Locked.

```kdl
keybinds {
    shared_except "locked" {
        bind "Alt f" {
            Run "lazygit" {
                floating true
            };
            SwitchToMode "Normal";
        }
    }
}
```
Checks: bound outside Locked ✓, returns to Normal ✓, `;` after each action ✓.

## Debugging

| Symptom | Cause |
|---|---|
| Key does nothing | Bound in the wrong mode, or you're in `Locked` |
| Stuck in a mode | Missing trailing `SwitchToMode "Normal"` |
| Key works in some modes only | Needs `shared_except "locked"` |
| Config won't load | Unknown action name, or a missing `;` |
| Binding shadows an app | Rebind, or teach users `Locked` mode |
| Behavior differs CLI vs keybind | Composite `CliAction` expanding to several `Action`s |

Inspect the live mapping:
```bash
zellij setup --dump-config      # the full effective config incl. defaults
zellij action --help            # the CLI surface of the same vocabulary
```

## Checklist

- [ ] Binding lives in the right mode block
- [ ] Trailing `SwitchToMode "Normal"` where the user should return
- [ ] `;` after each action
- [ ] `shared_except "locked"` for global bindings
- [ ] Action name matches the `Action` variant exactly (PascalCase)
- [ ] Implicit (focused) form used, not `*ByPaneId`, unless targeting deliberately
- [ ] Doesn't shadow a default users rely on (`unbind` explicitly if intended)
- [ ] Pressed the key in a live session

## Source Map

| What | Where |
|---|---|
| `Action` (137 variants) | `zellij-utils/src/input/actions.rs:117` |
| `InputMode` | `zellij-utils/src/data.rs:1146` |
| KDL → Action | `zellij-utils/src/kdl/mod.rs` |
| `CliAction` | `zellij-utils/src/cli.rs` |
| `CliAction → Vec<Action>` | `zellij-utils/src/input/actions.rs:904` |
| Default keybinds | `zellij-utils/assets/config/default.kdl` |
| Action → instruction | `zellij-server/src/route.rs` |
| Adding a new action | [`../core/adding-an-action.md`](../core/adding-an-action.md) |
