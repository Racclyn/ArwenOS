#include "fs.h"

unsigned int page_directory[1024] __attribute__((aligned(4096)));
unsigned int first_page_table[1024] __attribute__((aligned(4096)));

void init_paging() {
    for (int i = 0; i < 1024; i++) {
        first_page_table[i] = (i * 0x1000) | 3;
    }
    page_directory[0] = ((unsigned int)first_page_table) | 3;
    for (int i = 1; i < 1024; i++) {
        page_directory[i] = 0;
    }

    __asm__ volatile (
        "mov %0, %%eax\n\t"
        "mov %%eax, %%cr3\n\t"
        "mov %%cr0, %%eax\n\t"
        "or $0x80000000, %%eax\n\t"
        "mov %%eax, %%cr0\n\t"
        : : "r"(page_directory) : "%eax", "memory"
    );
}

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
