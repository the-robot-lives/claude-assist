// fast-os phase-0 boot shim — aarch64, QEMU virt machine.
// QEMU loads our ELF and jumps here at EL1. One CPU unless -smp given;
// secondaries (mpidr aff0 != 0) are parked.

.section .text.boot
.global _start
_start:
    mrs     x0, mpidr_el1
    and     x0, x0, #0xff
    cbz     x0, 2f
1:  wfe                         // park secondary cores
    b       1b

2:  adrp    x0, __stack_top     // set up boot stack
    add     x0, x0, :lo12:__stack_top
    mov     sp, x0

    adrp    x0, __bss_start     // zero .bss
    add     x0, x0, :lo12:__bss_start
    adrp    x1, __bss_end
    add     x1, x1, :lo12:__bss_end
3:  cmp     x0, x1
    b.hs    4f
    str     xzr, [x0], #8
    b       3b

4:  bl      kmain
5:  wfe                         // kmain never returns; belt & braces
    b       5b
