printcn(n, b, digits) {
    auto i;
    if ((i = n / b) | --digits) printcn(i, b, digits);
    putchar(char("0123456789abcdef", n % b));
}

main() {
    auto buf[8], i, j, c, n;
    i = 0;
    while (n = read(0, buf, 16)) {
        printcn(i, 16, 4);
        putchar(' ');
        putchar(' ');
        i = i + 16;
        j = 0;
        while (j < n) {
            printcn(char(buf, j++), 16, 2);
            putchar(' ');
            if (!(j & 7)) putchar(' ');
        }
        while (j < 16) {
            write(1, "   ", 3);
            if (!(++j & 7)) putchar(' ');
        }
        j = 0;
        putchar('|');
        while (j < n) {
            if ((c = char(buf, j++)) >= ' ' & c < 128) putchar(c);
            else putchar('.');
        }
        putchar('|');
        putchar('*n');
    }
    exit();
}
