#!/bin/bash

set -x

# Assemble the sections definition code
#
zcc +zx -vn -c -clib=sdcc_iy sections.asm -o sections.o --list

# Compile the C code which contains the const data to go into low memory.
# The --constseg option ensures the data in the C code goes into the
# CONTENDED section, which is defined as starting at 25000
#
zcc +zx -vn -c --constsegCONTENDED -clib=sdcc_iy low_data.c -o low_data.o \
               --list --c-code-in-asm

# Compile the C code with the main() program
#
zcc +zx -vn -c -clib=sdcc_iy dlm.c -o dlm.o \
               --list --c-code-in-asm

# Link the pieces. The output of this step is one *.bin file per section defined,
# and a memory map file called dmlinked.map which explains where everything is
# supposed to go.
#
zcc +zx -vn -startup=5 -clib=sdcc_iy dlm.o sections.o low_data.o -o dlmlinked -m -s

# Now glue the *.bin files together. This (silently) uses the memory map created
# by the previous step to arrange the sections and fill in the gaps between them.
# The output of this is a single binary file which everything in it, all in the
# right place. You can insert this binary directly into an emulated Spectrum's
# memory using, for example with Fuse, File->Load binary data. For this example
# you should put it at 25000.
# 
z88dk-appmake +glue -b dlmlinked --filler 0xDF --clean

# Finally build an application, which for the Spectrum is a TAP file. The BASIC
# loader will load the code (in dlmlinked__.bin) at the required origin (25000)
# and override the default execution start point (which would be 25000) with
# the --usraddr address.
#
z88dk-appmake +zx --org 25000 -b dlmlinked__.bin --blockname dlm -o dlm.tap --usraddr=32768
