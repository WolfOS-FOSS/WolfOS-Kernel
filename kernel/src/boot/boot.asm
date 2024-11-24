[org 0x7C00]  ; BIOS loads the bootloader at 0x7C00

; Define constants and macros
%define KERNEL_SIGNATURE 0xDEAD
%define KERNEL_LOAD_ADDR 0x1000
%define MAX_DRIVES 4
%define MAX_SECTORS 128
%define MAX_HEADS 16
%define MAX_CYLINDERS 1024
%define SECTOR_SIZE 512  ; Define the sector size as 512 bytes

; Sector Scan Status
%define STATUS_UNSEARCHED 0
%define STATUS_NO_KERNEL 1
%define STATUS_KERNEL_FOUND 2

; Global Variables
kernel_drive: db 0
kernel_start_sector: db 0
kernel_start_head: db 0
kernel_start_cylinder: dw 0
sector_status: times MAX_SECTORS * MAX_DRIVES * MAX_HEADS db STATUS_UNSEARCHED

; Search Tracking Variables
current_drive: db 0
current_head: db 0
current_cylinder: dw 0

; Bootloader Entry Point
start:
    ; Initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00        ; Stack grows downwards

    ; Clear Interrupts
    cli
    
    ; Initialize search
    call find_kernel

    ; If we reach here, no kernel was found
    mov si, kernel_not_found_msg
    call print_string

    ; Hang the system
hang:
    cli
    hlt

; Comprehensive Kernel Search
find_kernel:
    ; Draw initial TUI
    call draw_tui
    
    ; Scan drives
    mov dl, 0             ; Start with drive 0
.drive_loop:
    ; Store current drive
    mov [current_drive], dl
    
    ; Try different heads
    mov dh, 0             ; Start with head 0
.head_loop:
    ; Store current head
    mov [current_head], dh
    
    ; Try different cylinders
    mov ch, 0             ; Start with cylinder 0
.cylinder_loop:
    ; Store current cylinder
    mov [current_cylinder], cx
    
    ; Update TUI to show progress
    call draw_tui
    
    ; Try different sectors
    mov cl, 1             ; Start with sector 1
.sector_loop:
    ; Attempt to load kernel
    call load_kernel
    
    ; Check if kernel found
    cmp al, 1
    je .kernel_found
    
    ; Move to next sector
    inc cl
    cmp cl, MAX_SECTORS
    jl .sector_loop
    
    ; Move to next cylinder
    inc ch
    cmp ch, MAX_CYLINDERS
    jl .cylinder_loop
    
    ; Move to next head
    inc dh
    cmp dh, MAX_HEADS
    jl .head_loop
    
    ; Move to next drive
    inc dl
    cmp dl, MAX_DRIVES
    jl .drive_loop
    
    ; No kernel found
    jmp .kernel_not_found

.kernel_found:
    ; Kernel successfully loaded
    mov si, kernel_found_msg
    call print_string
    
    ; Set up the stack for the kernel (optional, but good practice for C++ programs)
    mov ax, KERNEL_LOAD_ADDR   ; Kernel's base address
    mov ss, ax                 ; Set up the stack segment (it can point to the kernel area)
    mov sp, 0x7C00             ; Stack pointer, just an example

    ; Set up DS and ES to point to the kernel
    mov ax, KERNEL_LOAD_ADDR   ; Kernel's segment address
    mov ds, ax                 ; Set DS to point to the kernel memory
    mov es, ax                 ; Set ES to point to the kernel memory
    
    ; Now jump to the C++ kernel entry point
    ; Assuming the kernel's entry point is at 0x1000 (or KERNEL_LOAD_ADDR)
    ; If using an entry point like '_start' from the kernel.o, make sure it's aligned properly
    jmp 0x0000:0x1000          ; Jump to kernel start

.wait_loop:
    loop .wait_loop
    
    ; Jump to kernel
    jmp KERNEL_LOAD_ADDR:0x0000

.kernel_not_found:
    ; Kernel not found
    mov si, kernel_not_found_msg
    call print_string
    
    ; Hang
    jmp hang

; Kernel Loading Function
load_kernel:
    ; Inputs:
    ; dl = drive
    ; dh = head
    ; ch = cylinder (low 8 bits)
    ; cl = sector
    
    ; Reset disk system
    mov ah, 0x00
    int 0x13
    jc .disk_error
    
    ; Prepare for kernel loading
    mov ax, KERNEL_LOAD_ADDR
    mov es, ax            ; ES:BX points to kernel load address
    xor bx, bx            ; Offset 0
    
    ; Sectors to load
    mov al, 64            ; Max 64 sectors (32KB)
    
    ; BIOS disk read
    mov ah, 0x02          ; Read sectors
    int 0x13
    jc .disk_error
    
    ; Verify kernel signature
    mov ax, [KERNEL_LOAD_ADDR]
    cmp ax, KERNEL_SIGNATURE
    jne .no_kernel
    
    ; Kernel found
    mov byte [kernel_drive], dl
    mov byte [kernel_start_sector], cl
    mov byte [kernel_start_head], dh
    mov word [kernel_start_cylinder], cx
    
    ; Mark sector as kernel found
    push dx
    mov ax, dx
    mul byte [SECTOR_SIZE]
    mov si, ax
    mov byte [sector_status + si], STATUS_KERNEL_FOUND
    pop dx
    
    mov al, 1
    ret

.disk_error:
    mov al, 0
    ret

.no_kernel:
    ; Mark sector as no kernel found
    push dx
    mov ax, dx
    mul byte [SECTOR_SIZE]
    mov si, ax
    mov byte [sector_status + si], STATUS_NO_KERNEL
    pop dx
    
    mov al, 0
    ret

; TUI Functions
print_string:
    ; Print string function
    ; SI points to string
    mov ah, 0x0E  ; BIOS teletype output function
.print_loop:
    lodsb            ; Load byte at SI into AL, then increment SI
    or al, al        ; Check for null terminator
    jz .done
    int 0x10         ; Call BIOS interrupt to print character
    jmp .print_loop
.done:
    ret

draw_tui:
    ; Draw TUI progress here (implementation depends on your display method)
    ret

; Messages
kernel_not_found_msg db 'Kernel not found!', 0
kernel_found_msg db 'Kernel loaded successfully!', 0

; Bootloader Signature
dw 0xAA55