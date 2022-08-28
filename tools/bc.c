/*
 * tools/bc.c -- copy-pasted from src/bc.b
 * edited a bit, to make it possible to be compiled with gcc + added some tests
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#define char _char
#define lfchar lchar
#define fchar _char
#define far(s, i) ((s)[(i)])
#define lfar(s, i, c) (((short*)(s))[(i)] = (c))
#define enum _enum
#define quit() exit(0)
/*
 * errors:
 *  symtab:
 *      2s          symtable overflow
 *      2n          name overflow
 *  lex:
 *      ?c          bad character
 *      /*          unclosed comment
 *      2c          character queue overflow (internal error)
 *      '"          unclosed ' or "
 *      ''          empty ''
 *      ?*          bad ctrl character
 *  expr:
 *      ?e          bad token in expr
 *      !(          bad () [] ?: balance
 *      [?          expected value instead of [] or ?: braces
 *      ee          binary operator not expected
 *      -e          prefix operator not expected
 *      Le          expected lvalue
 *      Ne          value not expected
 *  statement:
 *      ,;          expected comma or semicolon
 *      0p          expected number
 *      ap          expected name
 *      br          bad 'break' syntax
 *      cs          bad 'case' syntax
 *      df          bad 'default' syntax
 *      co          bad 'continue' syntax
 *      el          bad 'else' syntax
 *      if          bad 'if' syntax
 *      wh          bad 'while' syntax
 *      IM          not implemented
 *  declaration:
 *      ,)          expected comma or ')'
 *      nd          expected name
 *      0d          expected number
 *      ]d          expected ']'
 *      [d          array used before its declaration
 *      2d          declaration overflow
 *      ;d          missing ';' after declaration
 */

short line = 0;

eprintn(n, b) {
    auto i;
    if (i = n / b) eprintn(i, b);
    i = n % b + '0';
    write(2, &i, 1);
}

error(c) {
    eprintn(line, 10);
    write(2, &c, 2);
    write(2, "\n", 1);
    quit();
}

/*
 * symbol table
 */

/*
 * entry:
 *  # word      usage
 *  0-3         name (up to 8 symbols)
 *  4           flags (bits: 1=key, 2=extrn, 4=local, 8=extrn array, 16=auto array)
 *  5           auto value
 *  6           key/extrn value
 *  7           prev-auto value
 *      4096 entries
 */

short* data; short datasiz = 0;
short* bytecode; short pc = 0;
short* symtab; short lastauto = 0; short symtabs = 4096;

lookup(name) short* name; {
    auto n, p, s, i;
    n = i = 0;
    while (s = char(name, i++)) n = (n * 1217 + s) % symtabs;
    p = n * 8;
    while (far(symtab, p + 4)) {
        i = 0;
        while (fchar(symtab, p * 2 + i) == (s = char(name, i++)))
            if (!s | i == 8) return p;
        p = (p + 8) % (symtabs * 8);
        if (p == n * 8) error('2s');
    }
    i = 0;
    while (lfchar(symtab, p * 2 + i, char(name, i))) i++;
    lfar(symtab, p + 7, lastauto);  /* prev-auto */
    return p;
}

init(name, value) short* name; {
    auto k;
    k = lookup(name);
    lfar(symtab, k + 4, 1);         /* keyword */
    lfar(symtab, k + 6, value);
    return k;
}

/*
 * lexer
 */

