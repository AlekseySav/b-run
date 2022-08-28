tools 	= tools/boot tools/bc tools/mkfs
tsource	= src/lite src/b-run src/shell src/bc src/ls src/cat src/hexdump src/clear src/test src/edit
source  = $(tsource) src/lib.b src/calc.b
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

src/syscall.asm: src/lite.asm
	cat $< > $@

src/lite: src/lite.bo src/syscall
	cat $^ > $@

image: $(tools) $(source)
	tools/mkfs 1M $(source) > image1
	cat tools/boot image1 > image
	rm image1

.PHONY: run
run: image
	qemu-system-x86_64 -display gtk,gl=on,grab-on-hover=off,zoom-to-fit=on --full-screen image

.PHONY: clean
clean:
	rm -f $(tools) $(tsource) src/syscall src/syscall.asm src/*.bo
