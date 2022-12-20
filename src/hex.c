/* hexdump but C version */

main() {
    extern int printcn(), putchar(), read(), write();
    int i, j, c, n, x1, x2, x3, x4, x5, x6, x7, x8;
    char* buf, *p;
    buf = &x8;
    i = 0;
    while ((n = read(0, buf, 16)) > 0) {
        printcn(i, 16, 4);
        putchar(' ');
        putchar(' ');
        i += 16;
        j = 0;
        p = buf;
        while (j++ < n) {
            printcn(*p++ & 0xff, 16, 2);
            putchar(' ');
            if (!(j & 7)) putchar(' ');
        }
        while (j++ <= 16)
            write(1, "   ", 3 + !(j & 7));
        p = buf;
        putchar('|');
        while (n--) {
            if ((c = *p++) >= ' ' & c < 128) putchar(c);
            else putchar('.');
        }
        putchar('|');
        putchar('\n');
    }
}


printcn(n, b, digits)
int n, b, digits;
{
    extern int printcn(), putchar();
    int i;
    char* fmt;
    if ((i = n / b) | --digits) printcn(i, b, digits);
    fmt = "0123456789abcdef";
    putchar(fmt[n % b]);
}
