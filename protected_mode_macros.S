/* https://github.com/cirosantilli/x86-bare-metal-examples#protected-mode */

#include "mycommon.h"
BEGIN
    CLEAR
    PROTECTED_MODE
    VGA_PRINT_STRING $message
    jmp .
message:
    .asciz "hello world"

/* 
Compilar y correr:
as -g -o protected_mode.o protected_mode.S
ld --oformat binary -o protected_mode.img -T link.ld protected_mode.o
qemu-system-x86_64 -hda protected_mode.img
*/