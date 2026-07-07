#!/usr/bin/env python3
"""Convert the fast-os kernel ELF into a raw ARM64 Linux-protocol Image.

Dumps PT_LOAD segments at their physical offsets and verifies the ARM64
boot-header magic ends up at byte 56 — the format QEMU's -kernel and
Apple Virtualization's VZLinuxBootLoader both expect.
"""
import struct
import sys


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: elf2image.py <kernel-elf> <out-image>")
    src, dst = sys.argv[1], sys.argv[2]
    d = open(src, "rb").read()

    if d[:4] != b"\x7fELF" or d[4] != 2 or d[5] != 1:
        sys.exit("input is not a 64-bit little-endian ELF")

    (e_phoff,) = struct.unpack_from("<Q", d, 0x20)
    (e_phentsize,) = struct.unpack_from("<H", d, 0x36)
    (e_phnum,) = struct.unpack_from("<H", d, 0x38)

    segs = []
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        (p_type,) = struct.unpack_from("<I", d, off)
        p_offset, p_vaddr, p_paddr, p_filesz, _p_memsz = struct.unpack_from(
            "<QQQQQ", d, off + 8
        )
        if p_type == 1 and p_filesz > 0:  # PT_LOAD
            segs.append((p_paddr, p_offset, p_filesz))

    if not segs:
        sys.exit("no PT_LOAD segments found")

    segs.sort()
    base = segs[0][0]
    end = max(p + f for p, _, f in segs)
    img = bytearray(end - base)
    for p, o, f in segs:
        img[p - base : p - base + f] = d[o : o + f]

    if img[56:60] != b"ARM\x64":
        sys.exit(
            "ARM64 boot-header magic not at offset 56 — "
            ".text.boot is no longer first; check link.ld"
        )

    open(dst, "wb").write(img)
    print(f"[elf2image] {dst}: {len(img)} bytes (link base {base:#x})")


if __name__ == "__main__":
    main()
