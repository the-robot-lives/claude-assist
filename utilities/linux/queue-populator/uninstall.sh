#!/usr/bin/env bash
# Remove queue-populator binary, autostart, and PipeWire virtual mic config.
# Leaves ~/.config/queue-populator (config) and downloaded models in place.
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

log "Stopping any running instance"
pkill -x queue-populator 2>/dev/null || true

log "Removing binary"
rm -f "${HOME}/.local/bin/queue-populator"

log "Removing autostart entry"
rm -f "${HOME}/.config/autostart/com.noizu.queue-populator.desktop"

log "Removing PipeWire virtual mic config"
rm -f "${HOME}/.config/pipewire/pipewire.conf.d/10-robot-virtual-mics.conf"
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null \
    || log "restart PipeWire manually: systemctl --user restart pipewire wireplumber"

log "Done. Config kept at ~/.config/queue-populator; models kept in ~/.local/share/queue-populator"
