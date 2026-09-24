void print_char(char c) {
    __asm__ volatile (
        "mov $0x0e, %%ah\n\t"
        "int $0x10\n\t"
        : : "al" (c) : "ah", "cc"
    );
}

void kmain() {
    char *msg = "Hai lesbians :3\r\n";
    for (int i = 0; msg[i] != '\0'; i++) {
        print_char(msg[i]);
    }

    while (1) {
        __asm__ volatile ("hlt");
    }
}
