# elf2efi

This is the "elf2efi" utility, separated from the iPXE package
(https://github.com/ipxe/ipxe / https://ipxe.org/). It may originally
come from Syslinux (https://wiki.syslinux.org).

The utility is of such general use that I figured it'd be worth separating out.

It converts an ELF-format executable/DLL to a "PE+"-format file, suitable for
use as an EFI application (or driver). This makes it easier to build EFI
executables on systems which primarily use the ELF format, and without
resorting to the relocation hacks that eg GNU-EFI use.

Of course the ELF file must have been correctly compiled and constructed to
be used as an EFI application. You cannot convert an arbitrary executable
into the PE+ format and expect it to work as an EFI application.

This is version 1.0, from commit 2690f730961e335875cac5fd9cf870a94eaef11a
of the iPXE repository.

The source file for elf2efi is credited to Michael Brown
(mbrown@fensystems.co.uk). This package was created by Davin McCall
(davmac@davmac.org).

## Build and run

This repo is in a pretty rough-and-ready state. To build just run "make".
This will produce two binaries, "elf2efi32" and "elf2efi64", to be used for
32- and 64- bit ELF files respectively. Run eg `elf2efi32 --help` for help
on running the utility. Typically you want something like:

```
elf2efi64 --subsystem=10 input.efi.so output.efi
```

(`--subsystem=10` specifies an EFI application).

The build has been tested on Linux and has no dependencies. 

## Why not just use objcopy?

POSIX-UEFI (see links) and possibly GNU EFI use the "objcopy" utility (from
GNU binutils) to convert ELF format files to PE+. However:

 * This requires binutils has been built with the appropriate support.
 * The EFI loads applications at any arbitrary address; it requires they be
   relocatable.
 * objcopy doesn't preserve relocations in executable images when copying
   from ELF to PE+. This means that the code must be position-independent,
   or must contain a stub which performs the ELF relocations (which are in
   sections that must be copied to the output).
 * objcopy seems to use the presence of a ".reloc" section to decide whether
   to mark the output with `IMAGE_FILE_RELOCS_STRIPPED`. But, it won't
   generate such a section itself, even if the input does have relocations.
   Therefore, unless the input file has a section with this name (and it is
   copied to the output file), the output is marked as having relocations
   stripped, and an EFI environment may refuse to run it. Note that if such
   a section is present, it must already (within the ELF input...) be in the
   correct format of a PE+ relocation table.

If binutils supports the PE+ format, though, why not link directly to that
and skip the problematic objcopy step?

First, you can't use `ld -q` to link an executable ELF with relocations
retained, and then another `ld` stage to convert to PE+, because:

```
ld: relocatable linking with relocations from format elf64-x86-64 (helloworld.o) to format pei-x86-64 (helloworld.efi) is not supported
```

That perhaps makes sense; we are still trying to use an executable object as
an input object.

We could try to skip the intermediate object altogether: use `ld` (without
`-q`) to produce PE+ format directly, i.e. just add `--oformat pei-x86-64`
to the link. Unfortunately, this does not appear to set certain fields in the
PE+ headers correctly (eg size and address of .text, .data and .bss sections
get reported as 0). Also, it is not possible to set the subsystem to the
correct value (10, for EFI application) unless linker emulation is enabled,
i.e.:

```
ld -m i386pep --oformat pei-x86-64 --subsystem 10 ...
```

This (somewhat) works! We can even use `--enable-reloc-section` to cause
relocations to be generated, meaing that, in theory, we do not have to
compile the code with `-fpie` (but more on this shortly).

The `i386pep` emulation seems to prevent ld from recognizing elf objects in
archives (they are ignored). For example, linking against some library
"libmylib.a" with `-lmylib` will simply not work. You can still a link a bunch
of objects by specifying their names immediately, or you can first link
(against the archive) to a relocatable ELF file using `ld -r`, and then use the
result as a singular input to a final stage link (to PE+ format), using
`-m i386pep` as above.

Despite apparent success of the link, source objects may need to be compiled
with `-fpie`, or otherwise the resulting binary may be refused by the EFI
system (as "Unsupported", possibly due to some unsupported relocation type
emitted by binutils), or it may exhibit failures at runtime (I have seen the
latter when using `-fpic`; I suspect either binutils is producing incorrect
relocation information, or the EFI system is mishandling a certain type of
relocation which elf2efi doesn't generate).

Note, the "fake .reloc" section trick necessary with the objdump method is
not necessary with the direct linking method, and in my experiments it in
fact caused a problem resulting in a binary which the EFI system refused to
load.

(By the way, I gather "pei-x86-64" is the PE *Image* or executable format, as
opposed to "pe-x86-64" which is the PE *object* format which is intended as an
input format to linking. There is a distinct lack of relevant documenation in
the binutils manual).

In summary, to produce an executable EFI binary:
 * If you have binutils with pei-x86-64 support (or equivalent for your
   processor architecture), you can use one of two methods:
   * The objcopy trick used by GNU EFI / POSIX-UEFI, which requires
     compiling with `-fpie`, or with `-fpic` and a relocation hack
   * link directly to PE+ as described above, which seems to work reliably
     at least for x86-64, *if* `-fpie` is used during compilation
 * If you don't have suitable binutils support, or want or need to link
   non-position-independent code (not compiled with `-fpie` or `-fpic`):
   * link to executable ELF and then convert to PE+ using elf2efi.

While using pure binutils *is* possible if it is correctly configured when
built, it's certainly easier and more flexible to go the latter route and
use elf2efi.

## Constructing an EFI application in ELF format

To create a working EFI application (mostly assuming GCC compiler):

 * Do not link against standard system libraries (i.e. compile with
   `-ffreestanding`)
 * Turn off use of facilities requiring runtime support (eg use
   `-fno-stack-protector`)
 * Use the ms_abi, i.e. `-mabi=ms_abi`, or mark EFI API calls and the
   application entry point as ms_abi using `__attribute__((ms_abi))`.
   GCC documentation implies that `-maccumulate-outgoing-args` will also be
   required.
 * EFI applications must be relocatable. Either compile with `-fpie`, or
   link with `-q` to preserve relocations in the executable (these will then
   be converted to PE+ relocations in the `.reloc` section by elf2efi).
 * Don't use AVX or similar extensions (beyond SSE). These may be supported
   by the processor but not enabled by the EFI environment. Eg using
   `-march=x86-64` seemed to work for me, and/or there's the `-mno-avx`-style
   options. Failure to do this may result in a binary that works in QEMU but
   fails on real hardware (or when run in QEMU with KVM).
 * Certain sections may not be convertible (eg `.note.gnu.property` may have
   to be discarded). Others can be converted but are useless so may as well
   be discarded. In practice you probably only need `.text`, `.data`,
   `.rodata` and `.bss`. Conversion will generate `.reloc` in the PE+ output
   if there are relocations and may generate `.debug`.

(I plan to add a small working example application at some point.)

## Links

 * UEFI specifications - https://uefi.org/specifications
 * UEFI headers (extracted from EDK2) - https://github.com/kiznit/uefi-headers
 * GNU EFI - https://sourceforge.net/projects/gnu-efi/
 * "Goodbye GNU-EFI!" (use clang/lld to produce EFI apps) - https://dvdhrm.github.io/2019/01/31/goodbye-gnuefi/
 * POSIX-UEFI - https://gitlab.com/bztsrc/posix-uefi
 * OS-Dev wiki UEFI page - https://wiki.osdev.org/UEFI
 * pev, "the PE file analysis toolkit" - https://pev.sourceforge.io/
