; boot.asm - Real BIOS-based bootloader to load kernel from disk

[org 0x7C00]  ; BIOS loads the bootloader at 0x7C00

; BIOS Interrupt Constants
%define KERNEL_SECTOR 2  ; Kernel starts at sector 2
%define SECTOR_SIZE 512  ; Sector size in bytes
%define KERNEL_LOAD_ADDR 0x10000 ; Kernel load address

; BIOS Disk Services
%define DISK_DRIVE 0x80    ; Drive 0 (first hard drive, typically)
%define SECTOR_COUNT 1     ; We are loading 1 sector at a time

; Clear the screen and print a message
clear_screen:
    mov ah, 0x0E         ; BIOS teletype function (print char)
    mov al, 0x20         ; ASCII space
    mov bh, 0            ; Page number
    mov bl, 0x07         ; Text color (light gray)
    mov cx, 2000         ; Print 2000 spaces to clear the screen
clear_loop:
    int 0x10             ; BIOS interrupt to print character
    loop clear_loop
    ret

print_string:
    ; Print a string passed in the 'si' register (pointer to string)
    mov ah, 0x0E         ; BIOS teletype function (print char)
print_char_loop:
    lodsb                ; Load byte at DS:SI into AL, increment SI
    or al, al            ; Check for null terminator
    jz print_done        ; If null terminator, end loop
    int 0x10             ; BIOS interrupt to print character
    jmp print_char_loop  ; Repeat until null terminator
print_done:
    ret

; Delay function (simple busy-wait)
delay:
    mov cx, 0x100000     ; Some delay duration
delay_loop:
    dec cx
    jnz delay_loop
    ret

; Load a sector from disk into memory (using BIOS interrupt 0x13)
load_sector:
    mov ah, 0x02         ; BIOS function to read disk sector
    mov al, SECTOR_COUNT ; Number of sectors to read (1 sector)
    mov ch, 0            ; Cylinder 0
    mov cl, KERNEL_SECTOR ; Kernel starts at sector 2
    mov dh, 0            ; Head 0
    mov dl, DISK_DRIVE   ; Drive 0 (first hard disk)
    mov al, KERNEL_SECTOR ; Segment to load kernel into (0x1000)
    mov di, 0            ; Offset (starting from 0)
    int 0x13             ; Call BIOS interrupt to read sector
    ret

; Jump to kernel
jump_to_kernel:
    jmp KERNEL_LOAD_ADDR ; Jump to the loaded kernel

; Bootloader entry point
start:
    ; Initialize the bootloader
    call clear_screen
    mov si, msg_initializing
    call print_string
    call delay

    ; Scan the disk (printing message for now)
    mov si, msg_scan_disk
    call print_string
    call delay

    ; Start loading the kernel
    mov si, msg_loading_kernel
    call print_string
    call delay

    ; Actually load the kernel (sector 2) from the disk
    call load_sector
    call delay

    ; After loading the kernel, jump to it
    mov si, msg_kernel_loaded
    call print_string
    call delay

    ; Now that we've loaded the kernel, jump to its entry point
    call jump_to_kernel

; Message strings
msg_initializing db 'Initializing WolfOS...', 0
msg_scan_disk db 'Scanning disk...', 0
msg_loading_kernel db 'Loading kernel...', 0
msg_kernel_loaded db 'Kernel loaded! Jumping to kernel...', 0

; Padding to make the bootloader 512 bytes
times 510-($-$$) db 0
dw 0xAA55  ; Bootloader signature
