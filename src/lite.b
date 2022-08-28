/*
 * lite kernel source
 */

/*
 * set by lite.asm
 * offsets are hardcoded
 */
KERNSEG;
_deqkey;
_rwblk;

/*
 * syscall table, used by lite.asm
 * int 0x20
 */

systab[12] =
    sysexit,
    sysalloc, sysfree,
    sysopen, sysclose,
    sysread, syswrite,
    sysseek,
    sysdup, sysdup2,
    sysexec;

err() return -1;

/*
 * memory manager
 * currently, allocatable memory [0x10000-0x80000], up to 200 chunks
 * freelist [3 words], [0] = size (high bit = is used), [1] = prev, [2] = next
 */

freelist[600] = 060000, 0, 0;
lowmem = 020000;

freenode(prev, size) {
    auto n;
    n = 0;
    while (freelist[n]) {
        n = n + 3;
        if (n == 600) return -1;
    }
    n = n + freelist;
    n[0] = size;
    n[1] = prev;
    if (n[2] = prev[2])
        prev[2][1] = n;
    prev[2] = n;
    return n;
}

sumnode(n1, n2) {
    n1[0] = n1[0] + n2[0];
    n2[0] = 0;
    if (n1[2] = n2[2])
        n1[2][1] = n1;
    return n1;
}

memset(seg, ptr, val, size) asm
    0003, 0002, 0003, 0003, 0003, 0004, 0003, 0005,
    0001, 0013, 0214, 0302, 0131, 0130, 0137, 0007,
    0374, 0363, 0253, 0216, 0302;

zeromem(seg, size) {
    memset(seg, 0, 0, size << 3);
    return seg;
}

sysalloc(size) {
    auto res, tr, x;
    size = size + 15 >> 4;
    size = size ? size : 010000;
    res = lowmem;
    tr = freelist;
    while (tr) {
        if (!(tr[0] & 0100000)) {
            if (tr[0] == size) return tr[0] = size | 0100000, zeromem(res, size);
            if (tr[0] > size) {
                if ((x = freenode(tr, size)) < 0)   
                    return 0;
                tr[0] = tr[0] - size;
            }
        }
        res = res + (tr[0] & 077777);
        tr = tr[2];
    }
    return 0;
}

sysfree(ptr) {
    auto res, tr;
    res = lowmem;
    tr = freelist;
    while (tr) {
        if (tr[0] & 0100000) {
            if (ptr == res) {
                tr[0] = tr[0] & 077777;
                if (!(tr[1][0] & 0100000))
                    tr = sumnode(tr[1], tr);
                if (!(tr[2][0] & 0100000))
                    sumnode(tr, tr[2]);
                return 0;
            }
        }
        res = res + (tr[0] & 077777);
        tr = tr[2];
    }
    return -1;
}

/*
 * console i/o
 */

screen = 0134000; bottom = 0; x = 0; y = 10; columns = 80; lines = 25; attr = 03400;
cursor = 1; sx; sy;

updscr() {
    if (y < bottom + 25 & y >= bottom) return;
    while (y >= bottom + 25) bottom++;
    while (y < bottom) bottom--;
    cli();
    outb(12, 01724);
    outb(bottom * columns >> 8, 01725);
    outb(13, 01724);
    outb(bottom * columns & 0377, 01725);
    sti();
}

updcur() {
    if (!cursor) return;
	cli();
	outb(14, 01724);
	outb(y * 80 + x >> 8, 01725);
	outb(15, 01724);
	outb(y * 80 + x & 0377, 01725);
	sti();
}

coutchar(c) {
    switch (c) {
        case '*n':  y++, updscr(); /* break; */
        case '*r':  x = 0; break;
        case '*t':  x = x + 8 - x % 8; break;
        case '*b':  x--; coutchar(' '); /* break; */
        case 1:     x--; break;             /* ^A */
        case 23:    y--; updscr(); break;   /* ^W */
        case 4:     x++; break;             /* ^D */
        case 19:    y++; updscr(); break;   /* ^S */
        case 21:    break;
        case 033:   return 1;               /* esc */
        default:
            c = c | attr;
            lfar(screen, y * columns + x++, c);
            break;
    }
    if (x > columns) {
        x = x - columns;
        y++, updscr();
    }
    return 0;
}

cin(fp, buf, len, seg) {
    auto c, res;
    res = len;
    while (len--) {
        asm 0004, 0377,                         /* vauto (-1); */
            0005, 0001, 0000,                   /* extrn (deqkey); */
            0001, 0004, 0130, 0377, 0320, 0120, /* native (pop ax; call ax; push ax); */
            0026, 0016;                         /* set; pop; */
        if (c == 24) return res - len - 1;      /* ^X */
        coutchar(lfchar(seg, buf++, c)), updcur();
    }
    return res;
}

atoi(seg, bufp) {
    auto n, c;
    if (fchar(seg, *bufp) == '**') {
        n = fchar(seg, ++*bufp);
        ++*bufp;
        return n;
    }
    n = 0;
    while ((c = fchar(seg, (*bufp)++)) >= '0' & c <= '9')
        n = n * 10 + c - '0';
    (*bufp)--;
    return n;
}

