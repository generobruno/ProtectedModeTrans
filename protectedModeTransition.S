/*
BEGIN
    CLEAR
    PROTECTED_MODE
    VGA_PRINT_STRING $message
    jmp .
message:
    .asciz "hello world"
*/

/* Las siguientes son macros que se repiten */

/* Push registers ax, bx, cx and dx. Lightweight `pusha`. */
.macro PUSH_ADX
    push %ax
    push %bx
    push %cx
    push %dx
.endm

/* Pop registers dx, cx, bx, ax. Inverse order from PUSH_ADX,
 * so this cancels that one.
 */
.macro POP_DAX
    pop %dx
    pop %cx
    pop %bx
    pop %ax
.endm

.macro PUSH_EADX
    push %eax
    push %ebx
    push %ecx
    push %edx
.endm

.macro POP_EDAX
    pop %edx
    pop %ecx
    pop %ebx
    pop %eax
.endm

.macro CURSOR_POSITION x=$0, y=$0
    PUSH_ADX
    mov $0x02, %ah
    mov $0x00, %bh
    mov \x, %dh
    mov \y, %dl
    int $0x10
    POP_DAX
.endm


.macro BEGIN
    /* BEGIN */
    LOCAL after_locals
    /* Al empezar en modo real, el código es en 16 bits */
    .code16
    cli
    /* Seteamos el CS a 0. */
    ljmp $0, $1f
    1:
    xor %ax, %ax
    /* Seteamos el DS a 0. */
    mov %ax, %ds
    /* Limpiamos el resto de segmentos */
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %bp
    /* Deshabilitamos las interrupciones */
    mov %ax, %ss
    /* We should set SP because BIOS calls may depend on that. TODO confirm. */
    mov %bp, %sp
    /* Store the initial dl to load stage 2 later on. */
    mov %dl, initial_dl
    jmp after_locals
    initial_dl: .byte 0
after_locals:
.endm

.macro CLEAR
    /* Push registers ax, bx, cx and dx. Lightweight `pusha`. */
    push %ax
    push %bx
    push %cx
    push %dx
    mov $0x0600, %ax
    mov $0x7, %bh
    mov $0x0, %cx
    mov $0x184f, %dx
    int $0x10
    CURSOR_POSITION /* Call CURSOR_POSITION??? */
    /* Pop registers dx, cx, bx, ax. Inverse order from PUSH_ADX */
    pop %dx
    pop %cx
    pop %bx
    pop %ax
.endm

/* Enter protected mode. Use the simplest GDT possible. */
.macro PROTECTED_MODE
    /* Must come before they are used. */
    .equ CODE_SEG, 8
    .equ DATA_SEG, gdt_data - gdt_start

    /* Tell the processor where our Global Descriptor Table is in memory. */
    lgdt gdt_descriptor

    /* Set PE (Protection Enable) bit in CR0 (Control Register 0),
     * effectively entering protected mode.
     */
    mov %cr0, %eax
    orl $0x1, %eax
    mov %eax, %cr0

    ljmp $CODE_SEG, $protected_mode
/* Our GDT contains:
 *
 * * a null entry to fill the unusable entry 0:
 * http://stackoverflow.com/questions/33198282/why-have-the-first-segment-descriptor-of-the-global-descriptor-table-contain-onl
 * * a code and data. Both are necessary, because:
 * +
 * --
 * ** it is impossible to write to the code segment
 * ** it is impossible execute the data segment
 * --
 * +
 * Both start at 0 and span the entire memory,
 * allowing us to access anything without problems.
 *
 * A real OS might have 2 extra segments: user data and code.
 *
 * This is the case for the Linux kernel.
 *
 * This is better than modifying the privilege bit of the GDT
 * as we'd have to reload it several times, losing cache.
 */
gdt_start:
gdt_null:
    .long 0x0
    .long 0x0
gdt_code:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10011010
    .byte 0b11001111
    .byte 0x0
gdt_data:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010010
    .byte 0b11001111
    .byte 0x0
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt_start
    .long gdt_start
vga_current_line:
    .long 0
.code32
protected_mode:
    /* Setup the other segments.
     * Those movs are mandatory because they update the descriptor cache:
     * http://wiki.osdev.org/Descriptor_Cache
     */
    mov $DATA_SEG, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    /* TODO detect the last memory address available properly.
     * It depends on how much RAM we have.
     */
    mov $0X7000, %ebp
    mov %ebp, %esp
.endm

/* Print a NULL terminated string to position 0 in VGA.
 *
 * s: 32-bit register or memory containing the address of the string to print.
 *
 * Clobbers: none.
 *
 * Uses and updates vga_current_line to decide the current line.
 * Loops around the to the top.
 */
.macro VGA_PRINT_STRING s
    LOCAL loop, end
    PUSH_EADX
    mov \s, %ecx
    mov vga_current_line, %eax
    mov $0, %edx
    /* Number of horizontal lines. */
    mov $25, %ebx
    div %ebx
    mov %edx, %eax
    /* 160 == 80 * 2 == line width * bytes per character on screen */
    mov $160, %edx
    mul %edx
    /* 0xb8000 == magic video memory address which shows on the screen. */
    lea 0xb8000(%eax), %edx
    /* White on black. */
    mov $0x0f, %ah
loop:
    mov (%ecx), %al
    cmp $0, %al
    je end
    mov %ax, (%edx)
    add $1, %ecx
    add $2, %edx
    jmp loop
end:
    incl vga_current_line
    POP_EDAX
.endm

jmp .

message:
    .asciz "Hello world"

