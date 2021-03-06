#gcc -c -g -Os -march=i686 -ffreestanding -Wall -Werror -I. -o vbr.o vbr.c
#ld -static -Tlinker.ld -nostdlib --nmagic -o vbr.elf vbr.o
#objcopy -O binary vbr.elf vbr.bin
#CFLAGS = -fno-stack-protector -std=c99 -Os -march=i686 -ffreestanding -Wall
CFLAGS = -m32  -g -Wall -Wextra -Werror -nostdlib -fno-builtin -nostartfiles -nodefaultlibs -fno-exceptions -fno-rtti -fno-stack-protector
#CB_CFLAGS = -fno-stack-protector -std=c99 -march=i686 -ffreestanding -Wall
CB_CFLAGS = -fno-stack-protector -std=c99 -m32 -ffreestanding -Wall -g
CB_LDFLAGS = -m elf_i386
CC=gcc

CPPFLAGS = -m32  -g -Wall -Wextra -Werror -nostdlib -fno-builtin -nostartfiles -nodefaultlibs -fno-exceptions -fno-rtti -fno-stack-protector

simple_proc_signal.com: simple_proc_signal.elf
	objcopy -R .pdr -R .comment -R.note -S -O binary $< $@
simple_proc_signal.elf: simple_proc_signal.o
	ld -m elf_i386 -static -Tas.ld -nostdlib --nmagic -o $@ $<
simple_proc_signal.o: simple_proc_signal.S
	$(CC) $(CFLAGS) -c $<

process.com: process.elf
	objcopy -R .pdr -R .comment -R.note -S -O binary $< $@
process.elf: process.o
	ld -m elf_i386 -static -Tas.ld -nostdlib --nmagic -o $@ $<
process.o: process.S
	$(CC) $(CFLAGS) -c $<

simple_proc.com: simple_proc.elf
	objcopy -R .pdr -R .comment -R.note -S -O binary $< $@
simple_proc.elf: simple_proc.o
	ld -m elf_i386 -static -Tas.ld -nostdlib --nmagic -o $@ $<
simple_proc.o: simple_proc.S
	$(CC) $(CFLAGS) -c $<
clean:
	rm -rf *.o *.com *.elf
