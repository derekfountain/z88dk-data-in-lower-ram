/*
 * This C file contains the data which needs to be loaded into low memory.
 * Just a hello world string in this example.
 *
 * The key here is to compile this part of the program with the
 *
 *  --constsegCONTENDED
 *
 * option, which puts the constant data defined here into the CONTENDED
 * section (as defined in sections.asm). See the build script.
 *
 * Any non-time-critical code can be put in CONTENDED section as well,
 * via the option
 *
 * --codesegCONTENDED
 */

#include <stdint.h>

const uint8_t helloworld[] = "Hello, world!";
