/*
 * build filesystem for lite
 * 
 * disk organization:
 *  0000-01ff           masterboot
 *  0200-03ff           meta
 *  0400-xxxx           fnode table
 *  xxxx-yyyy           file system
 * 
 * meta:
 * [0]                  size of disk in KiB
 * [1]                  first block within kernel
 * [2]                  kernel size in KiB
 * [3]                  root dir size
 * [4]                  last root dir block
 * xxxx = (meta[0] >> 8) + 0400
 * yyyy = meta[0]
 * 
 * input: argv[1] = disk size, argv[2...] = filename...  [> image]
 */

#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

struct dirent {
    char file[8];
    u_int16_t node;
    u_int16_t last;
    u_int16_t size;
};

static u_int16_t dir[512], * dd = dir;
static u_int16_t meta[256];
static u_int16_t* fnode;
u_int16_t node = 0;

static u_int16_t nextnode(void) {
    fnode[node * 2] = node + 1;
    node++;
    fnode[node * 2 + 1] = node - 1;
    fnode[node * 2] = 0xffff;
    return node;
}

static void add(char* name) {
    int n;
    char buf[1024];
    char* p = basename(name);
    fnode[node * 2 + 1] = 0xffff;
    if (!strcmp(p, "lite"))
        meta[1] = node;
    FILE* f = fopen(name, "rb");
    dd[4] = node;
    while (memset(buf, 0, 1024), (n = fread(buf, 1, 1024, f)) > 0) {
        write(1, buf, 1024);
        nextnode();
        dd[6] += n;
        if (!strcmp(p, "lite")) meta[2]++;
    }
    strncpy(dd, p, 8);
    dd[5] = node;
    dd += 8;
    fclose(f);
}

int main(int argc, char** argv) {
    u_int32_t size, len = strlen(argv[1]) - 1;
    switch (argv[1][len]) {
        case 'K': size = 1024; break;
        case 'M': size = 1024 * 1024; break;
        default: size = 1; break;
    }
    argv[1][len] = 0;
    size *= atoi(argv[1]);
    meta[0] = (size >>= 8) >> 2;
    fnode = calloc(1, size);
    node = 1 + size / 1024;

    for (int i = 0; i < node * 2; i++) fnode[i] = 1;
    lseek(1, size + 512 + 1024, SEEK_SET);
    fnode[node * 2] = 0xffff;
    fnode[node * 2 + 1] = 0xffff;
    node++;
    for (int i = 2; i < argc; i++)
        add(argv[i]);
    meta[3] = (dd - dir) << 1;
    meta[4] = (meta[0] >> 8) + (meta[3] + 1023 >> 10);
    lseek(1, 0, SEEK_SET);
    write(1, meta, 512);
    write(1, fnode, size);
    write(1, dir, 1024);
    free(fnode);
    lseek(1, (size << 8) - 513, SEEK_SET);
    write(1, "\0", 1);
    return 0;
}
