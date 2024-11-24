/* WolfOS Linker Script */
ENTRY(_start)

SECTIONS {
    /* Kernel starts at 1MB */
    . = 0x100000;

    .text BLOCK(4K) : ALIGN(4K) {
        *(.text)
    }

    .rodata BLOCK(4K) : ALIGN(4K) {
        *(.rodata)
    }

    .data BLOCK(4K) : ALIGN(4K) {
        *(.data)
    }

    .bss BLOCK(4K) : ALIGN(4K) {
        *(COMMON)
        *(.bss)
    }

    /* Stack grows down from 2MB */
    . = 0x200000;
    kernel_stack_top = .;
    . = . + 0x4000;    /* 16K stack */
    kernel_stack_bottom = .;
}