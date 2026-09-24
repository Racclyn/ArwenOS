[org 0x7c00]
[bits 16]

KERNEL_LOAD_SEG equ 0x1000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov [boot_drive], dl

    mov si, msg_loading
    call print_string

    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    mov bl, 3

.read_loop:
    push bx
    mov ah, 0x02
    mov al, [kernel_sectors]
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02

    mov bx, KERNEL_LOAD_SEG
    mov es, bx
    xor bx, bx

    mov dl, [boot_drive]
    int 0x13
    pop bx
    jnc .success

    dec bl
    jz disk_error

    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jmp .read_loop

.success:
    jmp KERNEL_LOAD_SEG:0x0000

disk_error:
    mov si, msg_error
    call print_string
    jmp $

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret

boot_drive: db 0
kernel_sectors: db 0x05
msg_loading: db "Loading kernel...", 13, 10, 0
msg_error: db "Disk error check", 13, 10, 0

times 510-($-$$) db 0 ; Pad rest with 0's on the bootloader
dw 0xaa55
