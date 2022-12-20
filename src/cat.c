main() {
    extern int read(), write(), brk();
    int x;
    char* buf;
    buf = brk(10000);
    while ((x = read(0, buf, 10000)) > 0)
        write(1, buf, x);
}
