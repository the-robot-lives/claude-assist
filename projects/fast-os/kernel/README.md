# kernel

Phase-0 proto-kernel. Boots via the **Linux Image protocol** on both QEMU's
aarch64 `virt` machine and **Apple Virtualization** (UTM), prints a banner
with boot-to-banner time, and serves `fsh0` — a tiny polling shell
(help/info/uptime/echo/clear/panic).

## Run

```bash
make            # from projects/fast-os/ — builds fast-os.img for UTM
make run        # or boot in QEMU CLI (brew install qemu; exit: Ctrl-a x)
```

UTM walkthrough (both backends): [../docs/utm-setup.md](../docs/utm-setup.md).
One-time Rust setup: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

## How it boots anywhere

- `src/boot.s` — ARM64 Linux boot header (magic at offset 56, text_offset
  0x80000); saves the DTB pointer (x0), parks secondaries, sets the stack,
  **self-relocates** (applies `R_AARCH64_RELATIVE` from `.rela.dyn` — the
  kernel is a base-0 PIE, so QEMU's 0x4000_0000 RAM base and Apple VZ's
  different base both work), zeroes BSS, calls `kmain(dtb)`.
- `src/fdt.rs` — minimal device-tree scanner: finds nodes by `compatible`,
  reads `reg`.
- `src/pl011.rs` — polled UART (QEMU virt).
- `src/virtio_console.rs` — polled modern virtio-mmio console driver
  (Apple Virtualization's serial device); split virtqueues, TX + RX.
- `src/main.rs` — console autodetect (PL011 first, else probe virtio-mmio
  nodes for device id 3), timer reads, fsh0 loop, panic handler.
- `link.ld` — base 0, `.text.boot` first (header must be at offset 0),
  keeps `.rela.dyn` for the boot-time relocation pass, 512 KiB boot stack.
- `../tools/elf2image.py` — dumps PT_LOAD segments to the raw `Image` both
  loaders expect (and asserts the header magic landed at offset 56).

No interrupts, no MMU setup, no allocator yet — this is the roadmap.md
Phase 0 exit artifact; `frame/` and `services/` splits arrive in Phase 1–2.
