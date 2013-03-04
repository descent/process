# in protected mode, do process switch

#define STACK_FRAME_OFFSET 6
.code16
.data
.macro Descriptor Base, Limit, Attr
    .2byte  \Limit & 0xFFFF
    .2byte  \Base & 0xFFFF
    .byte   (\Base >> 16) & 0xFF
    .2byte  ((\Limit >> 8) & 0xF00) | (\Attr & 0xF0FF)
    .byte   (\Base >> 24) & 0xFF
.endm

.set    DA_32,  0x4000  /* 32-bit segment */
.set    DA_LIMIT_4K, 0x8000     /* 4K */
.set    DA_CR,   0x9A   /* Execute/Read */
.set    DA_DRW,  0x92   /* Read/Write */

gdt0: Descriptor  0, 0, 0
gdt1: Descriptor  0, 0xfffff, DA_CR | DA_32 | DA_LIMIT_4K
gdt2: Descriptor  0, 0xfffff, DA_DRW | DA_32 | DA_LIMIT_4K
.set gdt_len, (. - gdt0)
gdt_ptr: .2byte (gdt_len -1 ) # limit
         .4byte 0             # base

.set selector_code, (gdt1-gdt0)
.set selector_data, (gdt2-gdt0)
.text
.global begin
begin:
  xchg %bx, %bx #bochs magic break point
## set stack frame flag
  # get flag
  pushf
  movw (%esp), %ax
  popf
  movw %ax, stack_frame_a+6
  movw %ax, stack_frame_b+6
  cli

  xor     %eax, %eax
  mov     %cs,%ax
  mov     %ax,%ds
  movw    %ax, my_cs
  movw    %ax, my_ss

## reset 0x30 interrupt
  movw    $0x0, %bx
  movw    %bx, %es
  movw $switch_proc, %es:32 # isr offset
  movw %ax, %es:34 #isr seg

  movw    $0xb800, %ax
  movw    %ax, %gs

## set stack frame eip
  movw $proc_a, stack_frame_a+2
  movw $proc_b, stack_frame_b+2

## set stack frame cs
  movw %cs, %ax
  movw %ax, stack_frame_a+4
  movw %ax, stack_frame_b+4


  movw $stack_frame_a, cur_proc
  movw cur_proc, %sp
  popw %ax
  iret

  mov $0x4c00, %ax
  int $0x21           


.global proc_a
proc_a:
1:
  mov $0x1, %ax
  #int $0x1c
  jmp 1b

.global proc_b
proc_b:
1:
  mov $0x2, %al
  #int $0x1c
  jmp 1b

.global switch_proc
switch_proc:
  xchg %bx, %bx #bochs magic break point
#  movw %cs:my_ss, %ds
#  movw %cs:my_ss, %ss
#  movw cur_proc, %sp
  pushw %ax

  inb $0x21, %al
  orb $0x1 ,%al
  outb %al, $0x21

  movw cur_proc, %dx
  cmp $stack_frame_a, %dx
  je 1f
  movw $stack_frame_a, cur_proc
  jmp 2f
1:
  movw $stack_frame_b, cur_proc
2:
  cli
  inb $0x21, %al
  andb $0xfe ,%al
  outb %al, $0x21

  movw cur_proc, %sp
  popw %ax
  iret


cur_proc:
  .word 0x0
dos_cs:
  .word 0x0
dos_ss:
  .word 0x0
dos_sp:
  .word 0x0
my_cs:
  .word 0x0
my_ss:
  .word 0x0
my_sp:
  .word 0x0

  .space  256, 0
proc_stack_top_a:
  .space  256, 0
proc_stack_top_b:

stack_frame_a:
  .word 0x9# ax
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag

stack_frame_b:
  .word 0x9# ax
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag
