# z88dk-data-in-lower-ram, SDCC version

The object of this exercise is to create a program for the ZX Spectrum
which starts off with the code at 0x8000 (32768, the start of the
"non-contended" faster memory) and some initial data below it in the
memory map. That initial data would therefore be in the slower,
"contended" memory, which is where programmers typically like to store
constant data until it's required by their game code.

This is a FAQ on the z88dk ZX Spectrum forum, but there aren't any
simple examples of how to do set up this rather tricky initial memory
map.

## How it works

SDCC uses sections to store blocks of code and data. It will then link
each section into the final output based on origin instructions, command
line arguments, etc.

z88dk defines a whole bunch of sections to store the code it generates.
The method used here is to create a new section which goes into lower,
contended memory, an area the normal section definitions ignore by
default.

The new section used here is called "CONTENDED".

## Run the build script

Start by running the build script:

> ./build.sh

Linux only, it should be trivial to convert it to Windows, but I don't
know how to do that.

This step gives the pieces for the following discussion.

## Building the pieces

### sections.asm

`
zcc +zx -vn -c -clib=sdcc_iy sections.asm -o sections.o --list
`

The new section "CONTENDED" is defined in an assembly language file called
sections.asm. As far as I'm aware, sdcc can't create a new section from
C code, so you need the assembly language file. You can see from the
lis file it just does this:

>    41                          SECTION CONTENDED
>    42                          org 25000

That's all the assembly language needs to do to guide the linker.

### low_data.c

`
zcc +zx -vn -c --constsegCONTENDED -clib=sdcc_iy low_data.c -o low_data.o --list --c-code-in-asm
`

This C file contains the constant data which needs to go into lower
memory. In the example it's just a hello world string:

`
const uint8_t helloworld[] = "Hello, world!";
`

The --constsegCONTENDED option on the build line causes the compiler to
generate assembly language code which puts the string in the CONTENDED section:

>   246                          	SECTION CONTENDED
>   247                          _helloworld:
>   248  0000  48656c6c6f2c2077  	DEFM "Hello, world!"
>              6f726c6421        
>   249  000d  00                	DEFB 0x00

### dlm.c

`
zcc +zx -vn -c -clib=sdcc_iy dlm.c -o dlm.o --list --c-code-in-asm
`

This is the main code which references the string:


>extern uint8_t helloworld[];
>...
>  printf("%s\n", helloworld);

## Link the pieces into separate binaries

`
zcc +zx -vn -startup=5 -clib=sdcc_iy dlm.o sections.o low_data.o -o dlmlinked -m -s
`

Caller the linker to create a linked object for each piece. The output of this step is one
*.bin file per section defined, and a memory map file called dmlinked.map which
explains where everything is supposed to go.

## Glue the binary pieces together

`
z88dk-appmake +glue -b dlmlinked --filler 0xDF --clean
`

This (silently) uses the memory map created by the previous step to arrange
the sections and fill in the gaps between them. The output of this is a single
binary file with everything in it, all in the right place. You can insert this
binary directly into an emulated Spectrum's memory using, for example with
Fuse, File->Load binary data. For this example you should put it at 25000.

## Create an application (TAP file)

`
z88dk-appmake +zx --org 25000 -b dlmlinked__.bin --blockname dlm -o dlm.tap --usraddr=32768
`

The application maker createa the BASIC loader which will load the code
(in dlmlinked__.bin) at the required origin (25000) and override the default execution
start point (which would be 25000) with the --usraddr address.
