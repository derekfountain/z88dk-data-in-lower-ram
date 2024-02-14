/*
 * Main C code, just prints the hello world line from contended memory.
 */

#include <stdio.h>
#include <stdint.h>

extern uint8_t helloworld[];

void main(void)
{
  printf("%s\n", helloworld);
  return;
}


