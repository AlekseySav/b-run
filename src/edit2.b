/*
 * structure:
 *      fake<->t<->t<->....<->t<->fake ::: node->t->t->...->nil
 */
token; prev; next; fake; node; ntoks = 10000;
screen[3000]; scr; noattr;
keys[11]; comm;

ctype[128] =
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 3,
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0;

limit() write(2, "resource limit*n", 15), exit();
doalloc(size) auto x; return (x = alloc(size)) >= 0 ? x : limit();
isident(t) return far(token, t) > 255 | far(token, t) < 0;

iskey(sfar) {
    auto c, i, k;
    k = 0;
    while (k < 11) {
        i = 0;
        while ((c = char(keys[k], i)) == fchar(sfar, i))
            if (!c) return 1;
            else i++;
        k++;
    }
    return 0;
}

instok(t, c) {
    auto x, n;
    if (!(x = node)) limit();
    node = far(next, node);
    lfar(prev, x, t);
    lfar(next, x, n = far(next, t));
    lfar(prev, n, x);
    lfar(next, t, x);
    lfar(token, x, c);
    return x;
}

deltok(t) {
    auto p, n;
    p = far(prev, t), n = far(next, t);
    lfar(next, p, n);
    lfar(prev, n, p);
    lfar(next, t, node);
    node = t;
}

scrsend(c) lchar(screen, scr++, c);

attr(n) {
    if (noattr) return;
    scrsend('*e');
    scrsend(n + '0');
    scrsend('a');
    scrsend(';');
}

puttok(t) {
    auto c, s, i, k;
    s = far(token, t), i = 0;
    if (!isident(t)) {
        attr(8);
        if (s == '**') comm = comm | 1;
        else if (s == '/') comm = comm | 2;
        else comm = 0;
        if (comm == 3) noattr = !noattr;
        if (s == '*'' | s == '*"') attr(2), noattr = !noattr;
        scrsend(s);
        return;
    }
    if (ctype[fchar(s, 0)] == 1) attr(6);
    else if (far(token, far(next, t)) == '(') attr(9);
    else if (iskey(s)) attr(5);
    else attr(7);
    while (c = fchar(s, i++))
        scrsend(c);
}

inschar(str, c, at) {
    auto x;
    if (at < 0) {
        at = 0;
        while (fchar(str, at)) at++;
    }
    while (c) {
        x = fchar(str, at);
        lfchar(str, at, c);
        c = x, at++;
    }
    lfchar(str, at, 0);
}

add(t, c, at) {
    auto ct, tt;
    if ((ct = ctype[c]) & isident(t))
        return inschar(far(token, t), c, at);
    if (ct) {
        tt = doalloc(16);
        lfar(tt, 0, c);
        return instok(t, tt);
    }
    return instok(t, c);
}

main() {
    auto i, c;

    keys[0] = "asm";
    keys[1] = "auto";
    keys[2] = "break";
    keys[3] = "case";
    keys[4] = "continue";
    keys[5] = "default";
    keys[6] = "else";
    keys[7] = "if";
    keys[8] = "return";
    keys[9] = "switch";
    keys[10] = "while";

    token = doalloc(ntoks << 1);
    prev = doalloc(ntoks << 1);
    next = doalloc(ntoks << 1);
    fake = 0;
    lfar(token, fake, 0);
    lfar(next, fake, fake);
    lfar(prev, fake, fake);
    node = i = 1;
    while (i < ntoks) lfar(next, i, ++i);
    lfar(next, ntoks - 1, 0);

    while ((c = getchar()) != -1)
        add(far(prev, fake), c, -1);

    i = far(next, fake);
    c = 130;
    while (c--) {
        while (far(token, i) != '*n') i = far(next, i);
        i = far(next, i);
    }

    scr = 0;
    while (i != fake) {
        puttok(i);
        i = far(next, i);
    }
    write(1, screen, scr);

    free(token);
    free(prev);
    free(next);
    exit();
}