/*
 * bytecode opcodes:
 *  --n     --name      --template
 *  000     nop
 *  001     nat
 *  002     const
 *  003     auto
 *  004     vauto
 *  005     extrn
 *  006     vextrn
 *  007     store
 *  010     jmp
 *  011     ret
 *  012     star
 *  013     vstar
 *  014     call
 *  015     jif
 *  016     pop
 *  017     not         ~
 *  020     lnot        !
 *  021     neg
 *  022     incl
 *  023     incr        ++
 *  024     decl
 *  025     decr        --
 *  026     set         =
 *  027     add         +
 *  030     sub         -
 *  031     shl         <<
 *  032     shr         >>
 *  033     and         &
 *  034     or          |
 *  035     xor         ^
 *  036     mul         *
 *  037     div         /
 *  040     mod         %
 *  041     eq          ==
 *  042     neq         !=
 *  043     leq         <=
 *  044     geq         >=
 *  045     les         <
 *  046     ges         >
 *  047     swt
 *
 * tokens:
 *      NONE=0, SYMBOL=1, CONST=2, STR=3, for operators: value = bytecode
 *      050     [
 *      051     ]
 *      052     (
 *      053     )
 *      054     ,
 *      055     ?
 *      056     :
 *      057     ;
 *      060     {
 *      061     }
 * ctype: bad=0, [alpha_]=1, digit=2, space=3, eof=4, quote=5, else: value = token
 */

short ctype[128] = {
    000, 000, 000, 000, 000, 000, 000, 000, 003, 003, 003, 003, 003, 003, 000, 000,
    000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000,
/*       !    "              %     &   '    (    )    *    +    ,    -         / */
    003, 020, 005, 000, 000, 040, 033, 005, 052, 053, 036, 027, 054, 030, 000, 037,
/*  0-9                                               :    ;    <    =    >    ? */
    002, 002, 002, 002, 002, 002, 002, 002, 002, 002, 056, 057, 045, 026, 046, 055,
/*       A-O                                                                     */
    000, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001,
/*  P-Z                                                    [    eof  ]    ^    _ */
    001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 050, 004, 051, 035, 001,
/*       a-o                                                                     */
    000, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001,
/*  p-z                                                    {    |    }    ~      */
    001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 001, 060, 034, 061, 017, 000 };

short lval; short qc; short buf[5]; short qt = 0;

next() { auto c; return qc ? c = qc, qc = 0, c : ((c = getchar()) == '\n' ? line++, c : c); }
prev(c) { return qc = qc ? error('2c') : c; }
subseq(c, true, false) { return c == prev(next()) ? next(), true : false; }

ctrl(c) {
    if (ctype[c] == 4) error('\'"');            /* eof */
    if (c != '*') return c;                     /* non-ctrl */
    switch (next()) {
        case '0':   return '\0';
        case 'r':   return '\r';
        case 'e':   return '\033';
        case 'n':   return '\n';
        case 't':   return '\t';
        case 'b':   return '\b';
        case '\"':  return '\"';
        case '\'':  return '\'';
        case '*':   return '*';
        default:    error('?*');
    }
}

void
comment() {
    auto c, e;
    e = 0;
    while (ctype[c = next()] != 4) {
        if (e & c == '/') return;
        e = c == '*';
    }
    error('/*');
}

lex() {
    auto c, ct, i;
    i = 0;

    if (qt) return ct = qt, qt = 0, ct;

    while ((ct = ctype[c = next()]) == 3);      /* skip spaces */

    if (c == '/') {                             /* skip comments */
        if ((c = next()) == '*')
            return comment(), lex();
        prev(c);
        c = '/';
    }

    switch (ct) {
        case 0: error('?c');
        case 1:                                 /* symbol */
            while (ct == 1 | ct == 2) {
                if (i == 8) error('2n');
                lchar(buf, i++, c);
                ct = ctype[c = next()];
            }
            lchar(buf, i, 0);
            prev(c);
            lval = lookup(buf);
            return 1;
        case 2:                                 /* number */
            i = (lval = c - '0') ? 10 : 8;
            while (ctype[c = next()] == 2)
                lval = lval * i + c - '0';
            prev(c);
            return 2;
        case 4: return 0;                       /* eof */
        case 5:
            i = datasiz << 1;
            while (ctype[c = next()] != 5)
                lfchar(data, i++, ctrl(c));
            lfchar(data, i++, 0);
            if (c == '\"') return lval = datasiz, datasiz = ++i >> 1, 3;  /* string */
            if (i == 1 + (datasiz << 1)) error('\'\'');
            lval = (fchar(data, datasiz * 2 + 1) << 8) | fchar(data, datasiz * 2);
            return 2;                           /* char */
        case 020: return subseq('=', 042, 020); /* ! or != */
        case 026: return subseq('=', 041, 026); /* = or == */
        case 027: return subseq('+', 023, 027); /* + or ++ */
        case 030: return subseq('-', 025, 030); /* - or -- */
        case 045: case 046:                     /* < or << or <= or > or >> or >= */
            return (subseq(c, 1, 0) ? 031 : subseq('=', 043, 045)) + ct - 045;
        default: return ct;
    }
}

