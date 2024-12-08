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

To test the application in QEMU, you will need to have OVMF ("open virtual
machine firmware") firmware files available.

These are normally distributed with QEMU, or some distributions as part of the
"ovmf" package. Check the Makefile and change `QEMU_FW_BASEDIR` (or
`OVMF_CODE_FILE` and `OVMF_VARS_FILE`) if necessary. In case your
distribution does not include them, you can get suitable pre-built files here:

https://retrage.github.io/edk2-nightly/

(eg `RELEASEX64_OVMF_CODE.fd` and `RELEASEX64_OVMF_DATA.fd`). Note that this
is an external link with a separate maintainer, we are not responsible for
them and cannot make guarantees of their integrity or suitability. If you
prefer, you can build the files yourself; they are part of EDK2:

https://github.com/tianocore/edk2

(Build instructions are outside the scope of this document).

Once the firmware files are in place, you can use `make run-in-qemu` to run.

When QEMU runs it will start the OVMF shell. You can then run the application
by typing:

```
Shell> fs0: 
```

followed by:

```
FS0:\> helloworld.efi
```

You should see the "Hello world!" message printed before control returns to
the shell.
