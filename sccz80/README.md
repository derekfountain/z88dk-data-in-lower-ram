# z88dk-data-in-lower-ram, sccz80 version

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

_* Note that I'm not very familiar with the sccz80 compiler. It wasn't hard
to work it out, but details may be wrong. Anything in here which looks a bit
off is probably my mistake. *_

sccz80 uses _sections_ to store blocks of code and data. It will then link
each section into the final output based on origin instructions, command
line arguments, etc.

sccz80 will automatically create a section called CONTENDED if the origin
of the code is below 32768. In theory you can force the compiler to build
low_data.c such that the constants appear in that section. In practise,
although I could see that changing the origin does cause that section to
appear, I couldn't get any control over where data or code actually went.
So I gave up on that and went for the split build approach.

z88dk defines a whole bunch of sections to store the code it generates.
The method used here is to create a new section which goes into lower,
contended memory, an area the normal section definitions ignore by
default.

The new section used here is called "CONTENDED", same as the automatically
created one. I'm not sure if that was a good idea.

## Run the build script

Start by running the build script:

```
> ./build.sh
```

Linux only, it should be trivial to convert it to Windows, but I don't
know how to do that.

This step gives the pieces for the following discussion.

## Building the pieces

### sections.asm

```
zcc +zx -vn -c sections.asm -o sections.o --list
```

The new section "CONTENDED" is defined in an assembly language file called
sections.asm. As far as I'm aware, sccz80 can't create a new section from
C code, so you need the assembly language file. You can see from the
_sections.asm.lis_ file it just does this:

```
    41                          SECTION CONTENDED
    42                          org 25000
```

That's all the assembly language needs to do to guide the linker.

### low_data.c

```
zcc +zx --constsegCONTENDED -c low_data.c -o low_data.o -compiler=sccz80 -clib=default -lndos -s -m --list --c-code-in-asm
```

This C file contains the constant data which needs to go into lower
memory. In the example it's just a hello world string:

```
const uint8_t helloworld[] = "Hello, world!";
```

The --constsegCONTENDED option on the build line causes the compiler to
generate assembly language code which puts the string in the CONTENDED section:

```
    18                          ;const uint8_t helloworld[] = "Hello, world!";
    18                          	C_LINE	20,"low_data.c"
    20                          	C_LINE	20,"low_data.c"
    20                          	SECTION	CONTENDED
    20                          ._helloworld
    20  0000  48656c6c6f2c2077  	defm	"Hello, world!"
              6f726c6421        
    20  000d  00                	defb	0
    20                          
```

### dlm.c

```
zcc +zx -c dlm.c -o dlm.o -compiler=sccz80 -clib=default -lndos -s -m --list --c-code-in-asm
```

This is the main code which references the string:

```
extern uint8_t helloworld[];
...
  printf("%s\n", helloworld);
```

## Link the pieces into separate binaries

The above commands are "compile-only". They compile the source into an
object, then stop. Next step is to use the linker to fix up each object's
absolute addresses.

```
zcc +zx -vn sections.o dlm.o low_data.o -o dlmlinked -compiler=sccz80 -clib=default -lndos -m -s
```

This line calls the linker to create a linked object for each piece. The output
of this step is a file called _dlmlinked_, a _dlmlinked_CONTENDED.bin_, and a memory
map file called _dmlinked.map_ which explains where everything is supposed to go.

## Glue the binary pieces together

```
z88dk-appmake +glue -b dlmlinked --filler 0xDF --clean
```

This (silently) uses the memory map created by the previous step to arrange
the sections and fill in the gaps between them. The output of this is a single
binary file with everything in it, all in the right place. You can insert this
binary directly into an emulated Spectrum's memory using, for example with
Fuse, _File->Load binary data_. For this example you should put it at 25000 at
if all is well it'll work when you _RANDOMISE USR 32768_.

## Create an application (TAP file)

```
z88dk-appmake +zx --org 25000 -b dlmlinked__.bin --blockname dlm -o dlm.tap --usraddr=32768
```

The application maker creates the BASIC loader which will load the code
(in dlmlinked__.bin) at the required origin (25000) and override the default execution
start point (which would be 25000) with the --usraddr address.
