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
  movw $proc_a, stack_frame
  movw $proc_b, stack_frame+STACK_FRAME_OFFSET

## set stack frame cs
  movw %cs, %ax
  movw %ax, stack_frame+2
  movw %ax, stack_frame+STACK_FRAME_OFFSET+2

## set stack frame flag
  # get flag
  pushf
  movw (%esp), %ax
  popf
  movw %ax, stack_frame+4
  movw %ax, stack_frame+STACK_FRAME_OFFSET+4

  int $0x30

  mov $0x4c00, %ax
  int $0x21           

cur_proc:
  .word 0x0
target_seg:
  .word 0x0
target_offset:
  .word 0x0

  .space  256, 0
proc_stack_top_a:
  .space  256, 0
proc_stack_top_b:

stack_frame:
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag

  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag

.global proc_a
proc_a:
1:
  mov $0x1, %ax
  int $0x30
  jmp 1b

.global proc_b
proc_b:
1:
  mov $0x2, %bl
  int $0x30
  jmp 1b

.global switch_proc
switch_proc:
  movw cur_proc, %dx
  cmp $stack_frame, %dx
  je 1f
  movw $stack_frame, cur_proc
  jmp 2f
1:
  movw $stack_frame+STACK_FRAME_OFFSET, cur_proc
2:
  movw cur_proc, %sp
  iret

