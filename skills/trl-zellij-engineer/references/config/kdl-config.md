# Zellij Configuration (KDL)

> **Verified against Zellij `0.45.0`.** Options read from `zellij-utils/src/input/options.rs`;
> defaults from `zellij-utils/assets/config/default.kdl`. Parser: `zellij-utils/src/kdl/mod.rs`.

## File Location & Precedence

Default: `~/.config/zellij/config.kdl` (XDG). Overridable via `--config`, `ZELLIJ_CONFIG_FILE`;
config dir via `--config-dir` / `ZELLIJ_CONFIG_DIR`.

```bash
zellij setup --dump-config       # the effective config, defaults included
zellij setup --check             # locations + validity
```

> `--dump-config` is the fastest way to answer "what is actually set?" — it resolves defaults,
> your file, and CLI overrides into one document. Prefer it to reasoning about precedence.

## Top-Level Nodes

| Node | Purpose |
|---|---|
| `keybinds` | Mode-scoped bindings — see [keybinds-and-actions.md](keybinds-and-actions.md) |
| `plugins` | Plugin aliases |
| `themes` | Theme definitions |
| `ui` | UI tweaks (e.g. `pane_frames { rounded_corners }`) |
| `env` | Environment variables for spawned panes |
| `load_plugins` | Plugins to background-load at startup |
| *(bare options)* | Everything in the table below, as top-level `key value` pairs |

Options are **not** nested under an `options` node — they are bare top-level entries:
```kdl
theme "gruvbox-dark"
default_shell "fish"
pane_frames false
```

## Options

From `zellij-utils/src/input/options.rs`. All are `Option<T>` — unset means "use the default".

### Appearance
| Option | Type | Notes |
|---|---|---|
| `theme` | string | Theme name |
| `theme_dark` / `theme_light` | string | Per-host-appearance themes |
| `theme_dir` | path | Where themes live |
| `simplified_ui` | bool | Drop glyphs needing a Nerd Font |
| `pane_frames` | bool | Frames around panes |
| `styled_underlines` | bool | Colored/curly underlines |
| `visual_bell` | bool | Flash instead of beep |
| `mouse_hover_effects` | bool | |
| `show_startup_tips` | bool | |
| `show_release_notes` | bool | |

### Behavior
| Option | Type | Notes |
|---|---|---|
| `default_mode` | `InputMode` | Startup mode (e.g. `"locked"`) |
| `default_shell` | path | |
| `default_cwd` | path | |
| `default_layout` | path | Layout name or path |
| `layout_dir` | path | Default `~/.config/zellij/layouts` |
| `mouse_mode` | bool | |
| `focus_follows_mouse` | bool | |
| `mouse_click_through` | bool | |
| `advanced_mouse_actions` | bool | |
| `auto_layout` | bool | Drive **swap layouts** automatically |
| `stacked_resize` | bool | |
| `scroll_buffer_size` | usize | Scrollback lines **per pane** |
| `scrollback_editor` | path | Editor for `EditScrollback` |
| `on_force_close` | `OnForceClose` | `detach` \| `quit` |
| `support_kitty_keyboard_protocol` | bool | |
| `post_command_discovery_hook` | string | |

### Copy
| Option | Type | Notes |
|---|---|---|
| `copy_command` | string | e.g. `wl-copy`, `pbcopy` |
| `copy_clipboard` | `Clipboard` | `system` \| `primary` |
| `copy_on_select` | bool | Default true; set false and bind `Copy` |

### Session
| Option | Type | Notes |
|---|---|---|
| `session_name` | string | |
| `attach_to_session` | bool | Attach if `session_name` exists |
| `mirror_session` | bool | Multiplayer: mirror vs independent focus |
| `session_serialization` | bool | Persist for resurrection |
| `serialize_pane_viewport` | bool | |
| `scrollback_lines_to_serialize` | usize | |
| `serialization_interval` | u64 | Seconds |
| `disable_session_metadata` | bool | |

### Web server
`web_server` (bool), `web_sharing` (`WebSharing`), `web_server_ip` (`IpAddr`),
`web_server_port` (u16), `web_server_cert` / `web_server_key` (paths),
`enforce_https_for_localhost` (bool).

> The web server serves **live terminal sessions over HTTP**. Enabling it, and especially binding
> `web_server_ip` to anything other than loopback, exposes shell access to the network. Treat
> `web_server`, `web_sharing`, and `web_server_ip` as security-relevant settings: default to
> loopback, and require TLS (`web_server_cert`/`web_server_key`) plus a deliberate decision from
> the user before binding externally. Never enable these on a user's behalf as a convenience.

## Plugin Aliases

```kdl
plugins {
    tab-bar    location="zellij:tab-bar"
    status-bar location="zellij:status-bar"
    my-plugin  location="file:/home/me/plugins/my-plugin.wasm" {
        some_key "some_value"     // default config for this alias
    }
}
```
The alias is then usable anywhere a `location` is expected:
```kdl
pane { plugin location="my-plugin" }
```
Config given at the **use site** merges over the alias defaults. Aliases are the right way to keep
absolute paths out of shared layouts.

`load_plugins` background-loads plugins at startup (headless, before their pane exists) — useful
for plugins that watch state rather than render.

## Themes

```kdl
themes {
    my-theme {
        text_unselected {
            base   255 255 255
            background 0 0 0
            emphasis_0 255 0 0
            // ...
        }
        text_selected { /* ... */ }
        ribbon_selected { /* ... */ }
        // ...
    }
}
```

Zellij has **two theme formats**:
- **Modern** — semantic component slots (`text_unselected`, `text_selected`, `ribbon_selected`,
  `frame_selected`, …), each with `base`/`background`/`emphasis_*`.
- **Legacy** — flat `fg`/`bg`/`black`/`red`/`green`/… palette.

Both parse. The modern format is what `ui_components` index levels resolve against, so plugins
using `Text::color_range(0, ..)` style correctly under it. Prefer modern for new themes.

Themes may live inline in `config.kdl` or as files in `theme_dir`. `theme_dark`/`theme_light` plus
`Event::HostTerminalThemeChanged` support following the host terminal's light/dark mode.

## Env

```kdl
env {
    EDITOR "nvim"
    RUST_BACKTRACE "1"
}
```
Applied to panes Zellij spawns. Plugins with `ReadSessionEnvironmentVariables` read these via
`get_session_environment_variables()`.

## Reconfiguring at Runtime

Config is not purely startup-time. Plugins with the `Reconfigure` permission call `reconfigure()`;
plugins subscribed to `PluginConfigurationChanged` observe their own config changing;
`ConfigWasWrittenToDisk` / `FailedToWriteConfigToDisk` report persistence.

## Checklist

- [ ] Options at top level, not nested under `options`
- [ ] `zellij setup --check` passes
- [ ] Absolute paths avoided in shareable config (use aliases)
- [ ] Web server settings deliberate, loopback-bound, TLS if exposed
- [ ] Theme uses the modern format for new work
- [ ] Verified with `zellij setup --dump-config`

## Source Map

| What | Where |
|---|---|
| `Options` | `zellij-utils/src/input/options.rs` |
| Defaults | `zellij-utils/assets/config/default.kdl` |
| KDL parsing | `zellij-utils/src/kdl/mod.rs` |
| Plugin aliases | `zellij-utils/src/input/plugins.rs` |
| Themes | `zellij-utils/src/input/theme.rs`, `zellij-utils/assets/themes/` |
| CLI | `zellij-utils/src/cli.rs` |
