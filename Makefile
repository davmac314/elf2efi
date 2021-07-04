CC=gcc
CFLAGS=-Os

all: elf2efi32 elf2efi64

elf2efi32: src/elf2efi.c
	$(CC) $(CFLAGS) -Isrc/include -DEFI_TARGET32 src/elf2efi.c -o elf2efi32

elf2efi64: src/elf2efi.c
	$(CC) $(CFLAGS) -Isrc/include -DEFI_TARGET64 src/elf2efi.c -o elf2efi64

clean:
	rm -f elf2efi32 elf2efi64
