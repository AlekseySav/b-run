/*
 * * / + - = $ reg=1 num=2
 * written with src/edit and copy-pasted here from 'image'
 */

prec[128];
stack[40]; s; queue[40]; q;
c; t; lv;
regs[30];

main() {
        s = stack, q = queue;
        prec['**'] = prec['/'] = 1;
        prec['+'] = prec['-'] = 2;
        prec['='] = prec['$'] = 3;
        prec['*n'] = prec[' '] = 4;
        prec[127] = 100;
        *s = *q = 127;
        while (lex()) eval();                         
        exit();
}

lex() {          
        if (!c) if ((c = getchar()) == -1) return 0;
        if (prec[c]) return t = c, c = 0, t;
        if ('a' <= c & c <= 'z') return lv = c - 'a', c = 0, t = 1;
        lv = 0;
        while ('0' <= c & c <= '9') 
                lv = lv * 10 + c - '0', c = getchar();
        return t = 2;
}
eval() {
        if (!prec[t]) *++q = lv;
        while (prec[*s] <= prec[t])
                run(*s--);
        if (prec[t] < 4) *++s = t;
}

run(t) {
        auto a, b;

        if (!prec[t]) return *++q = t;
        a = pop();
        if (t == '=') {
                *q--;
                regs[*q--] = a;
                return;
        }
        if (t != '$') b = pop();
        switch (t) {                    
                case '**': b = b * a; break; 
                case '/': b = b / a; break;
                case '+': b = b + a; break;
                case '-': b = b - a; break;
                case '$': printf("%d*n", a); break;
        }
        *++q = b, *++q = 2;
}


pop() {
        if (*q-- == 1) return regs[*q--];
        return *q--;
}

\
