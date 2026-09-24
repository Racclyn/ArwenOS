unsigned int page_directory[1024] __attribute__((aligned(4096)));

unsigned int first_page_table[1024] __attribute__((aligned(4096)));

void init_paging() {
    // Each page is 4KB. 1024 pages * 4KB = 4MB.
    for (int i = 0; i < 1024; i++) {
        first_page_table[i] = (i * 0x1000) | 3;
    }

    page_directory[0] = ((unsigned int)first_page_table) | 3; // Present, Read/Write

    for (int i = 1; i < 1024; i++) {
        page_directory[i] = 0; // Not present
    }

    __asm__ volatile (
        "mov %0, %%eax\n\t"
        "mov %%eax, %%cr3\n\t"     // Load Page Directory into CR3
        "mov %%cr0, %%eax\n\t"
        "or $0x80000000, %%eax\n\t" // Set the PG (Paging) bit (bit 31)
    "mov %%eax, %%cr0\n\t"     // Enable Paging!
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

    char *msg = "PAGING ENABLED SUCCESSFULLY! :3";
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
