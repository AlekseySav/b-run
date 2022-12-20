/*
 * ls
 * list fd=3 files, assuming it's a directorty
 */

main() {
    extern int seek(), read(), write(), putchar();
    int i, x1, x2, x3, x4, x5, x6, x7, x8;
    char* buf;
    buf = &x8;
    seek(3, 0, 0);
    while (read(3, buf, 16) > 0)
        if (*buf)
            write(1, buf, 8);
    putchar('\n');
}
