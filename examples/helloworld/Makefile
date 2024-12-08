# OVMF firmware location. See the README. There are two files: code and "vars", which is used as
# a template for the "OVMF-VARS.fd" file which will be used to emulate non-volatile storage.
# The files should be distributed with QEMU, but some distributions may not do so.
QEMU_FW_BASEDIR = /usr/share/qemu
OVMF_CODE_FILE := $(QEMU_FW_BASEDIR)/edk2-x86_64-code.fd
OVMF_VARS_FILE := $(QEMU_FW_BASEDIR)/edk2-i386-vars.fd


# link to ELF, then convert to PE using elf2efi:
helloworld.efi: main.o
	ld -s -q -Bsymbolic -Bsymbolic-functions -T link-elf-efi.lds \
	  -o helloworld.efi.so \
	  main.o
	../../elf2efi64 --subsystem=10 helloworld.efi.so helloworld.efi

# Alernative: link directly to PE.
#helloworld.efi: main.o
#	ld -s -T link-elf-efi.lds \
#	  -mi386pep --oformat pei-x86-64 --subsystem 10 --image-base 0 \
#	  --enable-reloc-section \
#	  -o helloworld.efi \
#	  main.o

# For either alternative above, compile to ELF object:
main.o: main.c
	gcc -ffreestanding -fshort-wchar -mabi=ms -maccumulate-outgoing-args -march=x86-64 -mno-red-zone -fno-stack-protector -fpie -c main.c


# Alternative: target UEFI directly using LLVM/clang. In this case, compile to COFF object format.
#helloworld.efi: main.o
#	clang -target x86_64-unknown-windows -nostdlib -fuse-ld=lld-link -Wl,-subsystem:efi_application -Wl,-entry:EfiMain -o helloworld.efi main.o
#
#main.o: main.c
#	clang -target x86_64-unknown-windows -ffreestanding -march=x86-64 -fno-stack-protector -mno-sse -mcmodel=large -c main.c


# Everything below here is concerned with building disk images and running in QEMU

disk.img: helloworld.efi
	rm disk.img
	echo "Please create disk image (disk.img). On linux use 'make disk.img-linux'"

# Create "image", a directory used to create a virtual FAT image
image-dir: helloworld.efi
	mkdir -p image
	cp helloworld.efi image

# Create a disk image with the helloworld.efi executable on it (Linux).
# requires mtools and dosfstools. This is an example as alternative to the above
# if you want a "real" disk image.
disk.img-linux: helloworld.efi
	dd if=/dev/zero of=disk.img bs=512 count=93750 # 48Mb
	/sbin/sfdisk disk.img < sfdisk.input # create partition table ("label") and EFI system partition
	# start=2048 end=93716 sectors=91669
	/usr/sbin/mkfs.fat -F 32 --offset=2048 -S 512 disk.img $$((91669 * 512 / 1024))
	mcopy -i disk.img@@1M helloworld.efi ::/

OVMF-VARS.fd:
	cp $(OVMF_VARS_FILE) OVMF-VARS.fd

run-in-qemu: OVMF-VARS.fd image-dir
	@if [ ! -e $(OVMF_CODE_FILE) ]; then \
	    echo "!!! OVMF firmware images are missing; see README."; \
	    exit 1; \
	fi
	qemu-system-x86_64 \
	  -drive if=pflash,format=raw,unit=0,file=$(OVMF_CODE_FILE),readonly=on \
	  -drive if=pflash,format=raw,unit=1,file=OVMF-VARS.fd \
	  -net none  \
	  -drive file=fat:rw:image,media=disk,format=raw

clean:
	rm -f main.o helloworld.efi.so helloworld.efi disk.img
	rm -rf image
