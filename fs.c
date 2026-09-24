#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

struct FileEntry {
    char name[32];
    unsigned int offset;
    unsigned int size;
} __attribute__((packed));

int main() {
    struct dirent **namelist;
    int n = scandir("fs", &namelist, NULL, alphasort);
    if (n < 0) {
        perror("[-] Failed to scan fs/ directory");
        return 1;
    }

    int count = 0;
    for (int i = 0; i < n; i++) {
        if (namelist[i]->d_name[0] == '.') continue;
        count++;
    }

    FILE *out = fopen("fs.bin", "wb");
    if (!out) {
        perror("[-] Failed to open fs.bin for writing");
        for (int i = 0; i < n; i++) free(namelist[i]);
        free(namelist);
        return 1;
    }

    fwrite("SFS1", 1, 4, out);
    fwrite(&count, sizeof(unsigned int), 1, out);

    long table_pos = ftell(out);
    struct FileEntry *entries = malloc(count * sizeof(struct FileEntry));
    memset(entries, 0, count * sizeof(struct FileEntry));
    fwrite(entries, sizeof(struct FileEntry), count, out);

    long header_size = 4 + 4 + (count * sizeof(struct FileEntry));
    int idx = 0;

    for (int i = 0; i < n; i++) {
        if (namelist[i]->d_name[0] == '.') {
            free(namelist[i]);
            continue;
        }

        char filepath[512];
        snprintf(filepath, sizeof(filepath), "fs/%s", namelist[i]->d_name);

        FILE *f = fopen(filepath, "rb");
        if (!f) {
            free(namelist[i]);
            continue;
        }

        fseek(f, 0, SEEK_END);
        long fsize = ftell(f);
        rewind(f);

        void *buf = malloc(fsize);
        fread(buf, 1, fsize, f);
        fclose(f);

        long current_pos = ftell(out);
        long offset_from_data_start = current_pos - header_size;

        strncpy(entries[idx].name, namelist[i]->d_name, 31);
        entries[idx].name[31] = '\0';
        entries[idx].offset = (unsigned int)offset_from_data_start;
        entries[idx].size = (unsigned int)fsize;

        fwrite(buf, 1, fsize, out);
        free(buf);
        free(namelist[i]);
        idx++;
    }
    free(namelist);

    fseek(out, table_pos, SEEK_SET);
    fwrite(entries, sizeof(struct FileEntry), count, out);

    free(entries);
    fclose(out);
    printf("[+] Packed fs/ into fs.bin successfully (%d files, sorted, packed)\n", count);
    return 0;
}