/*
 * expr
 */

/*
 * otype
 *  bits    octal   usage
 *  0-3     000017  prec (for binary only; for prefix/postfix, prec = 0)
 *  9       001000  isvalue
 *  10      002000  isprefix
 *  11      004000  ispostfix
 *  12      010000  isbrace (e.g. '()' '[]' '?:')
 *  13      020000  isbinary
 *  14      040000  isright
 */

short otype[50] = {
/*          symbol  const   str                                                   */
    000000, 001000, 001000, 001000, 000000, 000000, 000000, 000000, 000000, 000000,
/*  *a      *a lval a()                     ~a      !a      -a      ++a     a++   */
    002000, 002000, 002000, 000000, 000000, 002000, 002000, 002000, 002000, 004000,
/*  --a     a--     a = b   a + b   a - b   a << b  a >> b  a & b   a | b   a ^ b */
    002000, 004000, 060012, 020002, 020002, 020003, 020003, 020006, 020010, 020007,
/*  a * b   a / b   a % b   a == b  a != b  a <= b  a >= b  a < b   a > b   &a    */
    020001, 020001, 020001, 020005, 020005, 020004, 020004, 020004, 020004, 002000,
/*  [       ]       (       )       ,       ?       :       ;       {       }     */
    010000, 010000, 010000, 010000, 060013, 070011, 070011, 000000, 000000, 000000 };

short qsize = 50;
short stack[50]; short s; short queue[50]; short q; short values[50];

/* opcodes arguments size */
short stype[40] = { 0, 0, 2, 1, 1, 2, 2, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2 };


/* flush queue to bytecode section */
code1(at, what) { lfchar(bytecode, at, what); }
code2(at, what) { code1(at, what), code1(++at, what >> 8); }

flush() {
    auto i, s;
    i = 0;
    while (++i <= q) {
        code1(pc++, queue[i]);
        if (s = stype[queue[i]]) {
            code1(pc++, values[i]);
            if (s == 2) code1(pc++, values[i] >> 8);
        }
    }
    q = 0;
}

tolval(p) {
    if (p == 003 | p == 005 | p == 012) return ++p;         /* auto, extrn, star */
    error('Le');
}

enq(t) {
    auto p;
    if (t == 047) return queue[q] = tolval(queue[q]);       /* & */
    if (t >= 022 & t <= 025) queue[q] = tolval(queue[q]);   /* ++a a++ --a a-- */
    if (t == 055) {                                         /* end of ternary */
        flush();
        p = stack[s--];                                     /* restore pc */
        code2(p + 1, pc - p - 3);                           /* correct prejump */
        p++;
    }
    else {
        if (++q == qsize) flush();                          /* flush to prevent overflow */
        queue[q] = t;
    }
}

uptok(t) {
    switch (t) {
        case 023: case 025: t--; break;             /* a++/a-- to ++a/--a */
        case 030: t = 021; break;                   /* a-b to -a */
        case 033: t = 047; break;                   /* a&b to &a */
        case 036: t = 012; break;                   /* a*b to *a */
    }
    return t;
}

