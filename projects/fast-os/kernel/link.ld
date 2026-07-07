/* fast-os phase-0 linker script.
   Linked at base 0, position-independent; boot.s self-relocates using
   .rela.dyn, so the raw Image boots at any load address (QEMU virt,
   Apple Virtualization). .text.boot must stay first: it carries the
   ARM64 Linux boot header at offset 0. */
ENTRY(_start)

SECTIONS
{
    . = 0;
    __kernel_start = .;

    .text.boot : { KEEP(*(.text.boot)) }
    .text      : { *(.text*) }
    .rodata    : { *(.rodata*) }

    .rela.dyn : {
        __rela_start = .;
        *(.rela) *(.rela.*)
        __rela_end = .;
    }

    .got     : { *(.got) *(.got.plt) }
    .data    : { *(.data*) *(.data.rel.ro*) }
    .dynamic : { *(.dynamic) }

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
    __image_size = __kernel_end - __kernel_start;

    /DISCARD/ : { *(.comment*) *(.note*) *(.eh_frame*) *(.interp) }
}
