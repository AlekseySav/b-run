/*
 * edit.b -- simple code editor (requires file size <= 285 lines)
 * always edit 1.b file
 */

file; filename[5];
lines[285]; buf[11400]; ln;
x = 0; y = 0; py = 0;
nums; cmdmod; cmd[10]; cmdln;

txt() {
    auto n, i, s;
    i = n = 0;
    write(1, "*e0c0s0x0y7a;", 12);
    while (i + py < ln & i < 24) {
        if (nums) printnc(py + i + 1, 2), putchar(179);
        write(1, lines[py + i++], nums ? 76 : 80);
    }
    write(1, "~~~*e112a0x24y80 0x;", 19);
    printf(" (%s:%d:%d) (%d/285 lines) (ctrl+q)", filename, y + py + 1, x + 1, ln);
    if (cmdmod) write(1, "*e50x;L: ", 8), write(1, cmd, cmdln);
    else write(1, "*e7a;", 4);
    write(1, "*e1s1c;", 6);
}

main() {
    auto i, c;
    i = 0;
    while ((c = getchar()) != '*n')
        lchar(filename, i++, c);
    lchar(filename, i, 0);
    c = ln = i = 0;
    while ((file = open(filename, 0)) < 0)
        close(open(filename, 1));
    lines[0] = buf;
    while (read(file, &c, 1))
        if (c == '*n') i = i + 80 - i % 80, lines[++ln] = buf + (i >> 1);
        else lchar(buf, i++, c);
    ln++;
    close(file);
    write(1, "*e0x0y;", 6);
    clr();
    while (c = getchar()) {
        if (cmdmod) {
            if (c == ';') lchar(cmd, cmdln, 0), docmd(), cmdmod = 0, clr();
            else if (c == '*b') cmdln--;
            else lchar(cmd, cmdln++, c);
            continue;
        }
        switch (c) {
            case '*b':
                lchar(lines[y + py], --x, ' ');
                break;
            case '*t':
                i = x;
                x = x + 8 - x % 8;
                puttab(i);
                break;
            case '*n':  newline(); x = 0; break;
            case 23:    y--; break;             /* ^W */
            case 1:     x--; break;             /* ^A */
            case 19:    y++; break;             /* ^S */
            case 4:     x++; break;             /* ^D */
            case 21:    nums = !nums; clr(); break;    /* ^U */
            case 16:                            /* ^P */
                cmdmod = 1;
                cmdln = 0;
                write(1, "*e24y53x;", 8);
                break;
            case 18:                            /* ^R */
                if (py >= ln - 15) { clr(); break; }
                py = py + 15;
                y = y - 15;
                if (y < 0) y = 0;
                clr();
                break;
            case 5:                             /* ^E */
                if (py < 15) { clr(); break; }
                py = py - 15;
                y = y + 15;
                if (y >= 24) y = 24;
                clr();
                break;
            case 17:    quit();                 /* ^Q */
            default:    lchar(lines[y + py], x++, c); break;
        }
        txt();
    }
}

docmd() {
    if (cmd[0] == 'ln') {
        py = atoi(cmd + 1) - 1;
        y = 0;
    }
}

atoi(s) {
    auto n, c, i;
    i = n = 0;
    while (c = char(s, i++))
        if (c != ' ') n = n * 10 + c - '0';
    return n;
}

clr() {
    auto s;
    s = "*e7a0x0y2000 **0x**0y;";
    lchar(s, 13, nums ? x + 4 : x);
    lchar(s, 16, y);
    write(1, s, 19);
    txt();
}

puttab(i) while (i < x) lchar(lines[y + py], i++, ' ');

newline() {
    auto i;
    i = ln;
    ln++;
    while (i > y) {
        lines[py + i + 1] = lines[py + i];
        i--;
    }
    lines[py + ++y] = buf + (ln * 80 >> 1);
}

quit() {
    auto i, len;
    i = 0;
    write(1, "*e0x0y2000 0x0y;", 15);
    file = open(filename, 1);
    while (i < ln) {
        len = 0;
        while (char(lines[i], len++));
        lchar(lines[i], len - 1, '*n');
        write(file, lines[i++], len);
    }
    close(file);
    exit();
}

printnc(num, a) {
    auto i;
    if (i = num / 10) printnc(i, --a);
    else while (a--) putchar(' ');
    putchar(num % 10 + '0');
}
