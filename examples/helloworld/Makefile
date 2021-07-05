helloworld.efi: main.o
	ld -s -q -Bsymbolic -Bsymbolic-functions -T link-elf-efi.lds \
	  -o helloworld.efi.so \
	  main.o
	../../elf2efi64 --subsystem=10 helloworld.efi.so helloworld.efi

main.o: main.c
	gcc -ffreestanding -fshort-wchar -mabi=ms -maccumulate-outgoing-args -march=x86-64 -fno-stack-protector -c main.c

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

run-in-qemu: image-dir
	@if [ ! -e OVMF_CODE-pure-efi.fd -o ! -e OVMF_VARS-pure-efi.fd ]; then \
	    echo "!!! OVMF firmware images are missing; please download them to this directory."; \
	    exit 1; \
	fi
	qemu-system-x86_64 \
	  -drive if=pflash,format=raw,unit=0,file=OVMF_CODE-pure-efi.fd,readonly=on \
	  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS-pure-efi.fd \
	  -net none  \
	  -drive file=fat:rw:image,media=disk,format=raw

clean:
	rm -f main.o helloworld.efi.so helloworld.efi disk.img
	rm -rf image
