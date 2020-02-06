# ref: https://www.itread01.com/content/1544669708.html text color
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


org_eip:
  .word 0x0

is_sig_return:
  .word 0x0

cur_proc:
  .word stack_frame + STACK_FRAME_OFFSET

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
  mov $0x0, %eax
  movw $0x0441, %gs:(%eax) # A
  int $0x30
  jmp 1b

.global proc_b
proc_b:
1:
  mov $0x2, %ebx
  movw $0x0942, %gs:(%ebx) # B
  int $0x30
  jmp 1b

.global switch_proc
switch_proc:
  movw is_sig_return, %bx
  cmp $1, %bx
  jne skip_restore_eip

  mov $0x0, %esi
  movw $0x0020, %gs:(%esi) # ' '
  mov $0x2, %esi
  movw $0x0020, %gs:(%esi) # ' '
  mov $0x4, %esi
  movw $0x0020, %gs:(%esi) # ' '

mov $0x64, %cx
loopstart:
   dec %cx          #Note:  decrementing cx and jumping on result is
   jnz loopstart 

  movw org_eip, %bx # get original eip

  movl $0, %eax
  movw cur_proc, %ax
  movw %bx, (%eax)

  movw $0, is_sig_return
skip_restore_eip:

  add $1, %cx

  movw cur_proc, %dx
  cmp $stack_frame, %dx # 假如目前 cur_proc 是 stack_frame, 就將 cur_proc 設定為 stack_frame+STACK_FRAME_OFFSET (另外一個 process)
  je 1f
  movw $stack_frame, cur_proc
  jmp 2f
1:
  movw $stack_frame+STACK_FRAME_OFFSET, cur_proc
2:

  cmp $3, %cx
  jne skip_setup_signal
  xchg %bx, %bx #bochs magic break point

  movl $0, %eax
  movl cur_proc, %eax

  movw (%eax), %bx 
  movw %bx, org_eip # save original eip to org_eip

  movw $sig_handle, (%eax) # set eip to sig_handle
  movw $sig_return, 6(%eax) # set eip to sig_return

skip_setup_signal:

  movw cur_proc, %sp
  iret

.global sig_handle
sig_handle:
  mov     $0, %cx
  mov $0x4, %esi
  movw $0x075a, %gs:(%esi) # Z
  ret

.global sig_return
sig_return:
  movw $1, is_sig_return
  sub $2, %sp
  int $0x30


