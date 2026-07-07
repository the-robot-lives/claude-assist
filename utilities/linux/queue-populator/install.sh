#!/usr/bin/env bash
# Install queue-populator: binary, PipeWire virtual mics, STT models, autostart.
set -euo pipefail

cd "$(dirname "$0")"

BIN_DIR="${HOME}/.local/bin"
MODEL_DIR="${QP_MODEL_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/queue-populator/models}"
PW_CONF_DIR="${HOME}/.config/pipewire/pipewire.conf.d"
AUTOSTART_DIR="${HOME}/.config/autostart"

MODEL_NAME="sherpa-onnx-streaming-zipformer-en-2023-06-26"
MODEL_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/${MODEL_NAME}.tar.bz2"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

log "Stopping any running instance"
pkill -x queue-populator 2>/dev/null || true

log "Building (cargo build --release)"
cargo build --release

log "Installing binary to ${BIN_DIR}"
mkdir -p "${BIN_DIR}"
install -m 0755 target/release/queue-populator "${BIN_DIR}/queue-populator"

log "Installing PipeWire virtual mic config"
mkdir -p "${PW_CONF_DIR}"
cp config/10-robot-virtual-mics.conf "${PW_CONF_DIR}/"
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null \
    || log "restart PipeWire manually: systemctl --user restart pipewire wireplumber"

if [ ! -f "${MODEL_DIR}/${MODEL_NAME}/tokens.txt" ]; then
    log "Downloading STT model (${MODEL_NAME}, ~200MB)"
    mkdir -p "${MODEL_DIR}"
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT
    curl -fL --progress-bar "${MODEL_URL}" -o "${tmp}/model.tar.bz2"
    tar -xjf "${tmp}/model.tar.bz2" -C "${MODEL_DIR}"
else
    log "STT model already present"
fi

log "Installing autostart entry"
mkdir -p "${AUTOSTART_DIR}"
cat > "${AUTOSTART_DIR}/com.noizu.queue-populator.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Queue Populator
Comment=Voice memo router and virtual microphone control
Exec=${BIN_DIR}/queue-populator
Icon=audio-input-microphone
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

log "Verifying installation"
"${BIN_DIR}/queue-populator" --check || true

log "Done. Start now with: ${BIN_DIR}/queue-populator"
