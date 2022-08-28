/*
 * lib.b -- standard library for b
 */

libmark() return "LIBMARK:  *"lite, 0.3; bc, 0.2; lib.b, 0.3; b-run, 0.7; shell, 0.1;*"  ";

/*
 * system call
 * auto (+2);
 * auto (+3);
 * auto (+4);
 * auto (+5);
 * native (nop (x 18); pop dx; pop cx; pop bx; pop ax; int 0x21);
 * ret;
 */

_syscall(ax, bx, cx, dx) asm
    0003, 0002, 0003, 0003, 0003, 0004, 0003, 0005,
    0001, 0030, 0220, 0220, 0220, 0220, 0220, 0220,
    0220, 0220, 0220, 0220, 0220, 0220, 0220, 0220,
    0220, 0220, 0220, 0220, 0132, 0131, 0133, 0130,
    0315, 0041, 0011;

/*
 * system calls
 */

exit()              return _syscall(0);
alloc(size)         return _syscall(1, size);
free(ptr)           return _syscall(2, ptr);
open(file, mode)    return _syscall(3, file << 1, mode);
close(fd)           return _syscall(4, fd);
read(fd, buf, len)  return _syscall(5, fd, buf << 1, len);
write(fd, buf, len) return _syscall(6, fd, buf << 1, len);
seek(fd, offset, p) return _syscall(7, fd, offset, p);     /* not impl */
dup(fd)             return _syscall(8, fd);
dup2(fd, new)       return _syscall(9, fd, new);
execv(file, ac, av) return _syscall(10, file << 1, ac, av); /* no args */

/*
 * library functions
 */

putchar(c)          return write(1, &c, 1), c;
getchar()           auto c; return read(0, &c, 1) ? c & 0377 : -1;

/*
 * asm functions -- written in assembly, and dumped here
 * char, lchar, fchar, lfchar, far, lfar
 *
 * char:
 *      auto (+3);
 *      auto (+2);
 *      native (pop di; shl di, 1; pop ax; add di, ax; mov al, [di]; xor ah, ah; push ax);
 *      ret;
 * lchar:
 *      auto (+4);
 *      auto (+3);
 *      auto (+2);
 *      native (pop di; shl di, 1; pop ax; add di, ax; pop ax; stosb);
 *      auto (+4);
 *      ret;
 * fchar:
 *      auto (+3);
 *      auto (+2);
 *      native (mov ax, ds; pop ds; pop di; push word [di]; mov ds, ax);
 *      const (0377);
 *      and;
 *      ret;
 * lfchar:
 *      auto (+4);
 *      auto (+3);
 *      auto (+2);
 *      native (mov cx, es; pop es; pop di; pop ax; stosb; mov es, cx);
 *      auto (+4);
 *      ret;
 * far:
 *      auto (+3);
 *      auto (+2);
 *      native (mov ax, ds; pop ds; pop di; shl di, 1; push word [di]; mov ds, ax);
 *      ret;
 * lfar:
 *      auto (+4);
 *      auto (+3);
 *      auto (+2);
 *      native (mov cx, ds; pop ds; pop di; shl di, 1; pop word [di]; mov ds, cx);
 *      auto (+4);
 *      ret;
 */

char(s, n) asm
    0003, 0003, 0003, 0002, 0001, 0013, 0137, 0321,
    0347, 0130, 0001, 0307, 0212, 0005, 0060, 0344,
    0120, 0011;

lchar(s, n, c) asm
    0003, 0004, 0003, 0003, 0003, 0002, 0001, 0010,
    0137, 0321, 0347, 0130, 0001, 0307, 0130, 0252,
    0003, 0004, 0011;

fchar(s, n) asm
    0003, 0003, 0003, 0002, 0001, 0010, 0214, 0330,
    0037, 0137, 0377, 0065, 0216, 0330, 0002, 0377,
    0000, 0033, 0011;

lfchar(s, n, c) asm
    0003, 0004, 0003, 0003, 0003, 0002, 0001, 0010,
    0214, 0301, 0007, 0137, 0130, 0252, 0216, 0301,
    0003, 0004, 0011;

far(s, n) asm
    0003, 0003, 0003, 0002, 0001, 0012, 0214, 0330,
    0037, 0137, 0321, 0347, 0377, 0065, 0216, 0330,
    0011;

lfar(s, n, c) asm
    0003, 0004, 0003, 0003, 0003, 0002, 0001, 0012,
    0214, 0331, 0037, 0137, 0321, 0347, 0217, 0005,
    0216, 0331, 0003, 0004, 0011;

/*
 * some extra functions
 */

printn(n, b) {
    auto i;
    if (i = n / b) printn(i, b);
    putchar(char("0123456789abcdef", n % b));
}

puts(s) {
    auto i, c;
    i = 0;
    while (c = char(s, i++))
        putchar(c);
}

printf(fmt, va) {
    auto ap, i, n, c;
    i = 0;
    ap = &va;
    while (c = char(fmt, i++)) {
        if (c != '%') {
            putchar(c);
            continue;
        }
        c = char(fmt, i++);
        if (c == 's') puts(*ap++);
        else if (c == 'o') printn(*ap++, 8);
        else if (c == 'x') printn(*ap++, 16);
        else if (c == 'd') {
            if ((n = *ap++) < 0)
                putchar('-'), n = -n;
            printn(n, 10);
        }
        else if (c == 'c') putchar(*ap++);
    }
}

/* eof */
\