expr(e, pushargs) {
    auto t, tt, p, st, ss, expect, nargs;
    nargs = stack[++s] = 0;
    expect = 1;
    while ((t = lex()) != e) {
        if (!t) error('!(');
        if (expect) t = uptok(t);
        if (!(tt = otype[t])) error('?e');
        if (tt & 020000) {
            while ((((st = otype[stack[s]]) & 017) <= (tt & 017) & !(st & 040000)) | ((st & 017) < (tt & 017))) {
                if (!(ss = stack[s])) break;                /* bottom of stack, stop */
                s--;                                        /* pop operator */
                enq(ss);
            }
        }
        if (tt & 010000) {                                  /* isbrace */
            if (t == 055) {                                 /* ? : */
                
                flush();
                st = pc;                                    /* save pc */
                enq(015), values[q] = 0;                    /* prejump */
            }
            ss = expr(t + 1, !expect & t == 052);
            if (expect) {
                if (t != 052) error('[?');                  /* t != ( */
                expect = 0;
                continue;
            }
            if (t == 050) enq(027), enq(012);               /* add, star */
            else if (t == 052) enq(014), values[q] = ss;    /* call */
            else {                                          /* ? : */
                flush();
                code2(st + 1, pc - st);                     /* correct prejump */
                st++;
                stack[++s] = pc;                            /* save pc */
                stack[++s] = 055;                           /* ? */
                enq(010), values[q] = 0;                    /* prejump */
                expect = 1;
            }
        }
        else if (tt & 004000) enq(t);                       /* ispostfix */
        else if (tt & 002000) {                             /* isprefix */
            if (!expect) error('-e');
            stack[++s] = t;
        }
        else if (tt & 001000) {                             /* isvalue */
            if (!expect) error('Ne');
            if (t == 1) {                                   /* symbol */
                if ((p = far(symtab, lval + 4)) & 4) {
                    enq(003);                               /* auto */
                    if (p & 16)
                        queue[q]++;                         /* array: implicit auto to vauto */
                }
                else if (p & 2) {
                    enq(005);                               /* extrn */
                    if (p & 8) queue[q]++;                  /* array: implicit extrn to vextrn */
                }
                else {
                    lfar(symtab, lval + 4, 2 | p);          /* set to extrn implicitly */
                    lfar(symtab, lval + 6, datasiz++);
                    enq(005);                               /* extrn */
                }
                lval = far(symtab, lval + 5 + !(p & 4));    /* lval+5 => auto value, lval+6 => extrn value */
            }
            else if (t == 2) enq(002);                      /* const */
            else enq(006);                                  /* string */
            values[q] = lval;
            expect = 0;
        }
        else {                                              /* isbinary */
            if (expect) error('ee');
            expect = 1;
            if (t == 026) queue[q] = tolval(queue[q]);      /* = */
            if (t == 054) {                                 /* , */
                nargs++;
                if (!pushargs) enq(016);                    /* pop */
            }
            else stack[++s] = t;
        }
    }
    while (ss = stack[s--]) enq(ss);
    return expect ? 0 : ++nargs;
}

/*
 * parse statements
 */

/*
 * swtab: (value ptr) ... default_ptr
 */
short swtab[140]; short swtcnt; short def;
short breaks[140]; short nbrk;
short lastret = 0; /* ret optimization */

enum(e) {
    auto t;
    t = lex();
    if (t == 054) return 0;     /* comma */
    if (t == ctype[e]) return 1;
    error(',' << 8 | e);
}

arg(adj) {
    auto k;
    lfar(symtab, lval + 4, far(symtab, lval + 4) | 4);
    lfar(symtab, lval + 5, far(symtab, lastauto + 5) + adj);
    lfar(symtab, lval + 7, lastauto);
    lastauto = lval;
}

flushbrk() {
    while (nbrk--)
        code2(breaks[nbrk], pc - breaks[nbrk] - 2);
    nbrk = 0;
}

