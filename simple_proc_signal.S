#define STACK_FRAME_OFFSET 8
.code16
.text
.global begin
begin:
  xchg %bx, %bx #bochs magic break point
  cli

  xor     %eax, %eax
  mov     %cs,%ax
  mov     %ax,%ds
  mov     $0, %cx
  movw $0, is_sig_return

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

org_eip:
  .word 0x0

is_sig_return:
  .word 0x0

  .space  256, 0
proc_stack_top_a:
  .space  256, 0
proc_stack_top_b:

stack_frame:
  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag
  .word 0x3# ret_signal

  .word 0x0# eip
  .word 0x1# cs
  .word 0x2# flag
  .word 0x3# ret_signal

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
  #movl is_sig_return, %eax
  #movw (%eax), %bx 
  movw is_sig_return, %bx
  cmp $1, %bx
  jne skip_restore_eip

  movw org_eip, %bx # get original eip
#  movw (%eax), %bx 

  movl $0, %eax
  movw cur_proc, %ax
  movw %bx, (%eax)

  movw $0, is_sig_return
skip_restore_eip:

  add $1, %cx

  movw cur_proc, %dx
  cmp $stack_frame, %dx
  je 1f
  movw $stack_frame, cur_proc
  jmp 2f
1:
  movw $stack_frame+STACK_FRAME_OFFSET, cur_proc
2:

  cmp $7, %cx
  jne skip_setup_signal
  xchg %bx, %bx #bochs magic break point
#  movw cur_proc, %dx  # save original eip 
#  movw %dx, org_eip  

  movl $0, %eax
  movl cur_proc, %eax

  movw (%eax), %bx 
  mov %bx, org_eip # save original eip to org_eip

  movw $sig_handle, (%eax) # set eip to sig_handle
  movw $sig_return, 6(%eax) # set eip to sig_return

skip_setup_signal:

  movw cur_proc, %sp
  iret

.global sig_handle
sig_handle:
  mov     $0, %cx
  ret

.global sig_return
sig_return:
  movw $1, is_sig_return
  int $0x30

