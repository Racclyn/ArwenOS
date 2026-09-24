OUTPUT_FORMAT("binary")
ENTRY(start)

SECTIONS
{
    . = 0x0000;

    .text : {
        kstart.o(.text)
        *(.text)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