parse(scope) {
    auto t, i, j, k;
    flush();
    t = lex();
    i = j = 0;
    if (t == 057) return 1;                                 /* ; */
    if (t == 060) {                                         /* { */
        while (parse(scope));
        return 1;
    }
    if (t == 061) return 0;                                 /* } */
    if (t != 1 | !(far(symtab, lval + 4) & 1))              /* not keyword */
        return lastret = 0, qt = t, expr(057, 0), enq(016), 1;
    lastret = far(symtab, lval + 6) == 8;
    switch (far(symtab, lval + 6)) {
        case 0:                                             /* asm */
            while (1) {
                t = lex();
                if (t != 2) error('0p');
                code1(pc++, lval);
                if (enum(';')) break;                       /* break if semi */
            }
            return 1;
        case 1:                                             /* auto */
            while (1) {
                t = lex();
                j = lval;
                k = 1;
                if (t != 1) error('ap');
                if ((t = lex()) == 050) {                   /* [ */
                    lfar(symtab, lval + 4, far(symtab, lval + 4) | 20);
                    if (lex() != 2) error('0d');
                    k = lval;
                    if (lex() != 051) error('au');
                }
                else qt = t;
                lval = j;
                arg(-k);
                i = i + k;
                if (enum(';')) break;                       /* break if semi */
            }
            enq(007); values[q] = i;                        /* store */
            return parse(scope);
        case 2:                                             /* break */
            if (!scope | lex() != 057) error('br');
            enq(010);                                       /* jmp */
            flush();
            breaks[nbrk++] = pc - 2;
            return 1;
        case 3:                                             /* case */
            if (lex() != 002) error('cs');
            swtab[swtcnt++] = lval;
            if (lex() != 056) error('cs');
            swtab[swtcnt++] = pc;
            return parse(scope);
        case 4:                                             /* continue */
            if (!scope | lex() != 057) error('co');
            enq(010); values[q] = scope - pc - 3;           /* jmp to begin */
            return 1;
        case 5:                                             /* default */
            def = pc;
            if (lex() != 056) error('cs');
            return parse(scope);
        case 7:                                             /* if */
            if (lex() != 052) error('if');
            expr(053);
            enq(015);                                       /* prejump */
            flush();
            i = pc;
            parse(scope);
            flush();
            t = lex();
            if (t != 1)
                return qt = t, code2(i - 2, pc - i), 1;     /* not else */
            if (!(far(symtab, lval + 4) & 1) | far(symtab, lval + 6) != 6)
                return qt = t, code2(i - 2, pc - i), 1;     /* not else */
            code2(i - 2, pc - i + 3);
            enq(010);                                       /* prejump */
            flush();
            i = pc;
            parse(scope);
            flush();
            code2(i - 2, pc - i);
            return 1;
        case 8:                                             /* return */
            t = lex();
            if (t != 057)                                   /* return expr ; */
                return qt = t, expr(057, 0), enq(011), 1;
            return enq(003), values[q] = 0, enq(011), 1;    /* return; */
        case 9:                                             /* switch */
            if (lex() != 052) error('sw');
            nbrk = 0;
            scope = pc;
            swtcnt = 0;
            expr(053);
            flush();
            i = pc;
            enq(006);
            flush();
            code1(pc++, 047);                               /* swt */
            pc = pc + 2;
            values[q] = 0;
            def = 0;
            parse(scope);
            flush();
            code2(i + 4, swtcnt / 2);                       /* nr case */
            if (!def) def = pc;
            swtab[swtcnt++] = def;
            code2(i + 1, datasiz);                          /* vextrn swtab */
            while (j < swtcnt)
                lfar(data, datasiz++, swtab[j++]);          /* put swtab to .data */
            flush();
            flushbrk();
            return 1;
        case 10:                                            /* while */
            if (lex() != 052) error('wh');
            nbrk = 0;
            scope = pc;
            expr(053);
            enq(015);                                       /* prejump */
            flush();
            i = pc;
            parse(scope);
            flush();
            enq(010); values[q] = scope - pc - 3;           /* jmp to begin */
            flush();
            code2(i - 2, pc - i);
            flush();
            flushbrk();
            return 1;
    }
}

/*
 * declaration
 *      name [ '[' size ']' ] [ '=' num [ ',' num ] ] ';'
 *      name '(' [ name [ ',' name ] ')' statement
 *      (eof)
 */