ncc(n, c) while (n--) coutchar(c);

esc(seg, bufp) {
    auto n, b;
    b = *bufp;
    while (1) {
        n = atoi(seg, bufp);
        switch (fchar(seg, (*bufp)++)) {
            case 'x': x = n; break;
            case 'y': y = n; break;
            case ' ': ncc(n, ' '); break;
            case 'c': cursor = n; break;
            case 'a': attr = n << 8; break;
            case 's':
                if (n) x = sx, y = sy;
                else sx = x, sy = y;
                break;
            case ';':
                updscr();
                return *bufp - b;
        }
    }
}

cout(fp, buf, len, seg) {
    auto res;
    res = len;
    while (len--)
        if (coutchar(fchar(seg, buf++)))
            len = len - esc(seg, &buf);
    updcur();
    return res;
}

/*
 * disk i/o
 */

fblock;
dirblock; dirend; dirsiz;

blk_init() {
    auto nblks, i;
    i = 1;
    fblock = alloc(1024);
    rwblk(fblock, 0, 0);            /* read disk meta */
    nblks = far(fblock, 256);       /* size of disk in KiB */
    nblks = nblks << 2;             /* size of fblock in bytes */
    dirsiz = far(fblock, 259);
    dirend = far(fblock, 260);
    free(fblock);
    fblock = alloc(nblks);
    nblks = nblks + 1023 >> 10;     /* size of fblock in KiB */
    dirblock = nblks + 1;
    while (nblks--) rwblk(fblock + (((i - 1) << 6)), i++, 0);
}

blk_quit() {
    rwblk(fblock, 0, 0);            /* read disk meta */
    lfar(fblock, 259, dirsiz);
    lfar(fblock, 260, dirend);
    rwblk(fblock, 0, 1);
}

freeblk(prev) {
    auto i;
    i = 0;
    while (far(fblock, i)) i = i + 2;
    if (prev != -1) lfar(fblock, prev << 1, i >> 1);
    lfar(fblock, i, -1);
    lfar(fblock, ++i, prev);
    return i >> 1;
}

/*
 * rwblk: high-level gate for asm func
 *  extrn (_rwblk);
 *  auto (+3);
 *  auto (+4);
 *  auto (+2);
 *  native (pop di; pop dx; pop bx; pop ax; call ax; push ax);
 *  ret;
 */

rwblk(buf, block, mode) asm
    0005, 0002, 0000, 0003, 0003, 0003, 0004, 0003,
    0002, 0001, 0007, 0137, 0132, 0133, 0130, 0377,
    0320, 0120, 0011;

/*
 * filesystem
 * file descriptor [8 words]:
 *  [0] = read function
 *  [1] = write function
 *  [2] = disk node
 *  [3] = buffer
 *  [4] = offset
 *  [5] = size
 *  [6] = first node
 *  [7] = last node
 *  [8] = block of filemeta
 *  [9] = offset of filemeta
 */
fdsiz = 10;

filetab[180] =
    cin, err,  0, 0, 0, 0, 0, 0, 0, 0,  /* stdin */
    err, cout, 0, 0, 0, 0, 0, 0, 0, 0,  /* stdout */
    err, cout, 0, 0, 0, 0, 0, 0, 0, 0,  /* stderr */
    din, dout, 0, 0, 0, 0, 0, 0, 0, 0;  /* root dir */

findfd() {
    auto fd;
    fd = 0;
    while (fd < 20)
        if (!filetab[fd++ * fdsiz])
            return --fd;
    return -1;
}

din(fp, buf, len, seg) {
    auto res;
    res = 0;
    while (len--) {
        if (fp[4] == fp[5]) return res;
        lfchar(seg, buf++, fchar(fp[3], fp[4]++ & 1023));
        if (!(fp[4] & 1023)) {
            if (rwblk(fp[3], fp[2] = far(fblock, fp[2] * 2), 0) < 0)
                return -1;
        }
        res++;
    }
    return res;
}

dout(fp, buf, len, seg) {
    auto res, i;
    res = len;
    while (len--) {
        if (fp[4] != 0 & !(fp[4] & 1023)) {
            rwblk(fp[3], fp[2], 1);
            if ((i = far(fblock, fp[2] * 2)) != -1)
                fp[2] = i;
            else fp[2] = freeblk(fp[2]);
        }
        lfchar(fp[3], fp[4]++ & 1023, fchar(seg, buf++));
    }
    if (fp[5] < fp[4]) fp[5] = fp[4];
    return res;
}

fs_init() {
    rwblk(filetab[3 * fdsiz + 3] = alloc(1024), filetab[3 * fdsiz + 2] = dirblock, 0);
    filetab[3 * fdsiz + 5] = dirsiz;
    filetab[3 * fdsiz + 6] = dirblock;
    filetab[3 * fdsiz + 7] = dirend;
}

