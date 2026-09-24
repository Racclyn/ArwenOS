void kmain() {
    char *video_memory = (char *) 0xb8000;

    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2]     = ' ';
        video_memory[i * 2 + 1] = 0x07;
    }

    char *msg = "Hai Lesbian i'm 32 bit :3";
    int attr = 0x0A;

    int i = 0;
    while (msg[i] != '\0') {
        video_memory[i * 2]     = msg[i];
        video_memory[i * 2 + 1] = attr;
        i++;
    }

    while (1) {
        __asm__ volatile ("cli; hlt");
    }
}