decl() {
    auto t, name, n, dst, flags, i;
    n = 1;
    i = 0;
    if (!(t = lex())) return 0;
    if (t != 1) error('nd');
    name = lval;
    flags = far(symtab, name + 4);
    dst = far(symtab, name + 6);                            /* location in data */
    if (!(flags & 2)) {                                     /* mark extrn explicitly */
        lfar(symtab, name + 4, 2 | flags);
        lfar(symtab, name + 6, datasiz);
        dst = datasiz;
        datasiz = datasiz + 1;                              /* update datasiz */
    }
    if ((t = lex()) == 052) {                               /* function */
        lfar(data, dst, pc);
        while (1) {                                         /* read args */
            t = lex();
            if (t == 053) break;
            if (t != 1) error('ap');
            arg(1);
            i++;
            if (enum(')')) break;                           /* break if ')' */
        }
        lval = lookup(".");
        arg(-i - 1);
        parse(0);
        flush();
        if (!lastret) enq(003), values[q] = 000, enq(011);  /* ret */
        flush();
        while (lastauto) {                                  /* remove local variabled */
            lfar(symtab, lastauto + 4, far(symtab, lastauto + 4) & 11);
            lastauto = far(symtab, lastauto + 7);
        }
        return 1;
    }
    if (t == 050) {                                         /* array */
        if (lex() != 2) error('0d');
        n = lval;
        if (lex() != 051) error(']d');
        lfar(symtab, name + 4, far(symtab, name + 4) | 8);
        if (dst + 1 != datasiz) error('[d');                /* array was declared implicitly? */
        datasiz = datasiz + n - 1;
        t = lex();
    }
    if (t == 026) {                                         /* = */
        while (1) {
            if (!n--) error('2d');
            t = lex();
            if (t == 2);
            else if (t == 1) {
                if (!((i = far(symtab, lval + 4)) & 2)) {
                    lfar(symtab, lval + 4, 2 | i);          /* mark extrn implicitly */
                    lfar(symtab, lval + 6, dst);
                }
                lval = data[far(symtab, lval + 6)];
            }
            else error('0d');
            lfar(data, dst++, lval);
            if (enum(';')) break;                           /* break if semi */
        }
    }
    else if (t != 057) error(';d');
    return 1;
}

void* alloc();
/*
 * main
 */

main() {
    symtab = alloc();
    bytecode = alloc();
    data = alloc();
    int t;
    //tests();
    clearsym();
    pc = 8;
    while (decl());

    pc = pc + pc % 2;
    code1(0, 0220);
    code1(1, 0351);
    code2(2, pc + (datasiz << 1) - 4);
    code2(4, pc);
    code2(6, far(data, far(symtab, lookup("main\0") + 6)));
    write(1, bytecode, pc);
    write(1, data, datasiz << 1);
    quit();
}





/*
 * stdlib
 */

char(s, n) short* s; { return (s[n >> 1] >> ((n & 1) << 3)) & 0377; }

lchar(s, n, c) short* s; {
    auto i;
    i = (n & 1) << 3;
    s[n >> 1] = s[n >> 1] & ~(0377 << i) | ((c & 0377) << i);
    return c;
}














void*
alloc() { return calloc(1, 0x10000); }

#define b_nop       000
#define b_nat       001
#define b_const     002
#define b_auto      003
#define b_vauto     004
#define b_extrn     005
#define b_vextrn    006
#define b_store     007
#define b_jmp       010
#define b_ret       011
#define b_star      012
#define b_vstar     013
#define b_call      014
#define b_jif       015
#define b_pop       016
#define b_not       017
#define b_lnot      020
#define b_neg       021
#define b_incl      022
#define b_incr      023
#define b_decl      024
#define b_decr      025
#define b_set       026
#define b_add       027
#define b_sub       030
#define b_shl       031
#define b_shr       032
#define b_and       033
#define b_or        034
#define b_xor       035
#define b_mul       036
#define b_div       037
#define b_mod       040
#define b_eq        041
#define b_neq       042
#define b_leq       043
#define b_geq       044
#define b_les       045
#define b_ges       046
#define b_swt       047
#define b_qo        050
#define b_qc        051
#define b_co        052
#define b_cc        053
#define b_comma     054
#define b_question  055
#define b_ddot      056
#define b_semi      057
#define b_no        060
#define b_nc        061

