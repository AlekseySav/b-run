/*
 * shell.b
 */

/* globals */
_() {
    asm("_tokc: dw 0");
    asm("_fd: dw 0, 0, 0");
    asm("_bakfd: dw 0, 0, 0");
    asm("_buf: times 80 db 0");
    asm("_xbuf: times 8 db 0");
}

getc() {
    extern int tokc, getchar();
    int c;
    if (tokc) {
        c = tokc, tokc = 0;
        return c;
    }
    return getchar();
}

ungetc(c)
int c;
{
    extern int tokc;
    return tokc = c;
}

main() {
    extern int getc(), file(), dup(), dup2(), close(), execv(), puts();
    extern int fd[], bakfd[];
    extern char buf[];
    int c, i;
    while (1) {
        i = 0;
        fd[0] = 0, fd[1] = 1, fd[2] = 2;
        puts("L: ");
        while ((c = getc()) != '\n') {
            if (c == 8) i--;
            else if (c == '<') file(0);
            else if (c == '>') file(1);
            else buf[i++] = c;
        }
        buf[i] = 0;
        i = 0;
        while (i < 80) if (buf[i++] == ' ') buf[i - 1] = 0;

        bakfd[0] = dup(0), bakfd[1] = dup(1), bakfd[2] = dup(2);
        dup2(fd[0], 0), dup2(fd[1], 1), dup2(fd[2], 2);
        if (fd[0] != 0) close(fd[0]);
        if (fd[1] != 1) close(fd[1]);
        if (fd[2] != 2) close(fd[2]);
        execv(buf, 0, 0);
        dup2(bakfd[0], 0), dup2(bakfd[2], 1), dup2(bakfd[2], 2);
        close(bakfd[0]), close(bakfd[1]), close(bakfd[2]);
    }
}

file(n)
int n;
{
    extern int getc(), ungetc(), open(), puts(), exit(), fd[];
    extern char xbuf[];
    int c, i;
    i = 0;
    while ((c = getc()) != ' ' & c != '\n') {
        if (c == '\b') i--;
        else xbuf[i++] = c;
    }
    xbuf[i] = 0;
    ungetc(c);
    if ((fd[n] = open(xbuf, n)) < 0) {
        puts("redirect file error");
        exit();
    }
}
