[org 0x7c00]
[bits 16]

KERNEL_LOAD_OFFSET equ 0x10000

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

    mov ax, 0x2401
    int 0x15

    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    mov ah, 0x02
    mov al, 0x7F
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02

    mov bx, 0x1000
    mov es, bx
    xor bx, bx

    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:init_pm

[bits 32]
init_pm:
    ; Initialize 32-bit data segments
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Absolute jump to kernel entry point
    mov eax, KERNEL_LOAD_OFFSET
    jmp eax

[bits 16]
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

;gdt stuffs
gdt_start:
    dq 0x0000000000000000

gdt_code:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

boot_drive: db 0
msg_loading: db "Loading kernel (32-bit)...", 13, 10, 0
msg_error: db "Disk error check", 13, 10, 0

times 510-($-$$) db 0
dw 0xaa55