#define with_in(s) ({ \
    int8_t buf[10000] = s; \
    stdin = fmemopen(buf, sizeof(buf), stdin == stdin ? "rt" : "wt"); \
})

#define test_expr(...) ({ \
    size_t pp[] = { __VA_ARGS__ }, * p = pp - 1; \
    short* x = queue; \
    while (*++p) { \
        assert(*p == *++x); \
        if (*p == b_const || *p == b_call) assert(*++p == values[x - queue]); \
        else if (*p == b_extrn || *p == b_vextrn) assert((symtab + lookup(*++p))[6] == values[x - queue]); \
    } \
})

#define short_cmp(nr, to, ...) ({ \
    short pp[] = { __VA_ARGS__ }, * p = pp, *t = to; \
    while (nr--) assert(*p++ == *t++); \
})

clearsym() {
    memset(symtab, 0, (unsigned)symtabs * 8 * 2);
    lfar(symtab, 4, 4);                                     /* first entry is idle auto */
    lfar(symtab, 5, 1);
    init("asm\0", 0);
    init("auto\0", 1);
    init("break", 2);
    init("case\0", 3);
    init("continue\0", 4);
    init("default\0", 5);
    init("else\0", 6);
    init("if\0", 7);
    init("return\0", 8);
    init("switch\0", 9);
    init("while\0", 10);
}

