#define STACK_FRAME_OFFSET 6
.code16
.text
.global begin
begin:
  xchg %bx, %bx #bochs magic break point
  cli

  xor     %eax, %eax
  mov     %cs,%ax
  mov     %ax,%ds

## reset 0x30 interrupt
  movw    $0x0, %bx
  movw    %bx, %es
  movw $switch_proc, %es:0xc0 # isr offset
  movw %ax, %es:0xc2 #isr seg


  movw    $0xb800, %ax
  movw    %ax, %gs

## set stack frame eip
  movw $proc_a, stack_frame_a+2
  movw $proc_b, stack_frame_b+2

## set stack frame cs
  movw %cs, %ax
  movw %ax, stack_frame_a+4
  movw %ax, stack_frame_b+4

## set stack frame flag
  # get flag
  pushf
  movw (%esp), %ax
  popf
  movw %ax, stack_frame_a+6
  movw %ax, stack_frame_b+6

  movw $stack_frame_a, a_sp
  movw $stack_frame_b, b_sp

  movw $stack_frame_a, %sp

  popw %ax
  iret

.global proc_a
proc_a:
1:
  mov $0x1, %ax
  push %cx
  int $0x30
  jmp 1b

.global proc_b
proc_b:
1:
  mov $0x2, %al
  push %bx
  int $0x30
  jmp 1b

.global switch_proc
switch_proc:
  pushw %ax
  movw cur_proc, %dx

# 0 run proc_a
# 1 run proc_b
  cmp $0, %dx
  jne 1f
  # save cur_esp to a_sp
  movw %esp, a_sp
  movw b_sp, %ax
  movw $1, cur_proc
  jmp 2f
1:
  # save cur_esp to b_sp
  movw %esp, b_sp
  movw a_sp, %ax
  movw $0, cur_proc
2:

  movw %ax, %sp
  popw %ax
  iret


cur_proc:
  .word 0x0
a_sp:
  .word 0x0
b_sp:
  .word 0x0

  .space  256, 0
proc_stack_top_a:
  .space  256, 0
proc_stack_top_b:



  .space  256, 0
stack_frame_a:
  .word 0x9# ax
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag


  .space  256, 0
stack_frame_b:
  .word 0x9# ax
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag
