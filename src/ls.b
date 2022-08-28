/*
 * ls
 * list fd=3 files, assuming it's a directorty
 */

main() {
    auto buf[8], i;
    seek(3, 0, 0);
    while (read(3, buf, 16))
        if (buf[0])
            write(1, buf, 8);
    putchar('*n');
    exit();
}
