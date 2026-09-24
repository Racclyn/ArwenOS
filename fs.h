// Future TODO: Down the road will want to create a compression.h which can be utilized by the internal read-only fs to store files in a more optimized way
//              Additionally, will want to utilize compression.h to compress the majority of the kernel, besides paging.
//              Will want a read-write FS possibly, depending on where the OS goes, likely not due to the hassle. That said, I'm thinking i'll just write read-only emulators that run on the OS to be kind of a neat little thing. So i'll probably want to make at least a ramdisk based read-write FS.'
#ifndef FS_H
#define FS_H

struct FileEntry {
    char name[32];
    unsigned int offset;
    unsigned int size;
} __attribute__((packed));

struct FSHeader {
    char magic[4];
    unsigned int file_count;
} __attribute__((packed));

#define FS_START_ADDRESS 0x18000

static inline int fs_read_file(const char *filename, char *buffer, unsigned int max_len) {
    struct FSHeader *header = (struct FSHeader *)FS_START_ADDRESS;

    if (header->magic[0] != 'S' || header->magic[1] != 'F' ||
        header->magic[2] != 'S' || header->magic[3] != '1') {
        return -1;
        }

        struct FileEntry *entries = (struct FileEntry *)(FS_START_ADDRESS + sizeof(struct FSHeader));
    char *data_base = (char *)(FS_START_ADDRESS + sizeof(struct FSHeader) + (header->file_count * sizeof(struct FileEntry)));

    for (unsigned int i = 0; i < header->file_count; i++) {
        int match = 1;
        for (int j = 0; j < 32; j++) {
            if (entries[i].name[j] != filename[j]) {
                match = 0;
                break;
            }
            if (filename[j] == '\0') break;
        }

        if (match) {
            unsigned int bytes_to_read = entries[i].size < max_len ? entries[i].size : max_len - 1;
            char *file_src = data_base + entries[i].offset;
            for (unsigned int k = 0; k < bytes_to_read; k++) {
                buffer[k] = file_src[k];
            }
            buffer[bytes_to_read] = '\0';
            return (int)entries[i].size;
        }
    }
    return -2;
}

#endif