sysopen(file, mode, _, seg) {
    auto c, i, fd, fp, buf[8];
    if ((fd = dup(3)) < 0) return -1;
    fp = filetab + fd * fdsiz;
    if (seek(fd, 0, 0) < 0) return close(fd), -1;
    while (i = read(fd, buf, 16)) {
        if (i < 0) return close(fd), -1;
        i = 0;
        while (fchar(seg, file + i) == (c = char(buf, i)))
            if (!c | i++ == 7) {
                fp[8] = fp[2];
                fp[9] = (fp[4] & 1023) - 16;
                fp[0] = mode ? err : din;
                fp[1] = mode ? dout : err;
                fp[2] = fp[6] = buf[4];
                fp[4] = 0;
                fp[5] = buf[6];
                fp[7] = buf[5];
                if (rwblk(fp[3], fp[2], 0) < 0) return -1;
                return fd;
            }
    }
    if (!mode) return close(fd), -1;
    dirsiz = dirsiz + 16;
    fp[8] = fp[2];
    fp[9] = (fp[4] & 1023) - i;
    fp[0] = err, fp[1] = dout;
    fp[2] = fp[6] = fp[7] = freeblk(-1);
    fp[4] = fp[5] = 0;
    rwblk(fblock + (fp[2] >> 10), fp[2] >> 6, 1);
    seek(3, 0, 2);
    i = 0;
    while (lchar(buf, i, fchar(seg, file + i))) i++;
    while (i < 16) lchar(buf, i++, 0);
    i = 0;
    while (i < 1024) lfchar(fp[3], i++, 0);
    buf[4] = fp[2];
    buf[5] = fp[7];
    buf[6] = fp[5];
    write(3, buf, 16);
    return fd;
}

sysclose(fd) {
    auto i, fp;
    fp = filetab + fd * fdsiz;
    if (fp[1] == dout) rwblk(fp[3], fp[2], 1);
    if ((i = fp[3]) > 0) {
        if (fd != 3 & fp[1] == dout) {
            seek(3, fp[9] + 8, 0);
            write(3, fp + 6, 2);
            write(3, fp + 7, 2);
            write(3, fp + 5, 2);
        }
        if (sysfree(i) < 0) return -1;
    }
    i = 0;
    while (i < fdsiz) filetab[fd * fdsiz + i++] = 0;
    return 0;
}

sysread(fd, buf, len, seg)  return filetab[fd = fd * fdsiz](filetab + fd, buf, len, seg);
syswrite(fd, buf, len, seg) return filetab[fd = fd * fdsiz + 1](filetab + fd - 1, buf, len, seg);
sysdup(fd)                  return sysdup2(fd, new = findfd());

sysdup2(fd, new) {
    auto i, fp, np;
    if (fd == new) return -1;
    fp = filetab + fd * fdsiz, np = filetab + new * fdsiz;
    if (np) if (close(new) < 0) return -1;
    i = fdsiz;
    while (i--) np[i] = fp[i];
    if (fp[3]) {
        if ((np[3] = alloc(1024)) < 0) return close(new), -1;
        i = 1024;
        while (i--) lfchar(np[3], i, fchar(fp[3], i));
    }
    return new;
}

sysseek(fd, offset, p) {
    auto fp;
    fp = filetab + fd * fdsiz;
    fp[4] = (p ? p == 1 ? fp[4] : fp[5] : 0) + offset;
    return fp[4];
}

/*
 * process manager
 */

sysexec(file, ac, av, seg) {
    auto fd, p;
    
    if ((fd = sysopen(file, 0, 0, seg)) < 0) return -1;
    if ((p = alloc(0)) < 0) return close(fd), -1;
    if (sysread(fd, 0, filetab[fd * fdsiz + 5], p) < 0)
        return close(fd), free(p), -1;
    close(fd);
    cli();
    asm 0003, 0376,                     /* auto (-2); */
        0001, 0023,                     /* native ... */
        /* pop ax; mov ds, ax; mov es, ax; mov ss, ax;
         * mov bx, sp; xor sp, sp; push bx;
         * sti; push ax; push 0; */
        0130, 0216, 0330, 0216, 0300, 0216, 0320, 0211,
        0343, 0061, 0344, 0123,  0373, 0120, 0152, 0000,
        0313;                           /* native(retf); */
}

sysexit(a, b, c, seg) {
    free(seg);  
    asm 0001, 0003, 0203, 0305, 22;     /* native(add bp, 22); */
    /* why 22? skip 4 args [8], ss, sp [12], call meta [18], exec (fp, p) [22] */
}

/*
 * init
 */

main() {
    blk_init();
    fs_init();
    printf("%s*n", libmark());
    execv("shell", 0, 0);
    close(3);
    rwblk(fblock, 1, 1);
    printf("%d*n", dirsiz);
    blk_quit();
    while (1);
}

/*
 * some useful asm instructions
 */

cli() asm                       /* native(cli); */
    0001, 0001, 0372;

sti() asm                       /* native(sti); */
    0001, 0001, 0373;

outb(x, port) asm               /* auto (+2); auto (+3); native(pop dx; pop ax; out dx, al); */
    0003, 0002, 0003, 0003, 0001, 0003, 0132, 0130,
    0356;
