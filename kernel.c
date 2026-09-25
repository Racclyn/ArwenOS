#include "fs.h"
#include "paging.h"

void kmain() {
    init_paging();

    char *video_memory = (char *) 0xb8000;
    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2]     = ' ';
        video_memory[i * 2 + 1] = 0x07;
    }

    char file_buffer[128];
    int result = fs_read_file("hello.txt", file_buffer, sizeof(file_buffer));

    char *msg;
    if (result >= 0) {
        msg = file_buffer;
    } else {
        msg = "Error: hello.txt not found!";
    }

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
