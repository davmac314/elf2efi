# elf2efi

This is the "elf2efi" utility, separated from the iPXE package
(https://github.com/ipxe/ipxe / https://ipxe.org/). It may originally
come from Syslinux (https://wiki.syslinux.org).

The utility is of such general use that I figured it'd be worth separating out.

It converts an ELF-format executable/DLL to a "PE+"-format file, suitable for
use as an EFI application (or driver). This makes it easier to build EFI
executables on systems which primarily use the ELF format, and without
resorting to the relocation hacks that eg GNU-EFI use. However, a suitably
configured GNU toolchain or LLVM toolchain can also produce appropriate
executables: see "Alternative #2" and "Alternative #3" below. Therefore this
tool is probably only useful in limited situations.

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

# Alternative methods to create EFI applications

There are options for making EFI executables other than by using `elf2efi`:

## Alternative #1: GNU binutils objcopy

POSIX-UEFI (see links) and possibly GNU EFI use the "objcopy" utility (from
GNU binutils) to convert ELF format files to PE+. However:

 * This requires binutils has been built with the appropriate support.
 * The EFI loads applications at any arbitrary address; it requires they be
   relocatable -
 * But, objcopy doesn't preserve relocations in executable images when copying
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

To get around these problems, POSIX-UEFI and GNU EFI do a hack: they include
a stub to perform ELF relocations. They also compile with `-fpic` to reduce
the number of relocations needed (though for x86-64 at least, `-fpie` is a
much better choice). Finally, they include a `.reloc` section in PE+
relocation format, so that objcopy won't mark the result as having had
relocations stripped.

(The "elf2efi" method in comparison doesn't need these hacks, and doesn't
necessitate compiling with either `-fpic` or `-fpie`).

## Alternative #2: GNU binutils link directly to PE+

If binutils supports the PE+ format, though, why not link directly to that
and skip the problematic objcopy step?

This is tricky to get right, but it is possible, at least with a recent
binutils; it still needs to be built with the appropriate support.

The link command looks something like this:

```
ld --strip-debug -m i386pep --oformat pei-x86-64 --subsystem 10 \
    --image-base 0 --enable-reloc-section $(OBJECTS)
```

This works pretty well. The `--enable-reloc-section` causes (PE-format)
relocations to be generated, meaning that we do not have to compile the code
with `-fpie` -- the relocations will be "native" PE-format and will be
performed by the EFI loader. Having said that, on x86_64 it is worth using
`-fpie` anyway; see notes on `-mcmodel=` options under "constructing an EFI
application".

If you want to include ELF library archives in the link (with the typical
`-llibname`), use `--format=elf64-x86-64` to specify the input format;
otherwise the objects in the archive won't be pulled in (I suspect that
the `i386pep` emulation makes the linker look for PE-format objects).

Note, the "fake .reloc" section trick necessary with the objcopy method is
not necessary with the direct linking method, and in my experiments it in
fact caused a problem resulting in a binary which the EFI system refused to
load.

(By the way, I gather "pei-x86-64" is the PE *Image* or executable format, as
opposed to "pe-x86-64" which is the PE *object* format - also known as COFF -
which is intended as an input format to linking. There is a distinct lack of
relevant documenation in the binutils manual).

## Alternative #3: Use Clang (LLVM) and target UEFI directly

LLVM's Clang can be used to produce PE format object files and executables.
You will need to link with `lld-link` (which emulates MSVC link command),
which is part of LLD (LLVM's own linker); note that object files will not be
ELF format.

Compile and link with `--target x86_64-unknown-windows`; link (via `clang`)
using `-fuse-ld=lld-link` and `-Wl,-subsystem:efi_application`. You may wish
to specify an entry point via `-Wl,-entry:efi_main` (where `efi_main` is the
entry point function). You won't be able to use linker scripts or linker
options which are specific to the ELF linker. To create static libraries
you'll need to use `llvm-lib` (and use a `.lib` extension) since the linker
will not recognise `ar` format archives.

See also the general notes on constructing an EFI application below.

## Summary of techniques

In summary, to produce an executable EFI binary:
 * If you have binutils with pei-x86-64 support (or equivalent for your
   processor architecture), you can use one of two methods:
   * The objcopy trick used by GNU EFI / POSIX-UEFI, which requires
     compiling with `-fpie` or `-fpic`, and a relocation hack
   * link directly to PE+ as described above, which seems to work reliably
     at least for x86-64, and is a cleaner solution than the objcopy method.
 * If you have LLVM including clang and LLD, built with appropriate support
   (which they are by default), then you can use them to generate UEFI
   executables directly. However, you will need to use the
   Windows-compatible linker frontend (`lld-link`) and use `llvm-lib` for
   static archive management.
 * If you don't have suitable LLVM/binutils support, or want or need to link
   non-position-independent code (not compiled with `-fpie` or `-fpic`):
   * link to executable ELF and then convert to PE+ using elf2efi.

## Constructing an EFI application (using any method)

To create a working EFI application (mostly assuming GCC compiler):

 * Do not link against standard system libraries (i.e. compile with
   `-ffreestanding`, link with `-nostdlib`).
 * Turn off use of facilities requiring runtime support (eg use
   `-fno-stack-protector`).
 * If using headers which assume a 16-bit wchar_t, use `-fshort-wchar`.
   (You'll need to get UEFI headers from somewhere; they are not supplied
   with this tool, except for a cut down version with the example
   application).

For x86-64:

 * Disable use of the "red zone" above the stack pointer by using
   `-mno-red-zone`.
 * Either use `-mcmodel=large`, or use `-fpie` (or `-fpic`). Failure to do
   this may result in an executable that works correctly only when loaded at
   certain addresses, and which exhibits strange behaviour otherwise. For
   x86-64, `-fpie` is really the best choice as it generates efficient code
   with few relocations. (Note that for 32-bit code this may not be
   necessary, and `-fpie` will generate less efficient code). You cannot use
   `-fpie` with Clang for x86_64-unknown-windows target.
 * Use the ms_abi (i.e. `-mabi=ms`) or at least mark EFI API calls and the
   application entry point as ms_abi using `__attribute__((ms_abi))`. GCC
   documentation implies that `-maccumulate-outgoing-args` will also be
   required "currently" but in practice it doesn't seem to be necessary.
 * Don't use SSE or similar extensions (beyond MMX). These may be supported
   by the processor but not enabled by the EFI environment. For example, using
   `-march=x86-64 -mno-sse` should work. Failure to do this may result in a
   binary that works in QEMU but fails on real hardware (or when run in QEMU
   with KVM).

If using elf2efi, also:

 * EFI applications must be relocatable. Either compile with `-fpie`, or
   link with `-q` to preserve relocations in the executable (these will then
   be converted to PE+ relocations in the `.reloc` section by elf2efi).
 * You may need to strip debug sections from the ELF file (use
   `--strip-debug`/`-s` when linking).
 * Certain sections may not be convertible (eg `.note.gnu.property` may have
   to be discarded, via use of a suitable linker script). Others can be
   converted but are useless so may as well be discarded. In practice you
   probably only need `.text`, `.data`, `.rodata` and `.bss`. Conversion will
   generate `.reloc` in the PE+ output if there are relocations and may
   generate `.debug`.

See `examples/` folder for examples.

## Links

 * UEFI specifications - https://uefi.org/specifications
 * UEFI headers (extracted from EDK2) - https://github.com/kiznit/uefi-headers
 * GNU EFI - https://sourceforge.net/projects/gnu-efi/
 * "Goodbye GNU-EFI!" (use clang/lld to produce EFI apps) - https://dvdhrm.github.io/2019/01/31/goodbye-gnuefi/
 * POSIX-UEFI - https://gitlab.com/bztsrc/posix-uefi
 * OS-Dev wiki UEFI page - https://wiki.osdev.org/UEFI
 * pev, "the PE file analysis toolkit" - https://pev.sourceforge.io/
