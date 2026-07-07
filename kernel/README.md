# kernel

Phase-0 proto-kernel: boots on QEMU's aarch64 `virt` machine, prints a banner
with boot-to-banner time, and serves `fsh0` — a tiny polling shell on the
PL011 UART (help/info/uptime/echo/clear/panic).

## Run on macOS

```bash
# one-time setup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # Rust
brew install qemu                                                 # QEMU

# build + boot (HVF-accelerated on Apple Silicon)
../run.sh        # or from repo root: ./run.sh
```

Exit QEMU with `Ctrl-a x`.

## Layout

- `src/boot.s` — EL1 entry: park secondaries, set stack, zero BSS, call `kmain`
- `src/main.rs` — UART driver, timer reads, fsh0 loop, panic handler
- `link.ld` — loads at `0x4008_0000` (QEMU virt RAM base + 512K), 512 KiB boot stack
- `.cargo/config.toml` — targets `aarch64-unknown-none`; **build from this directory** so `-Tlink.ld` resolves

No interrupts, no MMU setup, no allocator yet — this is the roadmap.md
Phase 0 exit artifact (dev loop + boot measurement), with `frame/` and
`services/` splits arriving in Phase 1–2.
