/* fast-os phase-0 linker script — QEMU aarch64 `virt` machine.
   RAM starts at 0x4000_0000; we load at the conventional +0x8_0000. */
ENTRY(_start)

SECTIONS
{
    . = 0x40080000;
    __kernel_start = .;

    .text.boot : { KEEP(*(.text.boot)) }
    .text      : { *(.text*) }
    .rodata    : { *(.rodata*) }
    .data      : { *(.data*) }

    .bss (NOLOAD) : ALIGN(16) {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(16);
        __bss_end = .;
    }

    . = ALIGN(16);
    __stack_bottom = .;
    . += 0x80000;            /* 512 KiB boot stack */
    __stack_top = .;

    __kernel_end = .;

    /DISCARD/ : { *(.comment*) *(.note*) *(.eh_frame*) }
}
