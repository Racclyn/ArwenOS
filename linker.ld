ENTRY(_start)
SECTIONS
{
    . = 0x10000;

    .text : AT(0x10000) {
        kstart.o(.text)
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
