[bits 16]
global start
extern kmain

start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xfffe

    call kmain

.hang:
    cli
    hlt
    jmp .hang
