buf[512];

main() {
    auto n, x;
    n = 0;
    while ((x = read(0, buf, 1024)) > 0)
        n = n + x;
    printn(n, 10);
    putchar('*n');
    exit();
}
