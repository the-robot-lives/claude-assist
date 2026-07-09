# Hyprland clipboard history (cliphist) — Ubuntu ARM

Quick setup for Wayland clipboard history using `cliphist` with `wl-clipboard`.

## 1) Install required tools

```bash
sudo apt update
sudo apt install -y wl-clipboard wofi golang-go
```

Try package install first:

```bash
sudo apt install -y cliphist
```

If that fails, install via Go:

```bash
go install go.senan.xyz/cliphist@latest
```

If `go install` puts binaries in `~/go/bin`, add it to your PATH:

```bash
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.profile
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/go/bin:$PATH"
```

Verify:

```bash
wl-copy --version
cliphist --help
```

## 2) Update Hyprland config

Edit `~/.config/hypr/hyprland.conf` and add:

```ini
# Clipboard history watchers
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Clipboard picker (Super+V)
bind = SUPER, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
```

Reload Hyprland:

- `Super + Shift + R`, or log out and in.

## 3) Quick test

```bash
echo "hello clipboard history" | wl-copy
```

Press `Super + V`, choose an entry, then paste with `Ctrl + V`.

## 4) Useful commands

- Show history: `cliphist list`
- Clear history: `cliphist wipe`
- Manual selection + copy:
  ```bash
  cliphist list | wofi --dmenu | cliphist decode | wl-copy
  ```

If `Super + V` does nothing:

```bash
pgrep -a wl-paste
```

You should see two `wl-paste --watch` processes. If not, start them manually:

```bash
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
cliphist list
```
