[org 0x7C00]  ; Bootloader is loaded at address 0x7C00

; Set up the video mode (optional, to show something on screen)
mov ah, 0x0E      ; BIOS teletype function
mov al, 'B'       ; Print 'B' for "Booting..."
int 0x10          ; BIOS interrupt
mov al, 'o'       ; Print 'o'
int 0x10
mov al, 'o'       ; Print 'o'
int 0x10
mov al, 't'       ; Print 't'
int 0x10
mov al, 'L'       ; Print 'L'
int 0x10
mov al, 'o'       ; Print 'o'
int 0x10
mov al, 'a'       ; Print 'a'
int 0x10
mov al, 'd'       ; Print 'd'
int 0x10
mov al, 'e'       ; Print 'e'
int 0x10
mov al, 'r'       ; Print 'r'
int 0x10

; Newline after "Bootloader"
mov al, 0x0A      ; Newline character
int 0x10

; Print message: "Loading kernel..."
mov si, msg_loading_kernel
call print_string

; Loading the kernel
mov si, kernel_start  ; Set the source (the kernel in the boot image)
mov di, 0x1000        ; Destination: Load at 0x1000 (arbitrary address)
mov cx, 0x200         ; Length of the kernel to load (in 512-byte blocks)
call load_kernel

; Print message: "Kernel loaded. Jumping to kernel..."
mov si, msg_kernel_loaded
call print_string

; Jump to kernel
jmp 0x1000  ; Jump to where we loaded the kernel

; Simple Kernel Loading Function
load_kernel:
    ; Read the kernel from the disk (assuming the kernel is already on the disk)
    mov ah, 0x02      ; BIOS function 0x02 (read sectors)
    mov al, 0x01      ; Number of sectors to read
    mov bx, 0x0000    ; No flags
    mov dl, 0x80      ; Disk 0x80 (floppy or hard drive)
    mov dh, 0         ; Head 0
    mov ch, 0         ; Cylinder 0
    mov cl, 2         ; Starting sector (sector 2 after the bootloader)
    int 0x13          ; BIOS interrupt 0x13

    ; Check for errors
    jc  disk_error

    ; Print message: "Kernel read successfully!"
    mov si, msg_kernel_read
    call print_string

    ret

disk_error:
    ; Handle error (if needed)
    mov si, msg_disk_error
    call print_string
    hlt  ; Halt the system if disk error occurs

; Print function to display strings on screen
print_string:
    ; SI points to the string
    mov ah, 0x0E        ; BIOS teletype function
print_char:
    lodsb               ; Load the next byte from SI into AL
    cmp al, 0           ; Check if we reached the null terminator
    je  print_done
    int 0x10            ; Print the character
    jmp print_char
print_done:
    ret

; Messages for verbosity
msg_loading_kernel db 'Loading kernel...', 0
msg_kernel_loaded  db 'Kernel loaded. Jumping to kernel...', 0
msg_kernel_read    db 'Kernel read successfully!', 0
msg_disk_error     db 'Disk error occurred! Halting...', 0

; Kernel start location (start of the kernel.bin in the image)
kernel_start:
    db 0x00

; Fill up the remaining space with zeros (if necessary)
times 510 - ($ - $$) db 0
dw 0xAA55  ; Boot sector signature
