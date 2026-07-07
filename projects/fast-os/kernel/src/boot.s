// fast-os phase-0 boot shim — aarch64, Linux Image boot protocol.
// Works on QEMU virt (-kernel fast-os.img) and Apple Virtualization
// (VZLinuxBootLoader via UTM). Entered at EL1 with x0 = DTB pointer.
//
// The kernel is linked position-independent at base 0; we self-relocate
// using the R_AARCH64_RELATIVE entries in .rela.dyn, so any load address
// works (QEMU RAM base 0x4000_0000, Apple VZ differs).

.section .text.boot
.global _header
_header:
    b       _start              // code0: jump over header
    .word   0                   // code1
    .quad   0x80000             // text_offset: load at RAM base + 512K
    .quad   __image_size        // image_size
    .quad   0xa                 // flags: LE, 4K pages, placed anywhere
    .quad   0                   // res2
    .quad   0                   // res3
    .quad   0                   // res4
    .word   0x644d5241          // magic: "ARM\x64" (little-endian)
    .word   0                   // res5

.global _start
_start:
    mov     x19, x0             // preserve DTB pointer

    mrs     x1, mpidr_el1       // park secondary cores
    and     x1, x1, #0xff
    cbz     x1, 2f
1:  wfe
    b       1b

2:  adrp    x1, __stack_top     // set up boot stack
    add     x1, x1, :lo12:__stack_top
    mov     sp, x1

    // self-relocate: apply R_AARCH64_RELATIVE (type 1027) entries.
    // Link base is 0, so runtime value = load_base + addend.
    adrp    x5, _header
    add     x5, x5, :lo12:_header
    adrp    x6, __rela_start
    add     x6, x6, :lo12:__rela_start
    adrp    x7, __rela_end
    add     x7, x7, :lo12:__rela_end
3:  cmp     x6, x7
    b.hs    5f
    ldp     x8, x9, [x6], #16   // r_offset, r_info
    ldr     x10, [x6], #8       // r_addend
    cmp     x9, #1027           // R_AARCH64_RELATIVE
    b.ne    3b
    add     x10, x10, x5
    str     x10, [x5, x8]
    b       3b

5:  adrp    x0, __bss_start     // zero .bss
    add     x0, x0, :lo12:__bss_start
    adrp    x1, __bss_end
    add     x1, x1, :lo12:__bss_end
6:  cmp     x0, x1
    b.hs    7f
    str     xzr, [x0], #8
    b       6b

7:  mov     x0, x19             // kmain(dtb)
    bl      kmain
8:  wfe                         // kmain never returns; belt & braces
    b       8b
