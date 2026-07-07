#!/usr/bin/env bash
# fast-os phase-0: build + boot in QEMU. macOS-first (HVF on Apple Silicon),
# works on Linux/Intel too (TCG emulation).
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v cargo >/dev/null 2>&1; then
    echo "Rust not found. Install with:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi
if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
    echo "QEMU not found. Install with:"
    echo "  brew install qemu        (macOS)"
    echo "  apt install qemu-system-arm   (Debian/Ubuntu)"
    exit 1
fi

rustup target add aarch64-unknown-none >/dev/null 2>&1 || true

echo "[fast-os] building kernel..."
(cd kernel && cargo build --release)

KERNEL=kernel/target/aarch64-unknown-none/release/fast-os-kernel

ACCEL=(-cpu cortex-a72)  # TCG fallback (Intel Mac / Linux)
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
    ACCEL=(-accel hvf -cpu host)  # native-speed on Apple Silicon
fi

echo "[fast-os] booting (exit with Ctrl-a x)..."
exec qemu-system-aarch64 \
    -M virt \
    "${ACCEL[@]}" \
    -m 512M \
    -nographic \
    -kernel "$KERNEL"
