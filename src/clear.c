/* clear screen */

main() {
    extern int write();
    write(1, "\e0x0y2000 0x0y;", 15);
}
