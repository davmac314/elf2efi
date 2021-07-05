# Simple EFI application example

This is a very simple example EFI application built using elf2efi.

It's taken from: https://github.com/utshina/uefi-simple 
Written by: utshina (Takahiro Shinagawa).

See LICENSE file in this directory for license information.

The original example in the repository linked above builds using mingw64-gcc
(i.e. a cross-compilation toolchain). It has been modified to build with the
native gcc and elf2efi.

The resulting binary is helloworld.efi.

Note: The makefile assumes you are building an application for x86-64.

## Running in QEMU

To test the applicatio in QEMU, you can use `make run-in-qemu`, but you will
first need to copy the OVMF ("open virtual machine firmware") firmware files
into this directory. The files are:

 * OVMF_CODE-pure-efi.fd
 * OVMF_VARS-pure-efi.fd

See this OVMF page for information on how to build, or how to find builds,
of these files: https://github.com/tianocore/tianocore.github.io/wiki/OVMF

(Currently RPM builds can be found here:
https://www.kraxel.org/repos/jenkins/edk2/ - if not using an RPM-based system
you will need to find a way to extract the contents. For x86-64 you want the
edk2.git-ovmf-x64-* file).

Once QEMU runs it will start the OVMF shell. You can then run the
application by typing:

```
Shell> fs0: 
```

followed by:

```
FS0:\> helloworld.efi
```

You should see the "Hello world!" message printed before control returns to
the shell.
