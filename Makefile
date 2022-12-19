tools 	= tools/boot tools/bc tools/mkfs
tsource	= src/lite src/b-run src/shell src/bc src/edit2 src/ls src/cat src/hexdump src/clear src/test src/edit src/sizeof src/as src/as2 src/a src/cmp src/ed
source  = $(tsource) src/lib.b src/calc.b src/a.s src/as-src/as11.s src/as-src/as12.s src/1.txt src/lite.b src/ed-src/ed3.s
CFLAGS	= -Wno-implicit-int -Wno-implicit-function-declaration -Wno-multichar -Wno-incompatible-pointer-types -Wno-int-conversion -fsanitize=undefined,address

%.bo: %.b
	cat $< src/lib.b | tools/bc > $@

%: %.bo
	cat $< src/b-run > $@

%: %.b.asm
	python3.10 tools/tmp/basm.py $< > $<.nasm
	nasm -f bin -w-zeroing -o $@ $<.nasm
	rm $<.nasm
	cat src/b-run >> $@

%: %.asm
	nasm -f bin -w-zeroing -o $@ $<

%.o: %.s
	as1 <$< >$@

%: %.s
	as1 <$< >$@.so
	as2 $@.so >$@
	rm $@.so

src/syscall.asm: src/lite.asm
	cat $< > $@

src/lite: src/lite.bo src/syscall
	cat $^ > $@

src/a: src/a.o
	as2 $< >$@

src/as: src/as-src/as11.o src/as-src/as12.o src/as-src/as13.o src/as-src/as14.o src/as-src/as15.o src/as-src/as16.o src/as-src/as17.o src/as-src/as19.o
	as2 $^ >$@

src/as2: src/as-src/as21.o src/as-src/as22.o src/as-src/as29.o
	as2 $^ >$@

src/ed: src/ed-src/ed1.o src/ed-src/ed2.o src/ed-src/ed3.o src/ed-src/ed4.o src/ed-src/edx.o
	as2 $^ >$@

image: $(tools) $(source)
	tools/mkfs 1M $(source) > image1
	cat tools/boot image1 > image
	rm image1

.PHONY: run
run: image
	qemu-system-x86_64 -display gtk,gl=on,grab-on-hover=off,zoom-to-fit=on --full-screen image
# -display gtk,gl=on,grab-on-hover=off,zoom-to-fit=on --full-screen

.PHONY: clean
clean:
	rm -f $(tools) $(tsource) src/syscall src/syscall.asm src/*.bo src/*.o src/as-src/*.o src/ed-src/*.o
