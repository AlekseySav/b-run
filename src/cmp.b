b1[64]; s1; f1;
b2[64]; s2; f2;

r;

main() {
    auto i;
    f1 = open("a", 0);
    f2 = open("1", 0);
    
    while (1) {
        s1 = read(f1, b1, 128);
        s2 = read(f2, b2, 128);
        if (s1 != s2) no(0);
        i = 0;
        while (i != s1)
            if (char(b1, i) != char(b2, i++))
                no(i);
        r = r + s1;
        if (s1 < 128) break;
    }

    printf("ok.*n");
    close(f1);
    close(f2);
    exit();
}

no(i) {
    printf("no. (%d)*n", r + i);
    close(f1);
    close(f2);
    exit();
}