tests() {
    FILE* bak = stdin;
    fprintf(stderr, "#1 stdlib...\n");
    int8_t test1[] = "01234";
    for (int i = 0; i < 6; i++) assert(char(test1, i) == test1[i]);
    for (int i = 0; i < 6; i++) assert(lchar(test1, i, i + '0') == i + '0');
    for (int i = 0; i < 6; i++) assert(char(test1, i) == test1[i]);

    fprintf(stderr, "#2 symtab...\n");
    short* tabs[4096];
    assert(!strncmp((int8_t*)(symtab + lookup("hello")), "hello", 8));
    for (int i = 0; i < 4096; i++)
        if ((i & 255) && (i & 255 << 8))
            (tabs[i] = symtab + lookup(&i))[4] = 1, tabs[i][5] = i;
    for (int i = 0; i < 4096; i++)
        if ((i & 255) && (i & 255 << 8))
            assert(!strncmp(tabs[i], &i, 8) && tabs[i][5] == i);
    clearsym();
    datasiz = 0;

    assert((symtab + lookup("asm"))[4] == 1 && (symtab + lookup("asm"))[6] == 0);
    assert((symtab + lookup("auto\0"))[4] == 1 && (symtab + lookup("auto\0"))[6] == 1);
    assert((symtab + lookup("break"))[4] == 1 && (symtab + lookup("break"))[6] == 2);
    assert((symtab + lookup("case\0"))[4] == 1 && (symtab + lookup("case\0"))[6] == 3);
    assert((symtab + lookup("continue\0"))[4] == 1 && (symtab + lookup("continue\0"))[6] == 4);
    assert((symtab + lookup("default"))[4] == 1 && (symtab + lookup("default"))[6] == 5);
    assert((symtab + lookup("else\0"))[4] == 1 && (symtab + lookup("else\0"))[6] == 6);
    assert((symtab + lookup("if\0"))[4] == 1 && (symtab + lookup("if\0"))[6] == 7);
    assert((symtab + lookup("return\0"))[4] == 1 && (symtab + lookup("return\0"))[6] == 8);
    assert((symtab + lookup("switch\0"))[4] == 1 && (symtab + lookup("switch\0"))[6] == 9);
    assert((symtab + lookup("while"))[4] == 1 && (symtab + lookup("while"))[6] == 10);

    fprintf(stderr, "#3 lexer...\n");
    with_in("abc/*asdasjd???\n\t*/~!++--=+123-<<>>&|^*/%'12'==!=<=>=<>[](),:?;{}\\");
    assert(lex() == 1 && lookup("abc") == lval);
    assert(lex() == b_not);
    assert(lex() == b_lnot);
    assert(lex() == b_incr);
    assert(lex() == b_decr);
    assert(lex() == b_set);
    assert(lex() == b_add);
    assert(lex() == 2 && lval == 123);
    assert(lex() == b_sub);
    assert(lex() == b_shl);
    assert(lex() == b_shr);
    assert(lex() == b_and);
    assert(lex() == b_or);
    assert(lex() == b_xor);
    assert(lex() == b_mul);
    assert(lex() == b_div);
    assert(lex() == b_mod);
    assert(lex() == 2 && lval == '21');
    assert(lex() == b_eq);
    assert(lex() == b_neq);
    assert(lex() == b_leq);
    assert(lex() == b_geq);
    assert(lex() == b_les);
    assert(lex() == b_ges);
    assert(lex() == b_qo);
    assert(lex() == b_qc);
    assert(lex() == b_co);
    assert(lex() == b_cc);
    assert(lex() == b_comma);
    assert(lex() == b_ddot);
    assert(lex() == b_question);
    assert(lex() == b_semi);
    assert(lex() == b_no);
    assert(lex() == b_nc);
    assert(lex() == 0);

    fprintf(stderr, "#4 expr...\n");
    with_in("y=(1+2*5)/4+ ++x*&x>>9 | 1 & (*&7[3] = 1), 3(1, a() + x[1,2]);");
    s = q = 0;
    expr(b_semi, 0);
    test_expr(
        b_vextrn,   "y",
        b_const,    1,
        b_const,    2,
        b_const,    5,
        b_mul,
        b_add,
        b_const,    4,
        b_div,
        b_vextrn,   "x",
        b_incl,
        b_vextrn,   "x",
        b_mul,
        b_add,
        b_const,    9,
        b_shr,
        b_const,    1,
        b_const,    7,
        b_const,    3,
        b_add,
        b_vstar,
        b_vstar,
        b_const,    1,
        b_set,
        b_and,
        b_or,
        b_set,
        b_pop,
        b_const,    3,
        b_const,    1,
        b_extrn,    "a",
        b_call,     0,
        b_extrn,    "x",
        b_const,    1,
        b_pop,
        b_const,    2,
        b_add,
        b_star,
        b_add,
        b_call,     2,
        0
    );
    flush();
    pc = 0;
    with_in("1 ? 2 : 3, 2;");
    expr(b_semi, 0);
    flush();
    assert(!memcmp(bytecode, "\002\001\000\015\006\000\002\002\000\010\003\000\002\003\000\016\002\002\000", pc));
    
    fprintf(stderr, "#5 statement...\n");
    pc = 0;
    arg(-1);
    datasiz = 0;
    clearsym();
    with_in("{ auto i, j; asm 1, 2, 3; y + i >> z; if (1) 1; if (1) 1; else 2; return 7; return; while (1) continue; }");
    assert(parse(0));
    // for (int i = 0; i < pc; i++)
    //     fprintf(stderr, "%02o ", char(bytecode, i));
    assert(!memcmp(bytecode,
    /*    store 2; asm 1 2 3;  y/x         i/a     +   z/x         >> ; */
        "\007\002\001\002\003\005\000\000\003\377\027\005\001\000\032\016"
    /*   1            jif +4      1           ; */
        "\002\001\000\015\004\000\002\001\000\016"
    /*   1            jif +7      1           jmp +4          2; */
        "\002\001\000\015\007\000\002\001\000\016\010\004\000\002\002\000\016"
    /*  7             ret */
        "\002\007\000\011"
    /*  auto +0   ret */
        "\003\000\011"
    /*  1             jif +6      jmp -9        jmp -12 */
        "\002\001\000\015\006\000\010\367\377\010\364\377"
        , pc)
    );

    pc = datasiz = 0;
    clearsym();
    fprintf(stderr, "#6 declaration...\n");
    with_in("i[3] = 1, 2; z =2; x; q[5]=1,2,3,4,5; a[1]; func() auto n; return 0;\\");
    while (decl());
    short_cmp(datasiz, data, 1, 2, 0, 2, 0, 1, 2, 3, 4, 5, 0, 0);

    pc = datasiz = 0;
    clearsym();
    stdin = bak;
}
