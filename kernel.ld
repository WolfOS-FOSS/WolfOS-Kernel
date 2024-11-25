ENTRY(_start)

SECTIONS {
    . = 0x1000;  /* Start of the kernel in memory (this can be adjusted) */
    
    .text : {
        *(.text)  /* All .text sections from C code go here */
    }
    
    .data : {
        *(.data)  /* All .data sections from C code */
    }
    
    .bss : {
        *(.bss)  /* All .bss sections from C code */
    }
}
