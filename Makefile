name=rogue
all: rogue

libwrappers.a : wrappers.c
	gcc -c wrappers.c -o wrappers.o
	ar rcs libwrappers.a wrappers.o
	rm wrappers.o

rogue: rogue.asm libwrappers.a
	nasm -f elf64 -F dwarf -g rogue.asm
	gcc -m64 -no-pie -o rogue rogue.o -lc ./lib/libraylib.a -L./ -lwrappers -lGL -lm -lpthread -ldl -lrt -lX11

test-c: sizeof.c
	gcc -m64 -no-pie -o test-c sizeof.c -lc ./lib/libraylib.a -lGL -lm -lpthread -ldl -lrt -lX11