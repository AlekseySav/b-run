/*
 * shell.b
 */

fd[3]; bakfd[3];

tokc;
getc()      auto c; return tokc ? c = tokc, tokc = 0, c : (getchar());
ungetc(c)   return tokc = c;

main() {
    auto c, i, buf[40];
    while (1) {
        i = endl = 0;
        fd[0] = 0, fd[1] = 1, fd[2] = 2;
        printf("L: ");
        while ((c = getc()) != '*n') {
            if (c == 8) i--;
            else if (c == '<') file(0);
            else if (c == '>') file(1);
            else lchar(buf, i++, c);
        }
        lchar(buf, i, 0);
        i = 0;
        while (i < 80) if (char(buf, i++) == ' ') lchar(buf, i - 1, 0);

        bakfd[0] = dup(0), bakfd[1] = dup(1), bakfd[2] = dup(2);
        dup2(fd[0], 0), dup2(fd[1], 1), dup2(fd[2], 2);
        if (fd[0] != 0) close(fd[0]);
        if (fd[1] != 1) close(fd[1]);
        if (fd[2] != 2) close(fd[2]);
        execv(buf, 0, 0);
        dup2(bakfd[0], 0), dup2(bakfd[2], 1), dup2(bakfd[2], 2);
        close(bakfd[0]), close(bakfd[1]), close(bakfd[2]);
    }
    exit();
}

file(n) {
    auto c, i, buf[4];
    i = 0;
    while ((c = getc()) != ' ' & c != '*n')
        if (c == '*b') i--;
        else lchar(buf, i++, c);
    lchar(buf, i, 0);
    ungetc(c);
    if ((fd[n] = open(buf, n)) < 0) printf("redirect file error"), exit();
}
