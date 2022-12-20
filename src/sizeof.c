main() {
    extern int read(), brk(), printn(), putchar();
    char* buf;
    int n, x;

    buf = brk(10000);
    x = 0;
    while ((n = read(0, buf, 10000)) > 0)
        x += n;
    printn(x, 10);
    putchar('\n');
}
