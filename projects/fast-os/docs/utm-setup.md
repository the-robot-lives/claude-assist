# Running fast-os in UTM

Both UTM backends are supported. The kernel boots via the Linux Image protocol, self-relocates to any load address, and autodetects its console from the device tree — PL011 on the QEMU backend, virtio-console on the Apple Virtualization backend.

## 1. Build the image

```bash
cd projects/fast-os
make            # → kernel/target/aarch64-unknown-none/release/fast-os.img
```

(Needs Rust from https://rustup.rs and python3. QEMU is only needed for `make run`.)

## 2a. Apple Virtualization backend (fastest)

1. **Create a New Virtual Machine** → **Virtualize** → **Linux**
2. Check **Use Apple Virtualization**
3. Check **Boot from kernel image**
   - **Kernel**: select `fast-os.img` from step 1
   - **Initramfs / Boot args**: leave empty
4. Memory **512 MB**, 1 CPU, no storage
5. Save, then edit the VM → **Devices** → ensure a **Serial** device with mode **Built-in Terminal** exists (add one if not — on the Apple backend this is the virtio-console the kernel finds)

## 2b. QEMU backend

Same steps, but leave **Use Apple Virtualization** *unchecked* in step 2, and add the **Serial → Built-in Terminal** device (PL011). You may delete the default Display device.

## 3. Boot

Start the VM — the serial terminal shows the banner (including which console was detected and boot-to-banner ms) and the `fsh0>` prompt (`help`, `info`, `uptime`, `echo`, `clear`, `panic`).

## Rebuilding

After code changes: `make`, then restart the VM — UTM references the image by path, so the new build is picked up automatically.

## CLI alternative (no UTM)

```bash
brew install qemu
make run        # HVF-accelerated on Apple Silicon; exit with Ctrl-a x
```

## Troubleshooting

- **No output on Apple backend**: confirm a Serial (Built-in Terminal) device exists; without it the kernel finds no virtio-console and boots silently.
- **No output on QEMU backend**: confirm the Serial device was added and you're watching its window, not the Display window.
- **VM won't start**: the kernel path in UTM is absolute — re-select `fast-os.img` if the repo moved. Ensure you built with `make` (UTM needs the raw `.img`, not the ELF).
