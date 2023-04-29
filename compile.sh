#!/bin/bash

echo "Compiling..."

# Compile program
gcc -m32 -c -ggdb3 -o 'protectedModeTransition.o' 'protectedModeTransition.S'
ld -melf_i386  -nostdlib -o 'protectedModeTransition.elf' -T 'linker.ld' 'protectedModeTransition.o'
objcopy -O binary 'protectedModeTransition.elf' 'protectedModeTransition.img'

echo "Finish compiling."